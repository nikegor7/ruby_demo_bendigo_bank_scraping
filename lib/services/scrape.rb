require 'watir'
require 'nokogiri'
require 'date'
require_relative '../models/account'
require_relative '../models/transaction'

class BankScraper
  BANK_URL = 'https://demo.bendigobank.com.au/banking/sign_in'.freeze
  DEFAULT_CURRENCY = '$'.freeze

  def initialize(headless: false)
    @browser = Watir::Browser.new :chrome,
      headless: headless,
      options: {
        args: %w[
          --disable-dev-shm-usage
          --no-sandbox
          --disable-gpu
          --disable-infobars
          --window-size=1920,1080
        ]
      }
    @current_account = nil
  end

  def scrape
    navigate_to_bank
    accounts = scrape_accounts
    scrap_transactions(accounts)
    save_to_json(accounts)
    
    puts "\n✅ Total Transactions #{accounts.sum { |a| a.transactions.size }} транзакций"
    accounts
  rescue => e
    puts "⚠️ Critical error : #{e.message}"
    []
  ensure
    @browser.close if @browser
  end

  def scrap_transactions(accounts)
    accounts.each_with_index do |account, index|
      @current_account = account
      puts "\n#{index + 1}/#{accounts.size} Processing: #{account.name}"
      
      account.transactions = scrape_transactions_for_account(account)
      puts "   Transactions found: #{account.transactions.size}"

    end
  end

  private

  def navigate_to_bank
    @browser.goto BANK_URL
    demo_button = @browser.button(text: /Launch (Personal|Business) Demo/i)
    demo_button.wait_until(timeout: 15, &:present?).click
    sleep 1 # Стабилизационная пауза
  end

  def scrape_accounts
    account_items = fetch_account_items
    process_account_items(account_items)
  rescue => e
    puts "⚠️ Account error: #{e.message}"
    []
  end

  def fetch_account_items
    list = @browser.ol(class: 'grouped-list__group__items')
    list.wait_until(timeout: 20, &:present?)
    doc = Nokogiri::HTML(list.html)
    doc.css('li[data-semantic-account-id]')
  end

  def process_account_items(account_items)
    account_items.map do |li|
      create_account_from_li(li)
    end.compact
  end

  def create_account_from_li(li)
    id = li['data-semantic-account-id']
    name_node = li.at_css('[data-semantic="account-name"]')
    balance_node = li.at_css('span[data-semantic="available-balance"]')

    return unless name_node && balance_node

    name = name_node.text.strip
    balance_text = balance_node.text.strip
    currency = balance_text.empty? ? DEFAULT_CURRENCY : balance_text[0]
    balance = balance_text.gsub(/[^\d.-]/, '').to_f

    Account.new(
      id: id,
      name: name,
      currency: currency,
      balance: balance,
      nature: name.split[1] || 'Account'
    )
  end

  def scrape_transactions_for_account(account)
    puts "🔍 Search Transactions for: #{account.id}"

    # Клик по аккаунту через data-атрибут
    account_element = @browser.li(css: "li[data-semantic-account-id='#{account.id}']")
    account_element.wait_until(timeout: 15, &:present?).click

    sleep 1.5 # Стабилизационная пауза

    # Переход на вкладку активности
    activity_tab = @browser.div(data_semantic: 'activity-tab')
    activity_tab.wait_until(timeout: 15, &:present?).click if activity_tab.present?

    transactions = parse_transactions
    transactions
  rescue => e
    puts "⚠️ Scrape transaction error for #{account.name}: #{e.message}"
    []
  ensure
    return_to_accounts_list
  end

  def parse_transactions
    transactions = []
    begin
      loop do
        @browser.div(data_semantic: 'activity-feed').wait_until(timeout: 15, &:present?)
        doc = Nokogiri::HTML(@browser.html)

        doc.css('li.grouped-list__group').each do |group|
          date = group.at_css('h3.grouped-list__group__heading')&.text&.strip
          next unless date

          group.css('ol > li[data-semantic="activity-item"]').each do |item|
            transaction = parse_transaction_item(item, date)
            transactions << transaction if transaction
          end
        end

        break unless next_page_available?
        scroll_and_click_next_page
        sleep 2
      end
    rescue => e
      puts "⚠️ Transaction parsing error: #{e.message}"
    end

    transactions
  end

  def parse_transaction_item(item, date)
    title = item.at_css('[data-semantic="transaction-title"]')&.text&.strip
    amount_element = item.at_css('[data-semantic="amount"]')
    balance = item.css('[data-semantic="running-balance"] span').last&.text&.strip

    return nil unless title && amount_element

    amount_parent = amount_element.parent
    is_debit = if (amount_parent && amount_parent['class'].to_s.include?('debit')) ||
      item.at_css('i.ico-money-debit, svg[aria-label="debit"]')
      true
    else
      false
    end

    amount_text = amount_element.text.strip

    Transaction.new(
      date: parse_date(date),
      description: "#{title}",
      amount: parse_amount(amount_text, is_debit),
      currency: parse_currency(amount_text),
      account_name: @current_account.name
    )
  end

  def next_page_available?
    next_button = @browser.button(data_semantic: 'next-page')
    next_button.present? && !next_button.disabled?
  end

  def scroll_and_click_next_page
    next_button = @browser.button(data_semantic: 'next-page')
    next_button.scroll.to
    sleep 0.5
    next_button.click
  end

  def return_to_accounts_list
    return if @browser.url.include?('sign_in')

    @browser.back
    @browser.ol(class: 'grouped-list__group__items').wait_until(timeout: 15, &:present?)
  rescue
    @browser.goto BANK_URL
  end

  def parse_date(date_string)
    Date.parse(date_string).to_s rescue date_string
  end

  def parse_amount(amount_text, is_debit = nil)
    numeric_value = amount_text.gsub(/[^\d.-]/, '').to_f
    
    if is_debit.nil?
      amount_text.include?('-') ? -numeric_value.abs : numeric_value.abs
    else
      is_debit ? -numeric_value.abs : numeric_value.abs
    end
  end

  def parse_currency(amount_text)
    amount_text[/[^\d.-]+/] || DEFAULT_CURRENCY
  end

  def save_to_json(accounts)
    json_data = accounts.map do |account|
      {
        id: account.id,
        name: account.name,
        currency: account.currency,
        balance: account.balance,
        nature: account.nature,
        transactions: account.transactions.map(&:to_hash)
      }
    end

    File.write('accounts.json', JSON.pretty_generate(json_data))
  end
end