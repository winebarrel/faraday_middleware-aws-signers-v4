describe FaradayMiddleware::AwsSignersV4 do
  let(:response) do
    {"accountUpdate"=>
      {"name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil,
       "updateAccountInput"=>nil},
     "cloudwatchRoleArn"=>nil,
     "self"=>
      {"__type"=>
        "GetAccountRequest:http://internal.amazon.com/coral/com.amazonaws.backplane.controlplane/",
       "name"=>nil,
       "template"=>false,
       "templateSkipList"=>nil,
       "title"=>nil},
     "throttleSettings"=>{"burstLimit"=>1000, "rateLimit"=>500.0}}
  end

  let(:signed_headers) do
    'host;x-amz-content-sha256;x-amz-date'
  end

  let(:default_expected_headers) do
    {"User-Agent"=>"Faraday v0.9.1",
     "X-Amz-Date"=>"20150101T000000Z",
     "Host"=>"apigateway.us-east-1.amazonaws.com",
     "X-Amz-Content-Sha256"=>
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "Authorization"=>
      "AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, " +
      "SignedHeaders=#{signed_headers}, " +
      "Signature=#{signature}"}
  end

  let(:additional_expected_headers) { {} }

  let(:expected_headers) do
    default_expected_headers.merge(additional_expected_headers)
  end

  let(:client) do
    faraday do |stub|
      stub.get('/account') do |env|
        expect(env.request_headers).to eq expected_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end
  end

  before do
    stub_const('Faraday::VERSION', '0.9.1')
  end

  context 'without query' do
    let(:signature) do
      'c09b39e34c45c4915dfebdff57b4096ab30363558b6bcb94e0489ef0bfd1bd89'
    end

    subject { client.get('/account').body }

    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        '3ddc09ae39f44638aec66f71ebbe21377621900718e2d2893e11ad3c07030b4a'
      end

      let(:params) { {foo: 'b a r', zoo: 'b a z'} }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        '10c4e1f9236d58a28fcec480ca635123d6fd168616d0a7e1529bbc62fb7c515c'
      end

      let(:params) { {foo: 'bar', zoo: 'baz'} }

      it { is_expected.to eq response }
    end
  end

  context 'use net/http' do
    subject { client.get('/account').body }

    let(:signature) do
      'c09b39e34c45c4915dfebdff57b4096ab30363558b6bcb94e0489ef0bfd1bd89'
    end

    let(:signed_headers) do
      'host;x-amz-content-sha256;x-amz-date'
    end

    let(:additional_expected_headers) do
      {"Accept"=>"*/*"}
    end

    before do
      expect_any_instance_of(FaradayMiddleware::AwsSignersV4).to receive(:net_http?) { true }
    end

    it { is_expected.to eq response }
  end

  context 'with InstanceProfileCredentials' do
    let(:security_credentials_url) { 'http://169.254.169.254/latest/meta-data/iam/security-credentials/' }

    let(:security_credentials_response) do
      {
        body: {
          "Code"            => "Success",
          "LastUpdated"     => "2015-11-12T00:05:53Z",
          "Type"            => "AWS-HMAC",
          "AccessKeyId"     => "test-access-key-id",
          "SecretAccessKey" => "test-secret-access-key",
          "Token"           => "test-token",
          "Expiration"      => expiration.strftime('%Y-%m-%dT%H:%M:%SZ'),
        }.to_json,
        status: 200,
      }
    end

    let(:security_credentials_response2) do
      {
        body: {
          "Code"            => "Success",
          "LastUpdated"     => "2015-11-12T00:05:53Z",
          "Type"            => "AWS-HMAC",
          "AccessKeyId"     => "test-access-key-id-2",
          "SecretAccessKey" => "test-secret-access-key-2",
          "Token"           => "test-token-2",
          "Expiration"      => expiration2.strftime('%Y-%m-%dT%H:%M:%SZ'),
        }.to_json,
        status: 200,
      }
    end

    let(:expected_headers) do
      {
        "User-Agent"           => "Faraday v0.9.1",
        "X-Amz-Date"           => Time.now.strftime("%Y%m%dT%H%M%SZ"),
        "Host"                 => "apigateway.us-east-1.amazonaws.com",
        "X-Amz-Content-Sha256" => "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "X-Amz-Security-Token" => "test-token",
        "Authorization"        => [
          "AWS4-HMAC-SHA256 Credential=test-access-key-id/20150101/us-east-1/apigateway/aws4_request",
          "SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token",
          "Signature=#{signature}",
        ].join(", "),
      }
    end

    let(:expected_headers2) do
      {
        "User-Agent"           => "Faraday v0.9.1",
        "X-Amz-Date"           => Time.now.strftime("%Y%m%dT%H%M%SZ"),
        "Host"                 => "apigateway.us-east-1.amazonaws.com",
        "X-Amz-Content-Sha256" => "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "X-Amz-Security-Token" => "test-token-2",
        "Authorization"        => [
          "AWS4-HMAC-SHA256 Credential=test-access-key-id-2/20150101/us-east-1/apigateway/aws4_request",
          "SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token",
          "Signature=#{signature2}",
        ].join(", "),
      }
    end

    let(:stubs) { Faraday::Adapter::Test::Stubs.new }

    let(:client) do
      Faraday.new(url: 'https://apigateway.us-east-1.amazonaws.com') do |faraday|
        faraday.request :aws_signers_v4,
          credentials: Aws::InstanceProfileCredentials.new,
          service_name: 'apigateway',
          region: 'us-east-1'
        faraday.response :json, :content_type => /\bjson$/

        faraday.adapter :test, stubs
      end
    end

    before do
      stub_request(:get, security_credentials_url).to_return(
        body: "test-iam\n",
        status: 200,
      )

      stubs.get('/account') do |env|
        expect(env.request_headers).to eq expected_headers
        [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
      end
    end

    context 'when expiration is later than or equeal to 5 minutes' do
      let(:expiration) { Time.now + 300 }

      let(:signature) do
        '2865f4c918c812c0319cd4e4a734a3eb5dceffbd19c105b6fda1cf3b084d88c7'
      end

      before do
        stub_request(:get, "#{security_credentials_url}test-iam").to_return(
          security_credentials_response
        )
      end

      subject { client.get('/account').body }

      it { is_expected.to eq response }
    end

    context 'when expiration is within 5 minutes' do
      let!(:start_time) { Time.now }
      let(:expiration)  { start_time + 3600 }
      let(:expiration2) { start_time + 3600 + 3600 }
      let(:signature) do
        '2865f4c918c812c0319cd4e4a734a3eb5dceffbd19c105b6fda1cf3b084d88c7'
      end
      let(:signature2) do
        '7801ed64603c8496d8562faa81bb3438cb626483041cff2b83fbb8aa5a724dae'
      end

      before do
        stub_request(:get, "#{security_credentials_url}test-iam").to_return(
          security_credentials_response
        ).to_return(
          security_credentials_response2
        )
      end

      it do
        expect(client.get('/account').body).to eq response

        Timecop.freeze(expiration - 299)
        stubs.get('/account') do |env|
          expect(env.request_headers).to eq expected_headers2
          [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
        end

        expect(client.get('/account').body).to eq response
      end
    end

    context 'when the credential is expired' do
      let!(:start_time) { Time.now }
      let(:expiration)  { start_time + 3600 }
      let(:expiration2) { start_time + 3600 + 3600 }
      let(:signature) do
        '2865f4c918c812c0319cd4e4a734a3eb5dceffbd19c105b6fda1cf3b084d88c7'
      end
      let(:signature2) do
        '690a995ba60b9d04d9f3a19c9c649b4c69da782feda56a76fcf9c7053e724d58'
      end

      before do
        stub_request(:get, "#{security_credentials_url}test-iam").to_return(
          security_credentials_response
        ).to_return(
          security_credentials_response2
        )
      end

      it do
        expect(client.get('/account').body).to eq response

        Timecop.freeze(expiration)

        stubs.get('/account') do |env|
          expect(env.request_headers).to eq expected_headers2
          [200, {'Content-Type' => 'application/json'}, JSON.dump(response)]
        end

        expect(client.get('/account').body).to eq response
      end
    end
  end
end
