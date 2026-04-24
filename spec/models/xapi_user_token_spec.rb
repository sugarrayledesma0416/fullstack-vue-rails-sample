describe XapiUserToken do
  let(:user_id) { 21 }
  let(:attempt_id) { 42 }
  let(:state_modifiable) { true }
  let(:attrs) { { user_id: user_id, attempt_id: attempt_id, state_modifiable: state_modifiable } }
  let(:key) { Rails.application.config.xapi_encryption_key }
  let(:wrong_key) { 'Wrong key, Wrong key, Wrong key.' }
  let(:encoded_attrs) { Base64.urlsafe_encode64(encrypt(attrs.to_json, key)) }
  let(:mbox) { "mailto:#{encoded_attrs}" }

  def encrypt(msg, key)
    encryptor = ActiveSupport::MessageEncryptor.new(key)
    encryptor.encrypt_and_sign(msg)
  end

  describe '#initialize' do
    context 'when the mbox attribute is present' do
      let(:mbox) { 'some mbox' }
      let(:token) { described_class.new(mbox: mbox, user_id: user_id) }

      it 'stores the mbox attribute' do
        expect(token.mbox).to eq(mbox)
      end

      it 'does not store other attributes' do
        expect(token.user_id).not_to eq(user_id)
      end
    end

    context 'when the mbox attribute is not present' do
      let(:token) { described_class.new(user_id: user_id, unused_attr: 'unused') }

      it 'stores attributes used to generate the token' do
        expect(token.attrs).to include(:user_id)
      end

      it 'does not store attributes not used to generate the token' do
        expect(token.attrs).not_to include(:unused_attr)
      end
    end
  end

  describe '#attrs' do
    context 'when the mbox attribute is present' do
      it 'decrypt the attributes when a "mailto:" prefix is present' do
        token = described_class.new(mbox: "mailto:#{encoded_attrs}")
        expect(token.attrs).to eq(attrs)
      end

      it 'decrypt the attributes when no "mailto:" prefix is present' do
        token = described_class.new(mbox: encoded_attrs)
        expect(token.attrs).to eq(attrs)
      end

      it 'returns no attributes when the mbox is not base64 encoded' do
        token = described_class.new(mbox: encrypt(attrs.to_json, key))
        expect(token.attrs).to be_empty
      end

      it 'returns no attributes when the mbox cannot be decrypted' do
        mbox = Base64.urlsafe_encode64(encrypt(attrs.to_json, wrong_key))
        token = described_class.new(mbox: mbox)
        expect(token.attrs).to be_empty
      end

      it 'returns no attributes when the mbox cannot be parsed as json' do
        attrs = '{user_id: 3}'
        mbox = Base64.urlsafe_encode64(encrypt(attrs, key))
        token = described_class.new(mbox: mbox)
        expect(token.attrs).to be_empty
      end
    end

    context 'when the mbox attribute is not present' do
      it 'returns the token attributes' do
        token = described_class.new(attrs)
        expect(token.attrs).to eq(attrs)
      end
    end
  end

  describe '#user_id' do
    it 'returns the user_id attribute' do
      token = described_class.new(attrs)
      expect(token.user_id).to eq(user_id)
    end
  end

  describe '#attempt_id' do
    it 'returns the attempt_id attribute' do
      token = described_class.new(attrs)
      expect(token.attempt_id).to eq(attempt_id)
    end
  end

  describe '#state_modifiable' do
    it 'returns the state_modifiable attribute' do
      token = described_class.new(attrs)
      expect(token.state_modifiable).to eq(state_modifiable)
    end
  end
end
