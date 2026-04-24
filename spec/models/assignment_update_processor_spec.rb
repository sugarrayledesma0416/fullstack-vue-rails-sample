describe AssignmentUpdateProcessor, :core => true do
  let(:instructor) { create(:instructor) }
  let(:activity_1) { create(:activity, toc_location: toc_entry.id) }
  let(:lesson) { create(:lesson) }
  let(:toc_entry) { create(:toc_entry, id: 123456) }
  let(:program) { create(:program) }
  let(:category) { create(:category) }
  let(:course) do
    create(
      :course,
      program: program,
      start_date: Date.parse(due_date) - 1.week,
      end_date: Date.parse(due_date) + 1.week
    )
  end

  let(:section) { create(:section, course: course) }
  let(:focus) { double(Focus, section: section, course: course, sections: [section]) }
  let(:due_date) { Date.today.strftime("%m/%d/%Y") }
  let(:activity_validator) do
    instance_double(
      'AssignmentValidator',
      valid_activities: [activity_1],
      invalid_activity_assignments: [],
      validate: nil
    )
  end

  let(:processor) { AssignmentUpdateProcessor.new(params, instructor, focus) }
  let(:params) do
    {
      activity_assignment: {
        due_date: due_date,
        category_id: category.id
      },
      selected_activities: activity_1.id.to_s,
      selected_resources:"",
      update_type: "assign"
    }
  end

  let(:unassign_params) { params.merge(update_type: 'unassign') }
  let(:s3) { double(Radner::S3Storage, fetch: true) }

  before do
    stub_request(:any, /https\:\/\/s3\.amazonaws\.com\/vhlcentral\.activities\/.*\.xml/).
      to_return(status: 200, body: "", headers: {})

    allow(Radner::S3Storage).to receive(:new).and_return(s3)
    allow(Maestro::LicenseGroup).to receive(:all).and_return([])
    allow(lesson).to receive(:strand_for_toc_location).with(toc_entry.id).and_return(toc_entry)
    allow(AssignmentValidator).to receive(:new).and_return(activity_validator)
  end

  describe '#update_session_due_date_and_category' do
    context 'when params do not contain activity assignment values' do
      it 'returns an empty hash' do
        params.delete(:activity_assignment)
        expect(AssignmentUpdateProcessor.new(
          params, instructor, focus
        ).update_session_due_date_and_category).to eq({})
      end
    end

    context 'when params contain activity assignment values' do
      context 'when params contain both due date and category id values' do
        it 'returns a hash with the complete insformation' do
          expected_result = { due_date: params[:activity_assignment][:due_date],
                              category_id: params[:activity_assignment][:category_id] }
          expect(AssignmentUpdateProcessor.new(
            params, instructor, focus
          ).update_session_due_date_and_category).to eq(expected_result)
        end
      end

      context 'when params contain due date value only' do
        it 'returns a hash with the due date value' do
          params[:activity_assignment].delete(:category_id)
          expected_result = { due_date: params[:activity_assignment][:due_date] }
          expect(AssignmentUpdateProcessor.new(
            params, instructor, focus
          ).update_session_due_date_and_category).to eq(expected_result)
        end
      end

      context 'when params contain category value only' do
        it 'returns a hash with the category value' do
          params[:activity_assignment].delete(:due_date)
          expected_result = { category_id: params[:activity_assignment][:category_id] }
          expect(AssignmentUpdateProcessor.new(
            params, instructor, focus
          ).update_session_due_date_and_category).to eq(expected_result)
        end
      end
    end
  end

  describe '#flash_notice_msg' do
    subject(:processor) { described_class.new(processor_params, instructor, focus) }

    context 'when the section is not enterprise' do
      context 'when assigning' do
        let(:processor_params) { params }

        it 'returns the correct message' do
          processor.process
          expect(processor.flash_notice_msg).to eq('Activity assigned successfully.')
        end
      end

      context 'when unassigning' do
        let(:processor_params) { unassign_params }

        before do
          create(:assignment, assignable: activity_1, due_date: due_date.to_date, section:)
        end

        it 'returns the correct message' do
          processor.process
          expect(processor.flash_notice_msg).to eq('Activity unassigned successfully.')
        end
      end
    end

    context 'when the section is enterprise' do
      let(:course) { create(:enterprise_course) }
      let(:section) { create(:enterprise_section, course:) }

      context 'when assigning' do
        let(:processor_params) { params }

        it 'returns the correct message' do
          expect(processor.flash_notice_msg)
            .to eq('Assignments added successfully. Sections will update shortly.')
        end
      end

      context 'when unassigning' do
        let(:processor_params) { unassign_params }

        it 'returns the correct message' do
          expect(processor.flash_notice_msg)
            .to eq('Assignments removed successfully. Sections will update shortly.')
        end
      end
    end
  end

  describe '#process' do
    let(:invalid_assignment) do
      ActivityAssignment.new(
        activity_1, instructor, program, { course_id: course.id }
      )
    end

    context 'when a custom time has been set' do
      it 'sets the current time for the assignment' do
        really_early_assignment_params = params.merge(
          {
            due_time_hour: '04',
            due_time_min: '30',
            due_time_ampm: 'AM'
          }
        )
        processor = AssignmentUpdateProcessor.new(really_early_assignment_params, instructor, focus)
        processor.process
        expect(
          Assignment.by_assignable_id(activity_1.id).first.custom_due_time.to_s
        ).to include '04:30:00'
      end
    end

    context 'when validating activity licenses' do
      it 'validates selected activities' do
        expect(activity_validator).to receive(:validate)
        processor.process
      end

      it 'keeps track of license-related invalid assignments' do
        allow(activity_validator).to receive(:valid_activities).and_return([])
        allow(activity_validator)
          .to receive(:invalid_activity_assignments)
          .and_return([invalid_assignment])
        processor.process
        expect(processor.failure).to include invalid_assignment
      end
    end

    context 'when unassigning' do
      subject(:processor) { described_class.new(unassign_params, instructor, focus) }

      before do
        create(:assignment, assignable: activity_1, due_date: due_date.to_date, section:)
        allow(Enterprise::UnassignActivityWorker).to receive(:perform_async)
      end

      context 'when the section is not enterprise' do
        it 'unassigns the activity' do
          expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
          processor.process
          expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
          expect(processor.success.sample.activity).to eq(activity_1)
        end

        it 'does not schedule a job' do
          processor.process
          expect(Enterprise::UnassignActivityWorker).not_to have_received(:perform_async)
        end
      end

      context 'when the section is enterprise' do
        let(:course) { create(:enterprise_course) }
        let(:section) { create(:enterprise_section, course:) }

        context 'when instructor is institution_admin' do
          let(:instructor) { create(:institution_admin) }

          context 'when in institution_admin_context' do
            let(:processor_params) { ActionController::Parameters.new(unassign_params) }
            subject(:processor) { described_class.new(processor_params, instructor, focus, institution_admin_context: true) }

            it 'unassigns the activity' do
              expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
              processor.process
              expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
              expect(processor.success.sample.activity).to eq(activity_1)
            end

            it 'schedules a job' do
              processor.process
              expect(Enterprise::UnassignActivityWorker).to have_received(:perform_async)
            end
          end

          context 'when NOT in institution_admin_context' do
            let(:processor_params) { ActionController::Parameters.new(unassign_params) }
            subject(:processor) { described_class.new(processor_params, instructor, focus, institution_admin_context: false) }

            it 'unassigns the activity' do
              expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
              processor.process
              expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
              expect(processor.success.sample.activity).to eq(activity_1)
            end

            it 'does not schedule a job' do
              processor.process
              expect(Enterprise::UnassignActivityWorker).not_to have_received(:perform_async)
            end
          end
        end

        context 'when instructor is not institution_admin' do
          let(:instructor) { create(:instructor) }

          it 'unassigns the activity' do
            expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
            processor.process
            expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
            expect(processor.success.sample.activity).to eq(activity_1)
          end

          it 'does not schedule a job' do
            processor.process
            expect(Enterprise::UnassignActivityWorker).not_to have_received(:perform_async)
          end
        end
      end
    end

    context 'when assignning' do
      subject(:processor) { described_class.new(processor_params, instructor, focus) }

      let(:processor_params) { ActionController::Parameters.new(params) }

      before do
        allow(Enterprise::AssignActivityWorker).to receive(:perform_async)
      end

      context 'when the section is not enterprise' do
        it 'creates an assignment' do
          expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
          processor.process
          expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
          expect(processor.success.sample.activity).to eq(activity_1)
        end

        it 'does not schedule a job' do
          processor.process
          expect(Enterprise::AssignActivityWorker).not_to have_received(:perform_async)
        end
      end

      context 'when the section is enterprise' do
        let(:course) { create(:enterprise_course) }
        let(:section) { create(:enterprise_section, course:) }

        context 'when instructor is institution_admin' do
          let(:instructor) { create(:institution_admin) }

          context 'when in institution_admin_context' do
            let(:processor_params) { ActionController::Parameters.new(params) }
            let(:processor) { AssignmentUpdateProcessor.new(processor_params, instructor, focus, institution_admin_context: true) }

            it 'creates an assignment' do
              expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
              processor.process
              expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
              expect(processor.success.sample.activity).to eq(activity_1)
            end

            it 'schedules a job' do
              processor.process
              expect(Enterprise::AssignActivityWorker).to have_received(:perform_async)
            end
          end

          context 'when NOT in institution_admin_context' do
            let(:processor_params) { ActionController::Parameters.new(params) }
            let(:processor) { AssignmentUpdateProcessor.new(processor_params, instructor, focus, institution_admin_context: false) }

            it 'creates an assignment' do
              expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
              processor.process
              expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
              expect(processor.success.sample.activity).to eq(activity_1)
            end

            it 'does not schedule a job' do
              processor.process
              expect(Enterprise::AssignActivityWorker).not_to have_received(:perform_async)
            end
          end
        end

        context 'when instructor is not institution_admin' do
          let(:instructor) { create(:instructor) }

          it 'creates an assignment' do
            expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
            processor.process
            expect(Assignment.by_assignable_id(activity_1.id)).not_to be_empty
            expect(processor.success.sample.activity).to eq(activity_1)
          end

          it 'does not schedule a job' do
            processor.process
            expect(Enterprise::AssignActivityWorker).not_to have_received(:perform_async)
          end
        end
      end

      context 'when process fails' do
        it 'does not create an assignment' do
          allow(invalid_assignment).to receive(:assign_or_update).and_return(false)
          allow(ActivityAssignment).to receive(:new).and_return(invalid_assignment)
          processor.process
          expect(Assignment.by_assignable_id(activity_1.id)).to be_empty
          expect(processor.failure).to include invalid_assignment
        end
      end
    end
  end

  describe '#toc_location' do
    it "returns activity's toc_location" do
      expect(processor.toc_location).to eq(toc_entry.id)
    end
  end

  describe '#display_rank_modal?' do
    let(:validator) do
      instance_double(
        AssignmentUpdateProcessor::ActivityTypeOfContentValidator,
        selected_activities_have_both_types?: false,
        selected_and_assigned_activity_types_differ?: false
      )
    end

    before do
      allow(AssignmentUpdateProcessor::ActivityTypeOfContentValidator)
        .to receive(:new).and_return(validator)
    end

    it 'is false when unassigning activities' do
      assign_update_proc = AssignmentUpdateProcessor.new(unassign_params, instructor, focus)
      expect(assign_update_proc.display_rank_modal?).to be_falsey
    end

    context 'when not assigned nor selected activies are of different types' do
      it 'is false' do
        expect(processor.display_rank_modal?).to be_falsey
      end
    end

    context 'when selected activities are both internal and instructor created' do
      it 'is true' do
        allow(validator).to receive(:selected_activities_have_both_types?).and_return(true)
        expect(processor.display_rank_modal?).to be_truthy
      end
    end

    context 'when selected and assigned activities have both types' do
      it 'is true' do
        allow(validator)
          .to receive(:selected_and_assigned_activity_types_differ?)
          .and_return(true)
        expect(processor.display_rank_modal?).to be_truthy
      end
    end
  end

  def create_instructor_created_activity(args)
    activity = build(:instructor_created_activity_with_non_db_attrs, args)
    activity.extend(ActivityXmlContentHelper)
    activity.save
    activity
  end

  describe '#get_assignment_context_params' do
    context 'when focus is not present' do
      let(:focus) { nil }

      it 'raises an error' do
        expect { processor.send(:get_assignment_context_params) }
          .to raise_error('No focus defined')
      end
    end

    context 'when focus course does not have a program' do
      let(:course) { build(:course, program: nil) }
      let(:focus) { double(Focus, section: section, course: course, sections: [section]) }

      it 'raises an error' do
        expect { processor.send(:get_assignment_context_params) }
          .to raise_error('No program-specific focus in session ')
      end
    end

    context 'when course is enterprise' do
      let(:course) { create(:enterprise_course, program: program) }
      let(:enterprise_section) { create(:enterprise_section, course: course) }
      let(:regular_section) { create(:section, course: course) }
      let(:focus) { double(Focus, section: regular_section, course: course, sections: [regular_section]) }

      before do
        allow(course).to receive(:enterprise_section).and_return(enterprise_section)
      end

      context 'when instructor is institution_admin' do
        let(:instructor) { create(:institution_admin) }

        context 'when in institution_admin_context' do
          let(:processor_params) { ActionController::Parameters.new(params) }
          let(:processor) { AssignmentUpdateProcessor.new(processor_params, instructor, focus, institution_admin_context: true) }

          it 'returns section_id for enterprise_section' do
            result = processor.send(:get_assignment_context_params)
            expect(result).to eq({ section_id: enterprise_section.id })
          end

          it 'prioritizes enterprise section over focus.sections.size logic' do
            allow(focus).to receive(:sections).and_return([regular_section, create(:section)])

            result = processor.send(:get_assignment_context_params)
            expect(result).to eq({ section_id: enterprise_section.id })
          end
        end

        context 'when NOT in institution_admin_context' do
          let(:processor_params) { ActionController::Parameters.new(params) }
          let(:processor) { AssignmentUpdateProcessor.new(processor_params, instructor, focus, institution_admin_context: false) }

          it 'returns section_id for the focused section' do
            result = processor.send(:get_assignment_context_params)
            expect(result).to eq({ section_id: focus.section.id })
          end

          it 'uses focused section even when enterprise_section exists' do
            result = processor.send(:get_assignment_context_params)
            expect(result).to eq({ section_id: focus.section.id })
            expect(result[:section_id]).not_to eq(enterprise_section.id)
          end
        end
      end

      context 'when instructor is not institution_admin' do
        let(:instructor) { create(:instructor) }

        it 'returns section_id for the focused section' do
          result = processor.send(:get_assignment_context_params)
          expect(result).to eq({ section_id: regular_section.id })
        end

        it 'uses focused section even when enterprise_section exists' do
          result = processor.send(:get_assignment_context_params)
          expect(result).to eq({ section_id: regular_section.id })
          expect(result[:section_id]).not_to eq(enterprise_section.id)
        end
      end
    end

    context 'when course is not enterprise' do
      context 'when focus has only one section' do
        let(:focus) { double(Focus, section: section, course: course, sections: [section]) }

        it 'returns section_id for the focused section' do
          result = processor.send(:get_assignment_context_params)
          expect(result).to eq({ section_id: section.id })
        end
      end

      context 'when focus has multiple sections' do
        let(:section_2) { create(:section, course: course) }
        let(:focus) { double(Focus, section: section, course: course, sections: [section, section_2]) }

        it 'returns course_id' do
          result = processor.send(:get_assignment_context_params)
          expect(result).to eq({ course_id: course.id })
        end
      end
    end
  end

  describe AssignmentUpdateProcessor::ActivityTypeOfContentValidator do
    let(:instructor_activity) do
      create_instructor_created_activity(
        lesson: lesson, toc_location: toc_entry.id
      )
    end

    let(:activity_2) { create(:activity, toc_location: toc_entry.id) }

    before do
      @recycle_bin << instructor_activity.content_filepath
    end

    describe '#selected_activities_have_both_types?' do
      context 'when selected activities have both internal and instructor created activies' do
        it 'is true' do
          selected_activities = [activity_1, instructor_activity]
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities, []
            )
          expect(validator.selected_activities_have_both_types?).to be_truthy
        end
      end

      context 'when selected activities have only one type of activity' do
        it 'is false' do
          selected_activities = [activity_1, activity_2]
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities, []
            )
          expect(validator.selected_activities_have_both_types?).to be_falsey
        end
      end
    end

    describe '#selected_and_assigned_activity_types_differ?' do
      let(:instructor_activity_2) { create_instructor_created_activity(lesson: lesson, toc_location: toc_entry.id) }

      before do
        @recycle_bin << instructor_activity_2.content_filepath
      end

      context 'when assigned and selected activities are internal activities' do
        it 'is false' do
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities = [activity_1],
              assigned_activities = [activity_2]
            )
          expect(validator.selected_and_assigned_activity_types_differ?).to be_falsey
        end
      end

      context 'when assigned and selected activities are instructor activities' do
        it 'is false' do
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities = [instructor_activity],
              assigned_activities = [instructor_activity_2]
            )
          expect(validator.selected_and_assigned_activity_types_differ?).to be_falsey
        end
      end

      context 'when assigned activities are both internal and instructor created and selected activities are of one type' do
        it 'is true' do
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities = [instructor_activity],
              assigned_activities = [activity_1, instructor_activity_2]
            )
          expect(validator.selected_and_assigned_activity_types_differ?).to be_truthy
        end
      end

      context 'when assigned activities are of one type and selected activities are both internal and instructor created' do
        it 'is true' do
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities = [instructor_activity, activity_1],
              assigned_activities = [instructor_activity_2]
            )
          expect(validator.selected_and_assigned_activity_types_differ?).to be_truthy
        end
      end

      context 'when both assigned and selected activities are are both internal and instructor created' do
        it 'is true' do
          validator =
            AssignmentUpdateProcessor::ActivityTypeOfContentValidator.new(
              selected_activities = [instructor_activity, activity_1],
              assigned_activities = [activity_2, instructor_activity_2]
            )
          expect(validator.selected_and_assigned_activity_types_differ?).to be_truthy
        end
      end
    end
  end
end
