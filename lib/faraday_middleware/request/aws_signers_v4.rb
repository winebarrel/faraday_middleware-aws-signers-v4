require 'faraday_middleware/ext/uri_ext'
require 'aws-sigv4/signer'

class FaradayMiddleware::AwsSignersV4 < Faraday::Middleware
  class Request
    attr_reader :env

    def initialize(env)
      @env = env
    end

    def generate
      {
        http_method: http_method,
        url: url,
        headers: headers,
        body: body
      }
    end

    def headers
      env.request_headers
    end

    def body
      env.body || ''
    end

    def url
      _url = env.url.dup

      # Escape the query string or the request won't sign correctly
      if _url and _url.query
        re_escape_query!(_url)
      end

      _url
    end

    def http_method
      env.method.to_s.upcase
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
    signature(env).headers.each do |key, val|
      # Convert header string like 'x-amz-security-token'
      # to 'X-Amz-Security-Token'
      _key = key.gsub(/\A\w|(?<=-)\w/) { |s| s.upcase }
      env.request_headers[_key] = val
    end
    @app.call(env)
  end

  def signature(env)
    Aws::Sigv4::Signer.new(
      service: @service_name,
      region: @region,
      credentials_provider: @credentials
    ).sign_request(Request.new(env).generate)
  end
end
