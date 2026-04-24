describe StudentTimeLimitsPresenter do
  let(:default_time_limit) { 60 }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }

  before do
    create(:enrollment, section: section, user: student_1)
    create(:enrollment, section: section, user: student_2)
    create(:assignment,
           assignable_id: activity.id,
           assignable_type: 'Activity',
           assigned_assessment_detail: create(:assigned_assessment_detail,
                                              time_limit: default_time_limit),
           section_id: section.id)
  end

  describe '#assignment_time_limit' do
    it 'returns the time limit from the assignment' do
      presenter = described_class.new(section_id: section.id, activity_id: activity.id)
      expect(presenter.assignment_time_limit).to eq(default_time_limit)
    end
  end

  describe '#student_time_limit_index' do
    let(:student_3) { create(:student) }

    before do
      allow(section).to receive(:current_students).and_return([student_1, student_2, student_3])
      create(:enrollment, section: section, user: student_3)
    end

    context 'when there are no custom time limits' do
      it 'returns an array of student information hashes alphabetized by student name' do
        expected_results = [{ user_id: student_2.id,
                              name: student_2.last_name_first,
                              time_limit: nil },
                            { user_id: student_1.id,
                              name: student_1.last_name_first,
                              time_limit: nil },
                            { user_id: student_3.id,
                              name: student_3.last_name_first,
                              time_limit: nil }].sort_by { |s| s[:name] }
        presenter = described_class.new(section_id: section.id, activity_id: activity.id)
        expect(presenter.student_time_limit_index).to eq(expected_results)
      end
    end

    context 'when there are custom time limits' do
      let!(:unlimited_time_limit) do
        create(
          :assessment_student_time_limit,
          user_id: student_1.id,
          section_id: section.id,
          activity_id: activity.id,
          time_limit: 0
        )
      end

      let!(:custom_time_limit) do
        create(
          :assessment_student_time_limit,
          user_id: student_2.id,
          section_id: section.id,
          activity_id: activity.id,
          time_limit: 100
        )
      end

      let(:presenter) { described_class.new(section_id: section.id, activity_id: activity.id) }

      it 'returns an array of student information hashes with the unlimited students first' do
        unlimited_student = { user_id: student_1.id,
                              name: student_1.last_name_first,
                              time_limit: unlimited_time_limit.time_limit }
        expect(presenter.student_time_limit_index[0]).to eq(unlimited_student)
      end

      it 'returns an array of student information hashes with the custom limit students second' do
        custom_student = { user_id: student_2.id,
                           name: student_2.last_name_first,
                           time_limit: custom_time_limit.time_limit }
        expect(presenter.student_time_limit_index[1]).to eq(custom_student)
      end

      it 'returns an array of student information hashes with the default limit students last' do
        default_student = { user_id: student_3.id,
                            name: student_3.last_name_first,
                            time_limit: nil }
        expect(presenter.student_time_limit_index.last).to eq(default_student)
      end
    end
  end

  describe '#process_time_limits' do
    context 'when there is no custom user time limit set' do
      it 'creates a new record when a new value is submitted' do
        submitted_data = { activity_id: activity.id,
                           section_id: section.id,
                           time_limit: { student_1.id => '65' } }
        presenter = described_class.new(**submitted_data)
        expect { presenter.process_time_limits }
          .to change(AssessmentStudentTimeLimit, :count)
          .by(1)
      end

      it 'does not create a record when the value submitted is blank' do
        submitted_data = { activity_id: activity.id,
                           section_id: section.id,
                           time_limit: { student_1.id => '' } }
        presenter = described_class.new(**submitted_data)
        expect { presenter.process_time_limits }
          .not_to change(AssessmentStudentTimeLimit, :count)
      end

      it 'does not return an error if there are trailing spaces' do
        submitted_data = { activity_id: activity.id,
                           section_id: section.id,
                           time_limit: { student_1.id => '80  ' } }
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        expect(presenter.errors).to be_empty
      end

      it 'does not return an error if there are leading spaces' do
        submitted_data = { activity_id: activity.id,
                           section_id: section.id,
                           time_limit: { student_1.id => '  25' } }
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        expect(presenter.errors).to be_empty
      end
    end

    context 'when there is an existing custom user time limit set' do
      let!(:student_1_time_limit) do
        create(
          :assessment_student_time_limit,
          user_id: student_1.id,
          section_id: section.id,
          activity_id: activity.id,
          time_limit: 75
        )
      end

      let!(:student_2_time_limit) do
        create(
          :assessment_student_time_limit,
          user_id: student_2.id,
          section_id: section.id,
          activity_id: activity.id,
          time_limit: 90
        )
      end

      let(:submitted_data) do
        { activity_id: activity.id,
          section_id: section.id,
          time_limit: { student_1.id => '65',
                        student_2.id => '' } }
      end

      it 'updates the record if the value submitted is different' do
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        tlr = AssessmentStudentTimeLimit.student_time_limit(section.id,
                                                            activity.id,
                                                            student_1.id)
        expect(tlr.time_limit).to eq submitted_data[:time_limit][student_1.id].to_i
      end

      it 'removes the record if the submitted value is blank' do
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        tlr = AssessmentStudentTimeLimit.student_time_limit(section.id,
                                                            activity.id,
                                                            student_2.id)
        expect(tlr).to be_nil
      end
    end

    context 'when the submitted time limit is invalid' do
      let(:student_3) { build_stubbed(:student) }
      let(:student_4) { build_stubbed(:student) }
      let(:submitted_data) do
        { activity_id: activity.id,
          section_id: section.id,
          time_limit: { student_1.id => '1.5',
                        student_2.id => '-30',
                        student_3.id => 'some string',
                        student_4.id => '1'
                      }
        }
      end

      it 'will return false' do
        presenter = described_class.new(**submitted_data)
        expect(presenter.process_time_limits).to be false
      end

      it 'will populate an errors array' do
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        expect(presenter.errors).to_not be_empty
      end

      it 'populates an errors hash keyed on user_id' do
        presenter = described_class.new(**submitted_data)
        presenter.process_time_limits
        expect(presenter.errors.keys).to match [student_1.id, student_2.id, student_3.id, student_4.id]
      end
    end

    it 'can set the time limit to be unlimited' do
      submitted_data = { activity_id: activity.id,
                         section_id: section.id,
                         time_limit: { student_1.id => '0' } }
      presenter = described_class.new(**submitted_data)
      expect(presenter).to receive(:set_unlimited_time_limit).with(student_1.id)
      presenter.process_time_limits
    end
  end

  describe '#student_time_limit' do
    let!(:student_time_limit) do
      create(:assessment_student_time_limit, user_id: student_1.id,
                                             section_id: section.id,
                                             activity_id: activity.id,
                                             time_limit: 75)
    end
    let(:student_2) { build_stubbed(:student) }

    it 'returns the time_limit record for a student' do
      presenter = described_class.new(activity_id: activity.id, section_id: section.id)
      expect(presenter.student_time_limit(student_1.id).time_limit).to eq 75
    end

    it 'returns nil when there is no record' do
      presenter = described_class.new(activity_id: activity.id, section_id: section.id)
      expect(presenter.student_time_limit(student_2.id)).to be_nil
    end
  end

  describe '#custom?' do
    let(:presenter) { described_class.new(activity_id: activity.id, section_id: section.id) }

    context 'when the time limit is greater than 0' do
      it 'returns true' do
        expect(presenter.custom?(time_limit: 48)).to be true
      end
    end

    context 'when the time limit is less than 1' do
      it 'returns false' do
        expect(presenter.custom?(time_limit: 0)).to be false
      end
    end
  end

  describe '#unlimited?' do
    let(:presenter) { described_class.new(activity_id: activity.id, section_id: section.id) }

    context 'when the time limit is 0' do
      it 'returns true' do
        expect(presenter.unlimited?(time_limit: 0)).to be true
      end
    end

    context 'when the time limit is not 0' do
      it 'returns false' do
        expect(presenter.unlimited?(time_limit: 100)).to be false
      end
    end
  end

  describe '#select_value' do
    let(:presenter) { described_class.new(activity_id: activity.id, section_id: section.id) }

    context 'when the time limit is custom' do
      it 'returns "Custom"' do
        expect(presenter.select_value(time_limit: 48)).to eq 'Custom'
      end
    end

    context 'when the time limit is unlimited' do
      it 'returns "Unlimited"' do
        expect(presenter.select_value(time_limit: 0)).to eq 'Unlimited'
      end
    end

    context 'when the time limit is not custom nor unlimited' do
      it 'returns "Default"' do
        expect(presenter.select_value(time_limit: nil)).to eq 'Default'
      end
    end
  end
end
