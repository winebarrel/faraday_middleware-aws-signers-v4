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

  let(:expected_headers) do
    {"User-Agent"=>"Faraday v0.9.1",
     "X-Amz-Date"=>"20150101T000000Z",
     "Host"=>"apigateway.us-east-1.amazonaws.com",
     "X-Amz-Content-Sha256"=>
      "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "Authorization"=>
      "AWS4-HMAC-SHA256 Credential=akid/20150101/us-east-1/apigateway/aws4_request, " +
      "SignedHeaders=host;user-agent;x-amz-content-sha256;x-amz-date, " +
      "Signature=d25bb10ed5b6735974a3d1e0bae0bd8e4e28bddfd03a39e3e9ada780d54990a7"}
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

  subject { client.get('/account').body }

  it { is_expected.to eq response }
end
