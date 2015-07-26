require 'aws-sdk-core/signers/v4'

class Aws::Signers::V4
  alias signed_headers_orig signed_headers

  def signed_headers(request)
    signed_headers_orig(request).downcase
  end
end
