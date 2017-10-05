require 'faraday_middleware/ext/uri_ext'
require 'faraday_middleware/aws_signers_v4_ext'

class FaradayMiddleware::AwsSignersV4 < Faraday::Middleware
  class Request
    def initialize(env)
      @env = env
    end

    def headers
      @env.request_headers
    end

    def body
      @env.body || ''
    end

    def endpoint
      url = @env.url.dup

      # Escape the query string or the request won't sign correctly
      if url and url.query
        re_escape_query!(url)
      end

      url
    end

    def http_method
      @env.method.to_s.upcase
    end

    private

    def re_escape_query!(url)
      params = URI.decode_www_form(url.query)

      if params.any? {|k, v| v =~ / / }
        url.query = URI.seahorse_encode_www_form(params)
      end
    end
  end # of class Request

  def initialize(app, options = nil)
    super(app)

    @credentials = options.fetch(:credentials)
    @service_name = options.fetch(:service_name)
    @region = options.fetch(:region)
  end

  def call(env)
    req = Request.new(env)
    Aws::Signers::V4.new(@credentials, @service_name, @region).sign(req)
    @app.call(env)
  end
end
