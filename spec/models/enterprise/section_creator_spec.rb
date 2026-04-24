require 'rspec/expectations'

RSpec::Matchers.define :array_of_class do |klass|
  match do |actual|
    actual.all? { |item| item.is_a? klass }
  end
end

describe Enterprise::SectionCreator, new_gb_sync: true do
  # The SectionTemplateSectionCreator should
  # * accept data for 1+ sections to be created for a template-based course
  # * for each section,
  #   * create the section
  #   * set its name to the given name
  #   * set its source template ID to the given ID
  #   * map categories from the course template to the categories for the course
  #   * for each assignment in the section template,
  #     * copy the assignment
  #     * copy the group chat assignment config
  #     * assign it to the new section
  #     * set the category based on the category mapping

  # course is a course based on a template
  let(:course_owner) { create(:instructor) }
  let(:program) { create(:program) }
  let(:enterprise_course) do
    create(:enterprise_course, program:, owner: course_owner, enterprise_section: create(:enterprise_section))
  end

  let(:template_category_1) do
    create(:category, course: enterprise_course, name: 'Pride', weighting_percent: 40)
  end

  let(:template_category_2) do
    create(:category, course: enterprise_course, name: 'Prejudice', weighting_percent: 40)
  end

  let(:template_category_3) do
    create(:category, course: enterprise_course, name: 'Sense', weighting_percent: 20)
  end

  let(:enterprise_section) { enterprise_course.enterprise_section }
  let(:course_name) { 'Courses! Foiled again.' }
  let(:last_course) { Course.last }

  let(:coinstructor) { create(:instructor) }
  let(:assistant) { create(:instructor) }

  let(:section_name) { 'Seccion uno' }
  let(:due_time) { '17:00' }
  let(:time_zone) { 'UTC' }

  let(:params) do
    {
      course_id: enterprise_course.id,
      name: section_name,
      hide_owner_name: false,
      days_to_show_assignment_due_date: 7,
      due_time:,
      time_zone:,
      additional_instructors: [
        { instructor_id: coinstructor.id,
          role: 'Co-instructor' },
        { instructor_id: assistant.id,
          role: 'Assistant' }
      ]
    }
  end

  let!(:lesson) { create(:lesson, label: 'This needs a label so I am giving it one') }
  let(:concept) { create(:concept, lesson:) }
  let(:activity_1) do
    create(:activity, concept:, lesson:, title: 'the first activity')
  end
  let(:activity_2) do
    create(:activity, concept:, lesson:, title: 'the second activity')
  end
  let(:activity_3) do
    create(:activity, concept:, lesson:, title: 'activity for before course start')
  end
  let(:activity_4) do
    create(:activity, concept:, lesson:, title: 'activity for after course end')
  end
  let(:activity_5) do
    create(:activity, concept:, lesson:, title: 'activity for old category name')
  end
  let(:gb_external_activity_1) { create(:gb_external_activity, name: 'gb external activity 1') }
  let(:gb_external_activity_2) { create(:gb_external_activity, name: 'gb external activity 2') }
  let(:gb_external_activity_3) do
    create(:gb_external_activity, name: 'gb external activity for before course start')
  end
  let(:gb_external_activity_4) do
    create(:gb_external_activity, name: 'gb external activity for after course end')
  end
  let(:gb_external_activity_5) do
    create(:gb_external_activity, name: 'gb external activity for old category name')
  end

  let(:template_assignment_1) do
    create(:assignment, assignable: activity_1, section: enterprise_section,
           category: template_category_1)
  end

  let(:gb_template_assignment_1) do
    create(:gb_external_assignment, external_activity_id: gb_external_activity_1.id,
           lesson_id: lesson.id, section_id: enterprise_section.id, category_id: template_category_1.id)
  end

  let(:template_assignment_too_early) do
    create(:assignment,
           assignable: activity_3,
           due_date: enterprise_course.start_date,
           section: enterprise_section,
           category: template_category_1)
  end

  let(:gb_template_assignment_too_early) do
    create(:gb_external_assignment,
           external_activity_id: gb_external_activity_3.id,
           day_id: enterprise_course.start_date,
           lesson_id: lesson.id,
           section_id: enterprise_section.id,
           category_id: template_category_1.id)
  end

  let(:template_assignment_too_late) do
    create(:assignment,
           assignable: activity_4,
           due_date: enterprise_course.end_date,
           section: enterprise_section,
           category: template_category_1)
  end

  let(:gb_template_assignment_too_late) do
    create(:gb_external_assignment,
           external_activity_id: gb_external_activity_4.id,
           day_id: enterprise_course.end_date,
           lesson_id: lesson.id,
           section_id: enterprise_section.id,
           category_id: template_category_1.id)
  end

  let(:template_assignment_old_category_name) do
    create(:assignment,
           assignable: activity_5,
           due_date: enterprise_course.start_date + 7.days,
           section: enterprise_section,
           category: template_category_3)
  end

  let(:gb_template_assignment_old_category_name) do
    create(:gb_external_assignment,
           external_activity_id: gb_external_activity_5.id,
           day_id: enterprise_course.start_date + 7.days,
           lesson_id: lesson.id,
           section_id: enterprise_section.id,
           category_id: template_category_3.id)
  end

  let(:assessment_activity_1) do
    create(:activity, concept:, lesson:, title: 'assessment activity 1')
  end

  let(:assessment_activity_2) do
    create(:activity, concept:, lesson:, title: 'assessment activity 2')
  end

  let(:gchat_activity_1) do
    create(
      :activity,
      concept:,
      lesson:,
      title: 'group chat activity 1',
      activity_type: 'group_chat'
    )
  end

  let(:template_assessment_assignment_1) do
    create(:assignment,
           assignable: assessment_activity_1,
           due_date: enterprise_course.start_date + 7.days,
           section: enterprise_section,
           category: template_category_1)
  end

  let(:template_assessment_assignment_2) do
    create(:assignment,
           assignable: assessment_activity_2,
           due_date: enterprise_course.start_date + 7.days,
           section: enterprise_section,
           category: template_category_1)
  end

  let(:gchat_assignment_1) do
    create(
      :assignment,
      assignable: gchat_activity_1,
      due_date: enterprise_course.start_date + 7.days,
      section: enterprise_section,
      category: template_category_1
    )
  end

  let(:assessment_detail_1) do
    create(:assigned_assessment_detail,
           assignment: template_assessment_assignment_1,
           number_of_attempts: 1,
           password: 'super duper secret',
           time_limit: 45)
  end

  let(:assessment_detail_2) do
    create(:assigned_assessment_detail,
           assignment: template_assessment_assignment_2,
           number_of_attempts: 3,
           password: 'swordfish',
           time_limit: 0)
  end

  let(:group_chat_assignment_config_1) do
    create(
      :group_chat_assignment_config,
      assignment: gchat_assignment_1,
      group_minimum: 2,
      group_maximum: 5
    )
  end

  before do
    # Call necessary objects into existence.
    allow_any_instance_of(GradebookEngine::Assignment).to(
      receive(:section).and_return(enterprise_section)
    )
    allow_any_instance_of(Assignment).to(
      receive(:section).and_return(enterprise_section)
    )
    enterprise_course
    template_category_1
    template_category_2
    template_category_3
    template_assignment_1
    gb_template_assignment_1

    # This will create the template assessment assignments
    assessment_detail_1
    assessment_detail_2

    # Create group chat assignment config
    group_chat_assignment_config_1
  end

  describe('#initialize') do
    let(:section_creator) { described_class.new(params, enterprise_course) }
    let(:non_enterprise_course) { create(:course, is_enterprise: false) }

    it 'raises an error if the course is not based on a template' do
      expect do
        described_class.new(params.merge(course_id: non_enterprise_course.id), non_enterprise_course)
      end.to raise_error(
               ArgumentError,
               "Course id=#{non_enterprise_course.id} must be from enterprise and have an enterprise section."
             )
    end

    it 'raises an error if the course has not enterprise section' do
      no_section_course = create(:course, is_enterprise: true, enterprise_section: nil)
      expect do
        described_class.new(params.merge(course_id: no_section_course.id), no_section_course)
      end.to raise_error(
               ArgumentError,
               "Course id=#{no_section_course.id} must be from enterprise and have an enterprise section."
             )
    end
  end

  describe '#create_section' do
    before do
      allow(Assignment).to receive(:import).and_call_original
      allow(GradebookEngine::ExternalAssignment).to receive(:import).and_call_original
      allow(InstitutionAdminGradebookAssignmentSyncWorker).to receive(:perform_async)
    end

    describe 'associated sections' do
      before do
        described_class.new(params, enterprise_course).create_section
      end

      it 'creates associated section' do
        expect(last_course.sections.map(&:name)).to match_array(
                                                      [section_name]
                                                    )
      end

      it 'creates the section marked as not enterprise' do
        expect(last_course.sections.map(&:is_enterprise)).to match_array(
                                                               [false]
                                                             )
      end

      it 'associates the sections with the course owner' do
        expect(course_owner.sections.map(&:name)).to match_array(
                                                       [section_name]
                                                     )
      end

      it 'raises an error if an invalid time zone is provided' do
        invalid_params = params.merge(time_zone: 'InvalidZone')

        expect { described_class.new(invalid_params, enterprise_course).create_section }.to raise_error(
                                                                                              ActiveRecord::RecordInvalid,
                                                                                              /Time zone must be a valid time zone/
                                                                                            )
      end

      it 'sets time settings correctly using dup_time_settings' do
        new_section = Section.find_by(name: section_name)
        expected_time = Time.zone.parse(params[:due_time]).strftime('%H:%M')

        expect(new_section.days_to_show_assignment_due_date).to eq(params[:days_to_show_assignment_due_date])
        expect(new_section.due_time.strftime('%H:%M')).to eq(expected_time)
        expect(new_section.time_zone).to eq(params[:time_zone])
      end

      it 'adds the course owner as instructor' do
        sections = Section.where(
          name: [section_name]
        )
        section_instructors = SectionInstructor.where(section: sections,
                                                      user_id: course_owner.id)
        roles = section_instructors.map(&:role).uniq
        expect(roles).to eq(['Instructor'])
      end

      it 'adds expected additional instructors' do
        section_3 = Section.where(name: section_name).first
        additional_instructors_data = section_3.additional_instructors.map do |i|
          { id: i.user_id,
            role: i.role }
        end

        expect(additional_instructors_data).to match_array(
                                                 [{ id: coinstructor.id, role: 'Co-instructor' },
                                                  { id: assistant.id, role: 'Assistant' }]
                                               )
      end

      it 'records the source section template to the enterprise section' do
        source_template_ids = [Section.find_by(name: section_name)].map(&:source_template_id)
        expect(source_template_ids).to eq(
                                         [enterprise_course.enterprise_section.id]
                                       )
      end

      it 'updates the hide from dashboard flag on the seciton instructor record' do
        sections = Section.where(name: section_name)
        section_instructors = SectionInstructor.where(section: sections,
                                                      user_id: course_owner.id)
        hide_status = section_instructors.map(&:hide_from_instructor_dashboard)
        expect(hide_status).to eq([enterprise_course.hide_from_instructor_dashboard])
      end

      describe 'associated assignments' do
        it 'copies the template assignments to the new section' do
          created_section = Section.find_by(name: section_name)

          copied_activity_ids = created_section.assignments.map(&:assignable_id)
          expected_activity_ids = [activity_1.id, assessment_activity_1.id,
                                   assessment_activity_2.id, gchat_activity_1.id]

          expect(copied_activity_ids).to match_array(expected_activity_ids)
        end

        it 'copies the gradebook template external assignments to the new gradebook section' do
          created_section = Section.find_by(name: section_name)
          gb_section = GradebookEngine::Section.find_by(name: created_section.name)

          expect(gb_section.external_assignments.count).to eq(1)
          expect(gb_section.external_assignments.first.external_activity.name).to eq(gb_external_activity_1.name)
        end

        it 'correctly maps categories to categories for the new course' do
          created_section = Section.find_by(name: section_name)

          copied_category_ids = created_section.assignments.map(&:category_id)

          template_category_1_copy = Category.find_by(course: last_course,
                                                      name: template_category_1.name)

          expect(copied_category_ids).to all(eq(template_category_1_copy.id))
        end

        it 'bulk-imports assignments without validations' do
          # Assignments should be copied for created section.
          # Arguments to :import are:
          #   1. an array of column names as symbols
          #   2. an array of scalar values for the database record
          #   3. a :validate option set to false
          expect(Assignment).to have_received(:import)
                                  .exactly(1).times
                                  .with(array_of_class(Symbol), instance_of(Array), { validate: false })

          expect(GradebookEngine::ExternalAssignment).to have_received(:import)
                                                           .exactly(1).times
                                                           .with(array_of_class(Symbol), instance_of(Array), { validate: false })
        end

        it 'calls a Sidekiq worker to sync assignments to the gradebook db' do
          [Section.find_by(name: section_name)].map(&:id).each do |id|
            expect(InstitutionAdminGradebookAssignmentSyncWorker)
              .to have_received(:perform_async).with(id)
          end
        end

        it 'copies assigned assessment details' do
          assessment_assignments = Section.find_by(name: section_name).assignments.select do |a|
            a.assignable.title.include? 'assessment activity'
          end

          assessment_details = AssignedAssessmentDetail
                                 .where(
                                   assignment_id: assessment_assignments.map(&:id)
                                 ).map do |detail|
            [detail.number_of_attempts,
             detail.password,
             detail.time_limit]
          end

          expect(assessment_details).to eq(
                                          [[1, 'super duper secret', 45], [3, 'swordfish', 0]]
                                        )
        end

        it 'copies group chat assignment configs' do
          new_gchat_assignment = Section.find_by(name: section_name).assignments.where(assignable_id: gchat_activity_1)[0]

          expect(
            GroupChatAssignmentConfig.where(
              assignment_id: new_gchat_assignment.id,
              group_minimum: 2,
              group_maximum: 5
            )
          ).to exist
        end
      end
    end

    describe 'if course settings change' do
      it 'does not copy assignments that conflict with course settings' do
        # create template assignments that will conflict
        template_assignment_too_early
        template_assignment_too_late
        template_assignment_old_category_name
        gb_template_assignment_too_early
        gb_template_assignment_too_late
        gb_template_assignment_old_category_name

        # shorten course range
        enterprise_course.start_date = enterprise_course.start_date + 1.day
        enterprise_course.end_date = enterprise_course.end_date - 1.day
        enterprise_course.save!

        # change category name
        category_to_change = Category.where(course: enterprise_course, name: 'Sense').first
        category_to_change.name = 'Sensibility'
        category_to_change.save!

        allow(Assignment).to receive(:import).and_call_original
        allow(InstitutionAdminGradebookAssignmentSyncWorker).to receive(:perform_async)
        described_class.new(params, enterprise_course).create_section

        section_1_activity_ids = Section.find_by(name: section_name).assignments.map(&:assignable_id)

        # Sections 1 and 2 should have the activity for the first section template.
        expect(section_1_activity_ids)
          .to eq([
                   activity_1.id,
                   assessment_activity_1.id,
                   assessment_activity_2.id,
                   gchat_activity_1.id,
                   activity_5.id
                 ])
      end

      it 'returns an uncopied-assignments value of true if assignments conflict' do
        # create template assignments that will conflict
        template_assignment_too_early

        # shorten course range
        enterprise_course.start_date = enterprise_course.start_date + 1.day
        enterprise_course.save!

        allow(Assignment).to receive(:import).and_call_original
        allow(InstitutionAdminGradebookAssignmentSyncWorker).to receive(:perform_async)
        result = described_class.new(params, enterprise_course).create_section

        expect(result[:uncopied_assignments]).to be true
      end

      it 'returns an uncopied-assignments value of true if external assignments conflict' do
        # create template assignments that will conflict
        gb_template_assignment_too_early

        # shorten course range
        enterprise_course.start_date = enterprise_course.start_date + 1.day
        enterprise_course.save!

        allow(Assignment).to receive(:import).and_call_original
        allow(InstitutionAdminGradebookAssignmentSyncWorker).to receive(:perform_async)
        result = described_class.new(params, enterprise_course).create_section

        expect(result[:uncopied_assignments]).to be true
      end

      it 'returns an uncopied-assignments value of false if no assignments conflict' do
        # shorten course range
        enterprise_course.start_date = enterprise_course.start_date + 1.day
        enterprise_course.save!

        allow(Assignment).to receive(:import).and_call_original
        allow(InstitutionAdminGradebookAssignmentSyncWorker).to receive(:perform_async)
        result = described_class.new(params, enterprise_course).create_section

        expect(result[:uncopied_assignments]).to be false
      end
    end
  end
end
