require 'rspec'
require 'watir'
require 'vcr'
require 'webdrivers'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end