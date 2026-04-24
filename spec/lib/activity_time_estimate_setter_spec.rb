describe ActivityTimeEstimateSetter do
  let(:activity)  do
    build(
      :activity,
      activity_type: 'fill_in_the_blanks',
      minutes_to_complete: 0
    )
  end
  let(:setter)  { described_class.new(activity: activity) }

  it 'requires activity or activity_type' do
    expect { described_class.new }.to raise_error ArgumentError
    expect { described_class.new(activity: activity) }.to_not raise_error
    expect { described_class.new(activity_type: 'open_ended') }.to_not raise_error
  end

  it 'accepts pre-loaded estimates' do
    timings = described_class.estimates
    expect(YAML).to_not receive(:load)

    setter = described_class.new(activity: activity, estimates: timings)
    expect(setter.time_to_complete).to eq 8
  end

  it 'accepts an activity_type' do
    setter = described_class.new(activity_type: 'multiple_choice')
    expect(setter.time_to_complete).to eq 4
  end

  it 'down-cases the type' do
    allow(activity).to receive(:activity_type).and_return('Multiple_Choice')
    setter = described_class.new(activity: activity)
    expect(setter.time_to_complete).to eq(4)

    setter = described_class.new(activity_type: 'drop_down_SAME')
    expect(setter.time_to_complete).to eq(4)
  end

  describe '#apply' do
    context 'for a new record' do
      it 'requires an activity' do
        setter = described_class.new(activity_type: 'open_ended')
        expect { setter.apply }.to raise_error ActiveRecord::ActiveRecordError
      end

      it 'updates minutes_to_complete' do
        setter = described_class.new(activity: activity).apply
        expect(activity.minutes_to_complete).to eq 8
      end

      it 'does not save the record' do
        expect do
          described_class.new(activity: activity).apply
        end.not_to change(Activity, :count)
      end
    end

    context 'for an existing record' do
      before do
        activity.save
      end

      it 'updates minutes_to_complete' do
        setter = described_class.new(activity: activity).apply
        expect(activity.minutes_to_complete).to eq 8
      end

      it 'does not save the record' do
        described_class.new(activity: activity).apply
        expect(activity.minutes_to_complete).to eq 8
        expect(Activity.last.minutes_to_complete).to eq 0
      end
    end
  end

  describe '#update' do
    it 'requires an activity' do
      setter = described_class.new(activity_type: 'open_ended')
      expect { setter.update }.to raise_error ActiveRecord::ActiveRecordError
    end

    context 'for a new record' do
      it 'will not update the record' do
        expect do
          described_class.new(activity: activity).update
        end.to raise_error ActiveRecord::ActiveRecordError
      end
    end

    context 'for an existing record' do
      before do
        # in spite of the callback that sets minutes_to_complete
        # this object has no content_object so the value will be 0
        # if this was a simple save.
        activity.update!(minutes_to_complete: 8)
      end

      it 'updates the record' do
        # reset minutes_to_complete for this test
        activity.update_column(:minutes_to_complete, 0)

        described_class.new(activity: activity).update
        expect(Activity.last.minutes_to_complete).to eq 8
      end

      it 'does not save the record if the value has not changed' do
        # the value will be set correctly in the before block
        expect(activity).to_not receive(:update_column)
        described_class.new(activity: activity).update
      end
    end
  end

  describe '#time_to_complete' do
    it 'returns the base value for a book' do
      expect(setter.time_to_complete).to eq(8)
    end

    it 'returns 10 as a default' do
      allow(activity).to receive(:activity_type).and_return('unknown_type')
      setter = described_class.new(activity: activity)
      expect(setter.time_to_complete).to eq(10)
    end
  end
end
