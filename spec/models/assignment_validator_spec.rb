describe AssignmentValidator, core: true do
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:course) { create(:course, school:, owner: instructor) }
  let(:activity) do
    create(:activity, activity_type: 'open_ended', license_group_id: 1, title: 'foo')
  end
  let(:group_chat_activity) do
    create(:activity, activity_type: 'group_chat', license_group_id: 1)
  end
  let(:pchat_activity) do
    create(:activity, activity_type: 'partner_chat', license_group_id: 1)
  end

  let(:ai_virtual_chat_activity) do
    create(:activity, activity_type: 'ai_virtual_chat', license_group_id: 1)
  end

  let(:validator) { described_class.new(instructor, course, [activity]) }

  describe '#validate' do
    context 'for a course with sections' do
      before { allow(course).to receive(:sections_count).and_return(1) }

      context 'when the instructor does not have a license group for an activity' do
        it 'adds the activity to an unassignable list' do
          expect(Maestro::CourseLicense).to receive(:all).with(course.guid).and_return([])
          validator.validate
          expect(validator.invalid_activities).to eq([activity])
          expect(validator.valid_activities).to eq([])
        end
      end
    end

    context 'for a course without sections' do
      it 'does not hit the api' do
        expect(Maestro::CourseLicense).not_to receive(:all)
        validator.validate
      end

      it 'adds the activity to an unassignable list' do
        validator.validate
        expect(validator.invalid_activities).to eq([activity])
        expect(validator.valid_activities).to eq([])
      end
    end

    context 'when the instructor has a license group for an activity' do
      let!(:license_group) { double('LicenseGroup', id: 1) }
      let!(:course_license) { double('CourseLicense', license_group: license_group) }

      context 'in a course with sections' do
        before { allow(course).to receive(:sections_count).and_return(1) }

        it 'adds the activity to an assignable list' do
          expect(Maestro::CourseLicense).to receive(:all).with(course.guid).and_return([course_license])
          validator.validate
          expect(validator.invalid_activities).to eq([])
          expect(validator.valid_activities).to eq([activity])
        end
      end

      context 'in a course without sections' do
        it 'adds the activity to an unassignable list' do
          validator.validate
          expect(validator.invalid_activities).to eq([activity])
          expect(validator.valid_activities).to eq([])
        end
      end
    end
  end

  describe '#invalid_activity_assignments' do
    it 'returns an array of ActivityAssignment objects with error messages' do
      errors = double('Errors')
      activity_assignment = double('ActivityAssignment', errors: errors)
      expect(errors).to receive(:add).with(:base, 'foo was not updated because you do not have access to it')
      expect(ActivityAssignment).to receive(:new).with(activity, instructor, activity.program, { course_id: course.id }).and_return(activity_assignment)
      allow(validator).to receive(:invalid_activities).and_return([activity])
      expect(validator.invalid_activity_assignments).to eq([activity_assignment])
    end
  end

  describe '#assignable?' do
    shared_examples 'checks drafts status and license group' do
      it 'returns false when the activity is a draft' do
        activity.update!(draft: true)

        expect(validator.assignable?(activity)).to be_falsey
      end

      context 'when the activity license group is in the list of license group ids for the course' do
        it 'returns true' do
          allow(validator).to receive(:license_group_ids).and_return(
            [activity.license_group_id]
          )
          expect(validator.assignable?(activity)).to be_truthy
        end
      end

      context 'when the activity license group is not in the list of license group ids for the course' do
        it 'returns false' do
          allow(validator).to receive(:license_group_ids).and_return([])
          expect(validator.assignable?(activity)).to be_falsey
        end
      end
    end

    context 'when the school has disabled chat support' do
      before do
        create(:school_config, school:, chat_support_disabled: true)
      end

      it 'returns false for partner chat activities' do
        allow(validator).to receive(:license_group_ids).and_return(
          [pchat_activity.license_group_id]
        )

        expect(validator.assignable?(pchat_activity)).to be_falsey
      end

      it 'returns false for ai virtual chat activities' do
        allow(validator).to receive(:license_group_ids).and_return(
          [ai_virtual_chat_activity.license_group_id]
        )

        expect(validator.assignable?(ai_virtual_chat_activity)).to be_falsey
      end

      it 'returns false for group chat activities' do
        allow(validator).to receive(:license_group_ids).and_return(
          [group_chat_activity.license_group_id]
        )

        expect(validator.assignable?(group_chat_activity)).to be_falsey
      end

      context 'when the activity is not a partner/group chat activity,' do
        include_examples 'checks drafts status and license group'
      end
    end

    context 'when the school has enabled chat support' do
      context 'when the course has chat support enabled,' do
        context 'when the activity is a partner chat activity,' do
          let(:activity) { pchat_activity }

          include_examples 'checks drafts status and license group'
        end

        context 'when the activity is a group chat activity,' do
          let(:activity) { group_chat_activity }

          include_examples 'checks drafts status and license group'
        end
      end

      context 'when the course has chat support disabled,' do
        before do
          course.update!(chat_level: 'disabled')
        end

        it 'returns false for partner chat activities' do
          allow(validator).to receive(:license_group_ids).and_return(
            [pchat_activity.license_group_id]
          )

          expect(validator.assignable?(pchat_activity)).to be_falsey
        end

        it 'returns false for group chat activities' do
          allow(validator).to receive(:license_group_ids).and_return(
            [group_chat_activity.license_group_id]
          )

          expect(validator.assignable?(group_chat_activity)).to be_falsey
        end

        context 'when the activity is not a partner/group chat activity,' do
          include_examples 'checks drafts status and license group'
        end
      end

      context 'when there is no course,' do
        context 'when the activity is a partner chat activity,' do
          let(:activity) { pchat_activity }

          include_examples 'checks drafts status and license group'
        end

        context 'when the activity is a group chat activity,' do
          let(:activity) { group_chat_activity }

          include_examples 'checks drafts status and license group'
        end

        context 'when the activity is not a partner/group chat activity,' do
          include_examples 'checks drafts status and license group'
        end
      end
    end
  end

  describe '#unassignable_reason' do
    context 'when the activity is teacher edition' do
      let(:te_activity) { create(:e_reader_item) }

      it 'returns a teacher edition unassignable reason' do
        expect(validator.unassignable_reason(te_activity)).to eq(:unassignable_teacher_edition)
      end
    end

    context 'when the activity is ai virtual chat and the course has ai virtual chat disabled' do
      let(:activity) { ai_virtual_chat_activity }

      it 'returns a ai virtual chat unassignable reason' do
        allow(validator).to receive(:ai_virtual_chat_enabled?).and_return(false)
        expect(validator.unassignable_reason(activity)).to eq(:unassignable_ai_virtual_chat)
      end
    end

    context 'when the activity is group chat and the school chat support is disabled' do
      let(:activity) { group_chat_activity }

      it 'returns a chat disabled unassignable reason' do
        allow(validator).to receive(:school_chat_support_disabled?).and_return(true)
        expect(validator.unassignable_reason(activity)).to eq(
          :unassignable_chat_disabled_at_school_level
        )
      end
    end

    context 'when the activity is partner chat and the school chat support is disabled' do
      let(:activity) { pchat_activity }

      it 'returns a chat disabled unassignable reason' do
        allow(validator).to receive(:school_chat_support_disabled?).and_return(true)
        expect(validator.unassignable_reason(activity)).to eq(
          :unassignable_chat_disabled_at_school_level
        )
      end
    end

    context 'when the activity is group chat and the course has chat disabled' do
      let(:activity) { group_chat_activity }

      it 'returns a unassignable chat activity reason' do
        allow(course).to receive(:chat_disabled?).and_return(true)
        expect(validator.unassignable_reason(activity)).to eq(:unassignable_chat_activity)
      end
    end

    context 'when the activity is partner chat and the course has chat disabled' do
      let(:activity) { pchat_activity }

      it 'returns a unassignable chat activity reason' do
        allow(course).to receive(:chat_disabled?).and_return(true)
        expect(validator.unassignable_reason(activity)).to eq(:unassignable_chat_activity)
      end
    end

    context 'when the license does not cover the activity license group' do
      it 'returns a unassignable missing license reason' do
        expect(validator.unassignable_reason(activity)).to eq(:unassignable_missing_license)
      end
    end
  end

  describe '#any_assignable?' do
    context 'when any of the activities passed in are assignable' do
      it 'returns true' do
        allow(validator).to receive(:license_group_ids).and_return([1])
        expect(validator.any_assignable?([activity])).to be_truthy
      end
    end

    context 'when none of the activities passed in are not assignable' do
      it 'returns false' do
        allow(validator).to receive(:license_group_ids).and_return([2])
        expect(validator.any_assignable?([activity])).to be_falsey
      end
    end
  end

  describe '#course_licenses' do
    context 'when course is nil' do
      it 'returns an empty array' do
        allow(validator).to receive(:course).and_return(nil)
        expect(validator.course_licenses).to eq([])
      end
    end

    context 'when course is not nil' do
      context 'but there are no sections' do
        before { allow(course).to receive(:sections_count).and_return(0) }

        it 'returns an empty array' do
          expect(validator.course_licenses).to eq([])
        end
      end

      context 'and there is at least one section' do
        before { allow(course).to receive(:sections_count).and_return(1) }

        it 'fetches an array of course licenses from the API' do
          course_license = double('CourseLicense')
          expect(Maestro::CourseLicense).to receive(:all).with(course.guid).and_return([course_license])
          expect(validator.course_licenses).to eq([course_license])
        end
      end
    end
  end
end
