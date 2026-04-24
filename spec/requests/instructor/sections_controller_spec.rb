require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::SectionsController do
  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }

  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      school: school
    )
  end

  let(:previous_course) do
    create(
      :course,
      owner: instructor,
      program: program,
      school: school
    )
  end
  let(:previous_course_category) { create(:category, course: previous_course) }

  let(:roles) { SectionInstructor::INSTRUCTOR_ROLES }
  let(:teammate_1) { create(:instructor) }
  let(:teammate_2) { create(:instructor) }
  let(:teammate_3) { create(:instructor) }
  let(:previous_section) { create(:section, course: previous_course) }

  let(:section_instructors_attrs) do
    [
      {
        allowed_to_edit_content: true,
        role: roles[:co_instructor],
        user_id: teammate_1.id
      },
      {
        allowed_to_edit_content: false,
        role: roles[:assistant],
        user_id: teammate_2.id
      }
    ]
  end

  let(:original_attrs) do
    {
      additional_info: 'original addtl info',
      class_days: '1,2,3',
      days_to_show_assignment_due_date: 3,
      due_time: '11:00PM',
      hide_owner_name: false,
      name: 'original section name',
      open_to_students: false,
      time_zone: 'Pacific Time (US & Canada)'
    }
  end

  let(:non_attr_params) do
    {
      assignment_copy_section_id: previous_section.id,
      copy_external_assignments: false,
      section_instructors_attributes: section_instructors_attrs
    }
  end

  let(:create_params) do
    { section: original_attrs.merge(non_attr_params), format: :json }
  end

  # See https://github.com/rspec/rspec-rails/issues/610
  # Without explicitly converting the params to JSON, for create action,
  # a value of false for the non-attribute parameter copy_external_assignments
  # gets turned into the string "false", which evaluates to true.
  # After Rails 5 upgrade, it should be possible to simplify this to either:
  # post(target_path, params: params_hash, as: :json)
  # or
  # post(target_path, params: params_hash.merge(as: :json))
  def do_post_with_json_params(params_hash)
    post(
      target_path,
      params: JSON.dump(params_hash),
      headers: { 'CONTENT_TYPE' => 'application/json' }
    )
  end

  def expect_error(key, message)
    section_errors = JSON.parse(response.body)['errors']['section']
    errors = (key == 'base' ? section_errors : section_errors[key])
    expect(errors).to match_array [message]
  end

  before do
    allow(Maestro::School).to receive(:instructors).and_return(
      Maestro::School.new(
        'instructor_ids' => [teammate_1.id, teammate_2.id, teammate_3.id]
      )
    )
  end

  describe 'POST /create' do
    let(:target_path) do
      instructor_course_sections_path(
        course_id: course.id,
        program_id: program.id
      )
    end

    def do_request
      do_post_with_json_params(create_params)
    end

    include_examples 'require instructor with program access', :json

    context 'with a valid user,', new_gb_sync: true do
      before do
        lesson = create(:lesson)
        create(
          :gb_external_assignment,
          category_id: previous_course_category.id,
          lesson_id: lesson.id,
          section_id: previous_section.id
        )
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :section in the params' do
        expect { post(target_path, params: { format: :json }) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: section/
        )
      end

      it 'renders validation errors as JSON when invalid params are specified' do
        do_post_with_json_params(
          create_params.deep_merge(section: { name: '' })
        )

        expect_error('name', 'is required')
        expect(response).to be_unprocessable
      end

      it 'creates a new section record when valid params are specified' do
        do_request

        # for debugging validation errors
        puts JSON.parse(response.body).inspect if response.unprocessable?

        expect(response).to be_created
        expect(flash[:notice]).to match(/has been created/)

        section = Section.last

        expect(JSON.parse(response.body)).to eq(
          'redirect_to' => instructor_dashboard_url(program_id: program.id)
        )

        # Verify that posted params were permitted and saved.
        expect(section).to have_attributes(original_attrs.except(:due_time))
        expect(section.due_time.strftime('%l:%M%p')).to eq(
          original_attrs[:due_time]
        )

        # Verify non-posted attributes were set in the controller action.
        expect(section).to have_attributes(
          instructor_id: instructor.id,
          course_id: course.id
        )

        # Verify section instructors
        results = section.section_instructors.map do |record|
          [record.allowed_to_edit_content?, record.role, record.user_id]
        end
        expect(results).to match_array [
          [true, roles[:co_instructor], teammate_1.id],
          [false, roles[:assistant], teammate_2.id]
        ]

        # Verify external assignments from previous section are
        # not copied when copy_external_assignments param
        # is specified as false
        expect(
          GradebookEngine::ExternalAssignment.where(section_id: section.id)
        ).not_to exist

        # Verify that the focus is set to the course of the new created section.
        expect(session[:focus][program.id.to_s]['course_id']).to eq(course.id)
      end

      it 'copies external assignemnts from previous section if ' \
         'copy_external_assignments is specified as true', new_gb_sync: true do
        do_post_with_json_params(
          create_params.deep_merge(
            section: { copy_external_assignments: true }
          )
        )

        section = Section.last

        expect(
          GradebookEngine::ExternalAssignment.where(section_id: section.id)
        ).to exist
      end
    end
  end

  describe 'PUT /update' do
    let(:section) do
      create(
        :section,
        original_attrs.merge(
          course: course,
          instructor: instructor,
          section_instructors_attributes: section_instructors_attrs
        )
      )
    end

    let(:new_attrs) do
      {
        additional_info: 'new addtl info',
        class_days: '2,3,4',
        days_to_show_assignment_due_date: 1,
        due_time: '10:00PM',
        hide_owner_name: true,
        name: 'new section name',
        open_to_students: true,
        time_zone: 'Central Time (US & Canada)'
      }
    end

    let(:coinstructor_section_instructor) do
      section.section_instructors.where(user_id: teammate_1.id).first
    end

    let(:assistant_section_instructor) do
      section.section_instructors.where(user_id: teammate_2.id).first
    end

    let(:new_section_instructors_attrs) do
      [
        {
          allowed_to_edit_content: false,
          id: coinstructor_section_instructor.id,
          role: roles[:assistant],
          user_id: teammate_1.id
        },
        {
          allowed_to_edit_content: true,
          id: nil,
          role: roles[:co_instructor],
          user_id: teammate_3.id
        },
        { id: assistant_section_instructor.id, _destroy: true }
      ]
    end

    let(:update_params) do
      {
        section: new_attrs.merge(
          section_instructors_attributes: new_section_instructors_attrs
        ),
        format: :json
      }
    end

    let(:target_path) do
      instructor_course_section_path(
        course_id: course.id,
        id: section.id,
        program_id: program.id
      )
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access', :json

    it 'does not allow updating sections that logged in user does not own' do
      non_owner = create(:instructor)
      log_in_user_with_access_to_programs(non_owner, [program])

      do_request

      expect_error('base', /You must be the owner/)
      expect(response).to be_forbidden
    end

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :section in the params' do
        expect { put(target_path, params: { format: :json }) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: section/
        )
      end

      it 'renders validation errors as JSON when invalid params are specified' do
        put(target_path, params: update_params.deep_merge(section: { name: '' }))

        expect_error('name', 'is required')
        expect(response).to be_unprocessable
      end

      it 'updates the section with the specified id when valid ' \
        'params are specified', new_gb_sync: true do
        do_request

        # for debugging validation errors
        puts JSON.parse(response.body).inspect if response.unprocessable?

        expect(response).to be_ok

        section.reload

        # Verify that posted params were permitted and saved.
        expect(section).to have_attributes(new_attrs.except(:due_time))
        expect(section.due_time.strftime('%l:%M%p')).to eq(
          new_attrs[:due_time]
        )

        # Verify section instructors
        results = section.section_instructors.map do |record|
          [record.allowed_to_edit_content?, record.role, record.user_id]
        end
        expect(results).to match_array [
          [false, roles[:assistant], teammate_1.id],
          [true, roles[:co_instructor], teammate_3.id],
          [true, 'Instructor', instructor.id]
        ]
      end
    end
  end

  describe 'DELETE /destroy' do
    let(:section) do
      create(
        :section,
        original_attrs.merge(
          course: course,
          instructor: instructor,
          section_instructors_attributes: section_instructors_attrs
        )
      )
    end

    let(:coinstructor_section_instructor) do
      section.section_instructors.where(user_id: teammate_1.id).first
    end

    let(:assistant_section_instructor) do
      section.section_instructors.where(user_id: teammate_2.id).first
    end


    let(:target_path) do
      instructor_course_section_path(
        course_id: course.id,
        id: section.id,
        program_id: program.id
      )
    end

    def do_request
      delete(target_path,
             params: {},
             headers: { 'CONTENT_TYPE' => 'application/json' } )
    end

    include_examples 'require program access for instructor'

    context ' with an invalid user' do
      it 'redirects to the login page without a logged in user' do
        do_request
        expect(response).to redirect_to(%r{/login})
      end

      it 'redirects to the default student path ' \
         'when logged-in user is not an instructor' do
        student = create(:student)
        log_in_user_with_access_to_programs(student, [program])
        do_request
        section.reload
        expect(section).not_to be_archived
        expect(response.status).to eq(302)
        expect(response).to redirect_to(
          BestDefaultPath.best_default_path(student, program, nil, {})
        )
      end
    end

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'deletes the section with the specified id when the instructor requests it',
         new_gb_sync: false do
        do_request
        expect(response.status).to eq(302)
        expect(response).to redirect_to(instructor_dashboard_path)
        section.reload
        expect(section).to be_archived
        expect(section.course).not_to be_archived
      end

      it 'deletes the lti linked section and course when the instructor requests it',
         new_gb_sync: false do

        lti_instructor = create(:lti_rostering_instructor)
        create(:lti_rostering_user_link, user: lti_instructor)
        lti_section = create(:section, course: course, instructor: lti_instructor)
        lti_rostering_platform = create(:lti_rostering_platform)
        create(:lti_context_link, section: lti_section)
        log_in_user_with_access_to_programs(lti_instructor, [program])
        delete(
          instructor_course_section_path(
          course_id: course.id,
          id: lti_section.id,
          program_id: program.id
          ),
          params: {},
          headers: { 'CONTENT_TYPE' => 'application/json' })

        expect(response.status).to eq(302)
        expect(response).to redirect_to(instructor_dashboard_path)
        lti_section.reload
        expect(lti_section).to be_archived
        course.reload
        expect(course).to be_archived
      end
     end
   end
end
