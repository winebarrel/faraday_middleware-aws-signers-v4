require 'aws-sdk-core/signers/v4'

module AwsSignersV4Ext
  def signed_headers(request)
    super.downcase
  end
end

class Aws::Signers::V4
  unless Aws::Signers::V4 < AwsSignersV4Ext
    prepend AwsSignersV4Ext
  end
end
