require_relative '../lib/services/scrape'

begin
  scraper = BankScraper.new
  accounts = scraper.scrape
  puts "✅ Successfully scraped #{accounts.size} accounts"
  puts "The scrape is done"

rescue => e
  puts "⚠️ Error: #{e.message}"
  puts e.backtrace.join("\n")
end