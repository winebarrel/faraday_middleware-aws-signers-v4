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
    'host;user-agent;x-amz-content-sha256;x-amz-date'
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
      'd25bb10ed5b6735974a3d1e0bae0bd8e4e28bddfd03a39e3e9ada780d54990a7'
    end

    subject { client.get('/account').body }

    it { is_expected.to eq response }
  end

  context 'with query' do
    subject { client.get('/account', params).body }

    context 'include space' do
      let(:signature) do
        '1fab19a15836760910137069dfe5393a758047569f5efd276e09d3f40bc8e166'
      end

      let(:params) { {foo: 'b a r', zoo: 'b a z'} }

      it { is_expected.to eq response }
    end

    context 'not include space' do
      let(:signature) do
        'be8933a42d7517c7a9fba59f5440a3f920f21252376931c0dedeebf6c7d507eb'
      end

      let(:params) { {foo: 'bar', zoo: 'baz'} }

      it { is_expected.to eq response }
    end
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
          "SignedHeaders=host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-security-token",
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
          "SignedHeaders=host;user-agent;x-amz-content-sha256;x-amz-date;x-amz-security-token",
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
        '5db3e32fa139305425af96b4d8d2d1633baf4025fdf09a30c435dc6f50d841e2'
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
        '5db3e32fa139305425af96b4d8d2d1633baf4025fdf09a30c435dc6f50d841e2'
      end
      let(:signature2) do
        'c5823ad86dae5962dee6226a1b03d703f679838a627663f112c40b7534510e9f'
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
        '5db3e32fa139305425af96b4d8d2d1633baf4025fdf09a30c435dc6f50d841e2'
      end
      let(:signature2) do
        'd2c1eeb728b800bcd9ef31589f8a2c3210ff8ae61bc5444f06cb05c73c4f031b'
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
