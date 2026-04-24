describe Xapi::StateReader, if: DynamoConfig.use_local?,
                            use_local_dynamodb: true do
  let(:user) { create(:student) }
  let(:user_token) { XapiUserToken.new(user_id: user.id, attempt_id: attempt.id) }
  let(:learning_module_id) { 'https://netexlearning.com/487203' }
  let(:state_id_prefix) { "#{Rails.env}_#{Socket.gethostname}_" }

  def new_reader(attempt_id)
    user_token = XapiUserToken.new(user_id: user.id, attempt_id: attempt_id)

    described_class.new(
      agent: { mbox: user_token.mbox }.to_json,
      activityId: learning_module_id
    )
  end

  describe '#record_exists?' do
    it 'raises an error when no attempt exists' do
      expect { new_reader(nil).record_exists? }.to raise_error(ArgumentError)
    end

    it 'returns false when an attempt exists but no activity state exists' do
      attempt = create(:attempt, user: user)
      expect(new_reader(attempt.id).record_exists?).to eq(false)
    end

    it 'returns true when an attempt and an activity state exist' do
      attempt = create(:attempt, user: user)
      state_id = "#{state_id_prefix}#{attempt.id}"
      Xapi::ActivityState.new(id: state_id).save!

      expect(new_reader(attempt.id).record_exists?).to eq(true)
    end
  end

  describe '#serialize' do
    it 'raises an error when no attempt exists' do
      expect { new_reader(nil).serialize }.to raise_error(ArgumentError)
    end

    it 'raises an error when an attempt exists but no activity state exists' do
      attempt = create(:attempt, user: user)

      expect { new_reader(attempt.id).serialize }.to raise_error(NoMethodError)
    end

    it 'returns the serialized page state when an attempt and an activity ' \
       'state exist' do
      attempt = create(:attempt, user: user)
      milliseconds_spent = 2045
      page_location = '#/lang/en/pag/2f6e65a01fe52899e7bc9ec3300d452c||en'
      payload = 'some payload'
      state_id = "#{state_id_prefix}#{attempt.id}"

      Xapi::ActivityState.new(
        id: state_id,
        milliseconds_spent: milliseconds_spent,
        page_location: page_location,
        payload: payload
      ).save!

      expect(new_reader(attempt.id).serialize).to eq(
        location: page_location,
        suspend: payload,
        totalTime: milliseconds_spent
      )
    end
  end
end
