require 'aws-sdk-resources'
require 'faraday'

module FaradayMiddleware
  autoload :AwsSignersV4, 'faraday_middleware/request/aws_signers_v4'

  Faraday::Request.register_middleware :aws_signers_v4 => lambda { AwsSignersV4 }
end
