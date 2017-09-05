require 'aws-sigv4/signer'

module AwsSignersV4Ext
  def signed_headers(request)
    super.downcase
  end
end

class Aws::Sigv4::Signer
  unless Aws::Sigv4::Signer < AwsSignersV4Ext
    prepend AwsSignersV4Ext
  end
end
