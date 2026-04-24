describe Xapi::StateWriter, if: DynamoConfig.use_local?,
                            use_local_dynamodb: true do
  let(:user) { create(:student) }
  let(:user_token) do
    XapiUserToken.new(
      attempt_id: attempt.id,
      state_modifiable: true,
      user_id: user.id
    )
  end

  let(:payload) { 'some payload' }
  let(:new_payload) { 'new payload' }
  let(:milliseconds_spent) { 2045 }
  let(:new_milliseconds_spent) { milliseconds_spent + 60_000 }
  let(:page_location) { '#/lang/en/pag/2f6e65a01fe52899e7bc9ec3300d452c||en' }
  let(:new_page_location) { 'new location' }

  let(:learning_module_id) { 'https://netexlearning.com/487203' }
  let(:state_id_prefix) { "#{Rails.env}_#{Socket.gethostname}_" }
  let(:state_id) { "#{state_id_prefix}#{attempt.id}" }

  let(:state_writer) do
    described_class.new(
      agent: { mbox: user_token.mbox }.to_json,
      activityId: learning_module_id,
      state: {
        location: new_page_location,
        suspend: new_payload,
        totalTime: new_milliseconds_spent
      }
    )
  end

  describe '#update' do
    context 'when no attempt exists,' do
      let(:attempt) { build_stubbed(:attempt) }

      it 'raises an error and does not create a new page state record' do
        expect { state_writer.update }.to raise_error(ArgumentError)
      end

      it 'does not create any activity state record' do
        begin
          state_writer.update
        rescue ArgumentError
          expect(Xapi::ActivityState.scan.to_a).to eq([])
        end
      end
    end

    context 'when an attempt exists but no activity state exists' do
      let(:attempt) { create(:attempt, user: user) }

      it 'creates a new page state record' do
        state_writer.update
        record = Xapi::ActivityState.find(id: state_id)

        expect(record).to have_attributes(
          activity_id: attempt.activity.id,
          milliseconds_spent: new_milliseconds_spent,
          page_location: new_page_location,
          payload: new_payload,
          section_id: attempt.section.id,
          user_id: user.id
        )
      end
    end

    context 'when an attempt and an activity state exist' do
      let(:attempt) { create(:attempt, user: user) }

      before do
        Xapi::ActivityState.new(
          activity_id: attempt.activity_id,
          id: state_id,
          milliseconds_spent: milliseconds_spent,
          page_location: page_location,
          payload: payload,
          section_id: attempt.section_id,
          user_id: attempt.user_id
        ).save!
      end

      it 'updates the existing activity state' do
        state_writer.update
        record = Xapi::ActivityState.find(id: state_id)

        expect(record).to have_attributes(
          activity_id: attempt.activity_id,
          section_id: attempt.section_id,
          user_id: attempt.user_id,
          page_location: new_page_location,
          milliseconds_spent: new_milliseconds_spent,
          payload: new_payload
        )
      end
    end

    context 'when state is not modifiable' do
      let(:attempt) { create(:attempt, user: user) }
      let(:user_token) do
        XapiUserToken.new(
          attempt_id: attempt.id,
          state_modifiable: false,
          user_id: user.id
        )
      end

      it 'does not create a new record when no activity state exists' do
        state_writer.update

        expect(Xapi::ActivityState.scan.to_a).to eq([])
      end

      it 'does not update an existing activity state' do
        old_attrs = {
          activity_id: attempt.activity_id,
          milliseconds_spent: milliseconds_spent,
          page_location: page_location,
          payload: payload,
          section_id: attempt.section_id,
          user_id: attempt.user_id
        }
        Xapi::ActivityState.new(old_attrs.merge(id: state_id)).save!

        state_writer.update
        record = Xapi::ActivityState.find(id: state_id)

        expect(record).to have_attributes(old_attrs)
      end
    end
  end
end
