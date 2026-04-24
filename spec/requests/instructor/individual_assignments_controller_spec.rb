require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::IndividualAssignmentsController do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }

  let(:course) do
    create(
      :course,
      allow_individual_assign: true,
      owner: instructor,
      program: program
    )
  end

  let!(:section) { create(:section, course: course, instructor: instructor) }

  shared_examples 'assigns section id based on focus' do
    it 'assigns the focused section id when a section is in focus' do
      section_2 = create(:section, course: course)

      put(
        instructor_focus_path(program_id: program.id),
        params: { focus: "Section,#{section_2.id}", return_to: '' }
      )

      do_request

      expect(assigns(:section_id)).to eq(section_2.id)
    end

    it 'assigns the id of the first section in the focused course when ' \
       'no section is in focus' do
      put(
        instructor_focus_path(program_id: program.id),
        params: { focus: "Course,#{course.id}", return_to: '' }
      )

      do_request

      expect(assigns(:section_id)).to eq(section.id)
    end
  end

  shared_examples 'require individual assigning to be enabled' do
    it 'sets a flash error and redirects to the instructor dashboard ' \
       'if individual assigning is disabled for the focused course' do
      course.update!(allow_individual_assign: false)

      put(
        instructor_focus_path(program_id: program.id),
        params: { focus: "Course,#{course.id}", return_to: '' }
      )

      do_request

      expect(flash[:error]).to eq(
        described_class::COURSE_DISABLED_MESSAGE
      )

      expect(response).to redirect_to(instructor_dashboard_path)
    end
  end

  describe 'GET /index' do
    def do_request
      get instructor_individual_assignments_path(program_id: program.id)
    end

    include_examples 'require instructor with program access'
    include_examples 'require instructor with no assistant role'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'require individual assigning to be enabled'
      include_examples 'assigns section id based on focus'

      it 'renders the index view when is focused on the section' do
        create(:active_enrollment, section: section, user: student)
        assignment = create(:assignment, section: section)

        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Section,#{section.id}", return_to: '' }
        )

        do_request

        expect(response).to be_ok

        expect(response).to render_template :index

        user_entries = assigns(:presenter).entries["user_#{student.id}"]

        expect(user_entries.size).to eq(1)

        expect(user_entries.first).to have_attributes(
          assignable_id: assignment.assignable_id,
          section_id: section.id,
          user_id: student.id,
          individually_assigned: false
        )
      end
    end
  end

  describe 'GET /export' do
    let(:unit) { create(:unit, program: program) }
    let(:lesson) { create(:lesson, unit: unit) }
    let(:concept) { create(:concept, lesson: lesson, program: program) }
    let(:due_date) { 5.days.from_now.to_date }

    let(:activity) { create(:activity, concept: concept, lesson: lesson) }

    def do_request
      get export_instructor_individual_assignments_path(
        format: 'csv',
        program_id: program.id
      )
    end

    include_examples 'require instructor with program access'
    include_examples 'require instructor with no assistant role'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
        create(:active_enrollment, section: section, user: student)
        create(
          :assignment,
          assignable: activity,
          due_date: due_date,
          section: section
        )
      end

      include_examples 'require individual assigning to be enabled'
      include_examples 'assigns section id based on focus'

      it 'renders a csv' do
        put(
          instructor_focus_path(program_id: program.id),
          params: { focus: "Course,#{course.id}", return_to: '' }
        )

        do_request

        expect(response).to be_ok

        user_entries = assigns(:presenter).entries["user_#{student.id}"]

        expect(user_entries.size).to eq(1)

        expect(user_entries.first).to have_attributes(
          assignable_id: activity.id,
          section_id: section.id,
          user_id: student.id,
          individually_assigned: false
        )

        csv = response.body
        parsed_data = CSV.parse(csv.encode('windows-1252').encode('utf-8'))

        expect(parsed_data).to eq(
          [
            ['', '', concept.name],
            ['', '', activity.title],
            ['', 'Individually Assignable', 'no'],
            ['Last name', 'First name', due_date.strftime('%-m/%-d/%Y')],
            [student.last_name, student.first_name, 'x']
          ]
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:activity_1) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:other_section) { create(:section) }

    def do_request(params = {})
      put(
        instructor_individual_assignment_path(
          id: activity_1.id, program_id: program.id
        ),
        params: { section_id: section.id }.merge(params)
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'require individual assigning to be enabled'

      it 'updates the individually_assignable state of the assignment ' \
         'with the specified section_id and activity_id to the specified ' \
         'value' do
        target_assignment = create(
          :assignment,
          assignable: activity_1,
          individually_assignable: true,
          section: section
        )

        other_section_assignment = create(
          :assignment,
          assignable: activity_1,
          individually_assignable: true,
          section: other_section
        )

        other_activity_assignment = create(
          :assignment,
          assignable: activity_2,
          individually_assignable: true,
          section: section
        )

        do_request(individually_assignable: false)

        expect(response).to be_ok

        expect(
          target_assignment.reload.individually_assignable
        ).to be_falsey

        expect(
          other_section_assignment.reload.individually_assignable
        ).to be_truthy

        expect(
          other_activity_assignment.reload.individually_assignable
        ).to be_truthy
      end
    end
  end

  describe 'PUT /update_all' do
    def do_request(params = {})
      put(
        update_all_instructor_individual_assignments_path(program_id: program.id),
        params: params
      )
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      include_examples 'require individual assigning to be enabled'
      include_examples 'assigns section id based on focus'

      it 'deletes any individual assignments for the specified activity ids' \
         'where no users are assigned, and creates individual assignments ' \
         'for activities where users are assigned' do
        activity_1 = create(:activity)
        activity_2 = create(:activity)
        IndividualAssignment.create!(
          activity_id: activity_1.id,
          section_id: section.id,
          user_id: student.id
        )

        do_request(
          "activity_#{activity_1.id}[user_#{student.id}]" => { 'assigned' => 0, 'due_date' => nil },
          "activity_#{activity_2.id}[user_#{student.id}]" => { 'assigned' => 1, 'due_date' => nil }
        )

        expect(response).to redirect_to(
          instructor_individual_assignments_path(program_id: program.id)
        )

        expect(flash[:notice]).to eq('Changes saved.')

        expect(IndividualAssignment.where(activity_id: activity_1.id)).to be_empty
        expect(
          IndividualAssignment.where(
            activity_id: activity_2.id,
            section_id: section.id,
            user_id: student.id
          )
        ).not_to be_empty
      end
    end
  end
end
