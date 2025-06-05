require_relative './spec_helper'
require_relative '../services/scrape'

RSpec.describe BankScraper do
  let(:browser) { instance_double(Watir::Browser) }
  let(:button) { instance_double(Watir::Button) }
  let(:scraper) { described_class.new }

  before do
    allow(Watir::Browser).to receive(:new).and_return(browser)
    allow(browser).to receive(:goto)
    allow(browser).to receive(:close)
    allow(browser).to receive(:button).and_return(button)
    allow(button).to receive(:present?).and_return(true)
    allow(button).to receive(:wait_until).and_return(button)
    allow(button).to receive(:click)
    allow(browser).to receive(:div).and_return(double('Div', present?: true))
    allow(browser).to receive(:li).and_return(double('Li', present?: true, click: nil))
    allow(browser).to receive(:html).and_return('<html></html>')
  end

  describe '#scrape' do
    it 'returns array of accounts' do
      result = scraper.scrape
      expect(result).to be_an(Array)

      expect(browser).to have_received(:goto).with(BankScraper::BANK_URL)
      expect(button).to have_received(:click)
    end
  end

  describe '#parse_amount' do
    it 'parses positive amounts' do
      expect(scraper.send(:parse_amount, '$100.50')).to eq(100.5)
    end

    it 'parses negative amounts' do
      expect(scraper.send(:parse_amount, '-$50.25')).to eq(-50.25)
    end
  end

  describe '#parse_date' do
    it 'parses valid dates' do
      expect(scraper.send(:parse_date, 'April 12, 2023')).to eq('2023-04-12')
    end

    it 'returns original string for invalid dates' do
      expect(scraper.send(:parse_date, 'Invalid Date')).to eq('Invalid Date')
    end
  end
end