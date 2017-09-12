# FaradayMiddleware::AwsSignersV4

[Faraday](https://github.com/lostisland/faraday) middleware for AWS Signature Version 4.

[![Gem Version](https://badge.fury.io/rb/faraday_middleware-aws-signers-v4.svg)](http://badge.fury.io/rb/faraday_middleware-aws-signers-v4)
[![Build Status](https://travis-ci.org/winebarrel/faraday_middleware-aws-signers-v4.svg)](https://travis-ci.org/winebarrel/faraday_middleware-aws-signers-v4)
[![Coverage Status](https://coveralls.io/repos/winebarrel/faraday_middleware-aws-signers-v4/badge.svg?branch=master&service=github)](https://coveralls.io/github/winebarrel/faraday_middleware-aws-signers-v4?branch=master)

**Currently developing new gem to support aws-sdk-v3.**

**see https://github.com/winebarrel/faraday_middleware-aws-sigv4**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday_middleware-aws-signers-v4'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_middleware-aws-signers-v4

## Usage

```ruby
require 'faraday_middleware'
require 'faraday_middleware/aws_signers_v4'
require 'pp'

conn = Faraday.new(url: 'https://apigateway.us-east-1.amazonaws.com') do |faraday|
  faraday.request :aws_signers_v4,
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
    # If you use the credentials file:
    #credentials: Aws::SharedCredentials.new.credentials,
    service_name: 'apigateway',
    region: 'us-east-1'

  faraday.response :json, :content_type => /\bjson\b/
  faraday.response :raise_error

  faraday.adapter Faraday.default_adapter
end

res = conn.get '/account'
pp res.body
# => {"accountUpdate"=>
#      {"name"=>nil,
#       "template"=>false,
#       "templateSkipList"=>nil,
#       "title"=>nil,
#       "updateAccountInput"=>nil},
#     "cloudwatchRoleArn"=>nil,
#     "self"=>
#      {"__type"=>
#        "GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/",
#       "name"=>nil,
#       "template"=>false,
#       "templateSkipList"=>nil,
#       "title"=>nil},
#     "throttleSettings"=>{"burstLimit"=>1000, "rateLimit"=>500.0}}
```
