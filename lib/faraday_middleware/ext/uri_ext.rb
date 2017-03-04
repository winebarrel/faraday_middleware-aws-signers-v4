require 'uri'
require 'aws-sdk-resources'

module URI
  def self.seahorse_encode_www_form(params)
    params.map {|key, value|
      encoded_key = encode_www_form_component(key)

      if value.nil?
        encoded_key
      elsif value.respond_to?(:to_ary)
        value.to_ary.map {|v|
          if v.nil?
            # bug?
            #encoded_key
          else
            encoded_key + '=' + Seahorse::Util.uri_escape(v)
          end
        }.join('&')
      else
        encoded_key + '=' + Seahorse::Util.uri_escape(value)
      end
    }.join('&')
  end
end
