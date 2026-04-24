describe Xapi::BasicAuthCredential, if: DynamoConfig.use_local?,
                                    use_local_dynamodb: true do
  around do |example|
    # credentials expire_at attribute is based on the current time. So we wrap all
    # the examples with Timecop to be able to check the expires_at value
    Timecop.freeze(Time.now) do
      example.run
    end
  end

  let(:user) { create(:user) }

  # rubocop:disable RSpec/PredicateMatcher
  # Because `be_valid_credentials` doesn't make sense for a class method.
  describe '.valid_credentials?' do
    let(:username) { 'username' }
    let(:password) { 'password' }
    let(:credentials) { "#{username}:#{password}" }

    it 'returns false when no record exists with the specified credentials' do
      expect(
        described_class.valid_credentials?(username, password)
      ).to be_falsey
    end

    context 'when an unexpired item exists with the specified credentials,' do
      let(:old_expires_at) { Time.now.utc + 3600 }

      before do
        described_class.new(
          credentials: credentials,
          expires_at: old_expires_at
        ).save!
      end

      it 'extends the expiration time of the item' do
        described_class.valid_credentials?(username, password)

        record = described_class.find(credentials: credentials)

        expect(record.expires_at).to be_within(1.second).of(
          Time.now.utc + described_class::TIME_TO_LIVE_SEC
        )
      end

      it 'returns true' do
        expect(
          described_class.valid_credentials?(username, password)
        ).to be_truthy
      end
    end

    context 'when an expired item exists with the specified credentials,' do
      let(:old_expires_at) { Time.now.utc - 1 }

      before do
        described_class.new(
          credentials: credentials,
          expires_at: old_expires_at
        ).save!
      end

      it 'does not extend the expiration time of the item' do
        record = described_class.find(credentials: credentials)

        expect(record.expires_at).to be_within(1.second).of(old_expires_at)
      end

      it 'returns false' do
        expect(
          described_class.valid_credentials?(username, password)
        ).to be_falsey
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher

  describe '.generate_credentials' do
    let(:uuid) { 'some_uuid' }
    let(:credentials) { "#{uuid}:#{uuid}" }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
    end

    it 'returns new random credentials encoded in an http authorization' do
      authorization = described_class.generate_credentials(user)
      expect(authorization).to eq(
        "Basic #{::Base64.strict_encode64(credentials)}"
      )
    end

    it 'saves the credentials into the dynamodb table' do
      described_class.generate_credentials(user)

      record = described_class.find(credentials: credentials)

      expect(record).to have_attributes(
        creation_time: be_within(1.second).of(Time.now.utc),
        credentials: credentials,
        expires_at: be_within(1.second).of(Time.now.utc + described_class::TIME_TO_LIVE_SEC),
        vhlcentral_guid: user.guid
      )
    end
  end
end
