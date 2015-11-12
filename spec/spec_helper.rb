$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'faraday_middleware'
require 'faraday_middleware/aws_signers_v4'
require 'faraday_middleware/ext/uri_ext'
require 'timecop'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    Timecop.freeze(Time.utc(2015))
  end

  config.after(:each) do
    Timecop.return
  end
end

def faraday(options = {})
  options = {
    url: 'https://apigateway.us-east-1.amazonaws.com'
  }.merge(options)

  stubs = Faraday::Adapter::Test::Stubs.new

  Faraday.new(options) do |faraday|
    faraday.request :aws_signers_v4,
      credentials: Aws::Credentials.new('akid', 'secret'),
      service_name: 'apigateway',
      region: 'us-east-1'

    faraday.response :json, :content_type => /\bjson$/

    faraday.adapter :test, stubs do |stub|
      yield(stub)
    end
  end
end
