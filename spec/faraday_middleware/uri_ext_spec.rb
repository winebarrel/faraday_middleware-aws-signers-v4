describe URI do
  subject { URI.seahorse_encode_www_form(params) }

  context 'not include space' do
    let(:params) do
      [['foo', 'bar'], ['bar', ['zoo', 'baz']], ['baz', nil]]
    end

    it do
      is_expected.to eq URI.encode_www_form(params)
    end
  end

  context 'include space' do
    let(:params) do
      [['foo', 'b a r'], ['bar', ['z o o', 'baz']], ['baz', nil]]
    end

    it do
      is_expected.to eq 'foo=b%20a%20r&bar=z%20o%20o&bar=baz&baz'
      is_expected.to_not eq URI.encode_www_form(params)
    end
  end
end
