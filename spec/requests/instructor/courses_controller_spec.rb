require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::CoursesController do
  let(:program) { create(:program_with_lessons) }
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) do
    program.units.first.lessons.first.tap do |lesson|
      lesson.toc_entries = [strand]
      lesson.save!
    end
  end
  let(:concept) do
    create(
      :concept,
      id: strand.location,
      lesson: lesson,
      program: program
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

  let(:instructor_activity) do
    create(
      :instructor_created_activity,
      concept: concept,
      lesson: lesson,
      toc_location: strand.location
    )
  end

  let(:original_course_package_ids) { %w[1 2 3] }

  let(:original_attrs) do
    {
      allow_audio_transcripts: true,
      allow_video_popup_translation: true,
      allows_help_requests: true,
      allows_review_requests: true,
      chat_level: 'original chat level',
      course_package_ids: original_course_package_ids,
      enable_vocab_tutorial_translations: false,
      end_date: 30.days.from_now.to_date,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.first.id,
      level: 'original level',
      name: 'original course name',
      school_id: school.id,
      show_estimated_times: true,
      start_date: 2.days.from_now.to_date,
      video_subtitle_languages: 'original subtitle languages',
      video_transcript_languages: 'original transcript languages'
    }
  end

  let(:original_category_attrs) do
    [
      {
        accept_late_work: false,
        credit_only: false,
        drop_low_scores: 0,
        enhanced_feedback_disabled: false,
        late_work_penalty: 'original late penalty',
        max_attempts: 3,
        name: 'orig cat1 name',
        penalty_percent: 10,
        rank: 1,
        weighting_percent: 60
      },
      {
        accept_late_work: false,
        credit_only: false,
        drop_low_scores: 0,
        enhanced_feedback_disabled: false,
        late_work_penalty: 'original late penalty',
        max_attempts: 3,
        name: 'orig cat2 name',
        penalty_percent: 10,
        rank: 2,
        weighting_percent: 40
      }
    ]
  end

  let(:original_scoring_ruleset_attrs) do
    {
      ignore_accents: false,
      ignore_capitalization: false,
      ignore_punctuation: false
    }
  end

  let(:category_attrs_with_scoring_rulesets) do
    original_category_attrs.map do |attrs|
      attrs.merge(scoring_rulesets_attributes: [original_scoring_ruleset_attrs])
    end
  end

  let(:best_default_path) do
    BestDefaultPath.best_default_path(instructor, program, nil, {})
  end

  let(:non_attr_params) do
    {
      copy_created_activities_from_previous_course: false,
      course_library_from: previous_course.id
    }
  end

  let(:create_params) do
    {
      course: original_attrs.merge(non_attr_params).merge(
        categories_attributes: category_attrs_with_scoring_rulesets,
        end_date: original_attrs[:end_date].to_s,
        start_date: original_attrs[:start_date].to_s
      )
    }
  end

  # See https://github.com/rspec/rspec-rails/issues/610
  # Without explicitly converting the params to JSON, for express_create
  # action, the activity ids in assignments param get converted from integers
  # to strings, breaking logic in BulkGbAssignmentCreator, which tries to
  # look up activities in a hash with integers as keys.
  # For both create and express_create, the value for the non-attribute
  # parameter copy_created_activities_from_previous_course specifed as false
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

  def expect_error(message, key = 'errors')
    expect(JSON.parse(response.body)[key]).to eq([message])
  end

  before do
    allow(Maestro::LicenseGroup).to receive(:all)
      .and_return([Maestro::LicenseGroup.new('name' => '01-Supersite')])
    allow(CourseLicenseCreatorWorker).to receive(:perform_in)
  end

  describe 'POST /create' do
    let(:target_path) { instructor_courses_path(program_id: program.id) }

    def do_request(params = create_params)
      do_post_with_json_params(params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        create(
          :course_library_activity,
          activity: instructor_activity,
          course: previous_course
        )
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :course in the params' do
        expect { post(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: course/
        )
      end

      it 'does not allow creating courses in districts' do
        school.update!(school_type: 'district')

        do_request

        expect(response).to redirect_to best_default_path
      end

      it 'does not allow creating courses by non-clever users in clever schools' do
        school.update!(clever_id: 'abc123')

        do_request

        expect(response).to redirect_to best_default_path
      end

      it 'renders validation errors as JSON when invalid params are specified' do
        do_post_with_json_params(
          create_params.deep_merge(course: { name: '' })
        )

        expect_error('Name is required')
        expect(response).to be_unprocessable

        do_post_with_json_params(
          create_params.deep_merge(course: { categories_attributes: [] })
        )

        expect_error('Course must have at least one category.')
        expect(response).to be_unprocessable

        do_post_with_json_params(
          create_params.deep_merge(course: { categories_attributes: nil })
        )

        expect_error('Course must have at least one category.')
        expect(response).to be_unprocessable

        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Course).to receive(:save).and_raise('error')
        # rubocop:enable RSpec/AnyInstance

        do_request

        expect_error("We're sorry, your course could not be saved.", 'courses')
        expect(response).to be_server_error
      end

      context 'when the program has no standard set,' do
        it 'returns an error when a standard set is present' do
          standard_set = create(:standard_set)

          expect do
            do_request(
              create_params.deep_merge(course: { standard_set_ids: [standard_set.id] })
            )
          end.not_to change(Course, :count)

          expect_error('Standard sets must be blank')
        end

        it 'creates a course when no standard set is present' do
          expect do
            do_request
          end.to change(Course, :count).by(1)

          expect(Course.last).to have_attributes(
            standard_set_ids: []
          )
        end
      end

      context 'with course configuration data' do
        it 'saves an empty string, if there is no roster linked configuration' do
          do_request(
            create_params.deep_merge(course: { one_roster_linked: false, lti_roster_linked: false })
          )

          expect(JSON.parse(Course.last.course_config_json)['setup_method']).to eq('custom_setup')
          expect(
            JSON.parse(Course.last.course_config_json)['streamlined_rostering_setup']
          ).to eq('')
        end

        it 'saves RA, if there is a roster linked configuration' do
          do_request(
            create_params.deep_merge(course: { one_roster_linked: true, lti_roster_linked: false })
          )

          expect(JSON.parse(Course.last.course_config_json)['setup_method']).to eq('custom_setup')
          expect(
            JSON.parse(Course.last.course_config_json)['streamlined_rostering_setup']
          ).to eq('RA')
        end

        it 'saves LTI-A-R, if there a LTI roster linked configuration' do
          do_request(
            create_params.deep_merge(course: { one_roster_linked: false, lti_roster_linked: true })
          )

          expect(JSON.parse(Course.last.course_config_json)['setup_method']).to eq('custom_setup')
          expect(
            JSON.parse(Course.last.course_config_json)['streamlined_rostering_setup']
          ).to eq('LTI-A-R')
        end

        it 'returns true, if the course is supersite junior' do
          allow_any_instance_of(described_class).to receive(:current_program).and_return(program)
          allow(program).to receive(:supersite_junior?).and_return(true)

          do_request(
            create_params.deep_merge(course: { one_roster_linked: false, lti_roster_linked: false })
          )

          expect(JSON.parse(Course.last.course_config_json)['supersite_jr']).to be true
        end

        it 'returns false, if the course is supersite junior' do
          allow_any_instance_of(described_class).to receive(:current_program).and_return(program)
          allow(program).to receive(:supersite_junior?).and_return(false)
          do_request(
            create_params.deep_merge(course: { one_roster_linked: false, lti_roster_linked: false })
          )

          expect(JSON.parse(Course.last.course_config_json)['supersite_jr']).to be false
        end
      end

      context 'when the school disabled chat support,' do
        before do
          create(:school_config, school:, chat_support_disabled: true)
        end

        it 'creates a course with the chat level set to disabled' do
          expect do
            do_request
          end.to change(Course, :count).by(1)

          expect(response).to be_created
          expect(flash[:notice]).to match(/created successfully/)

          expect(Course.last).to have_attributes(
            original_attrs.merge(chat_level: 'disabled')
          )
        end
      end

      context 'when the program supports a list of standard sets,' do
        let(:standard_set_1) { create(:standard_set) }
        let(:standard_set_2) { create(:standard_set) }
        let!(:standard_set_3) { create(:standard_set) }

        before do
          create(
            :program_config_with_standard_sets,
            program:,
            supported_standard_sets: [standard_set_1, standard_set_2]
          )
        end

        it 'creates a course when no standard set is present' do
          expect do
            do_request
          end.to change(Course, :count).by(1)

          expect(Course.last).to have_attributes(
            standard_set_ids: []
          )
        end

        it 'returns an error when a standard set is not supported by the program' do
          do_request(
            create_params.deep_merge(
              course: {
                standard_set_ids: [standard_set_1, standard_set_3].map(&:id).map(&:to_s)
              }
            )
          )

          expect_error('Standard sets must be supported by the program')
        end

        it 'creates a course when a valid list of standard sets is provided' do
          expect do
            do_request(
              create_params.deep_merge(
                course: {
                  standard_set_ids: [standard_set_1, standard_set_2].map(&:id).map(&:to_s)
                }
              )
            )
          end.to change(Course, :count).by(1)

          expect(Course.last).to have_attributes(
            standard_sets: [standard_set_1, standard_set_2]
          )
        end
      end

      it 'creates a new course record when valid params are specified' do
        do_request

        # for debugging validation errors
        puts JSON.parse(response.body).inspect if response.unprocessable?

        expect(response).to be_created
        expect(flash[:notice]).to match(/created successfully/)

        course = Course.last

        # Verify the body is a JSON representation of the created course.
        expect(JSON.parse(response.body)).to match hash_including(
          'end_date' => course.end_date.to_s,
          'first_unit_id' => course.first_unit_id,
          'last_unit_id' => course.last_unit_id,
          'level' => course.level,
          'name' => course.name,
          'owner_id' => instructor.id,
          'program_id' => program.id,
          'start_date' => course.start_date.to_s
        )

        # Verify that posted params were permitted and saved.
        expect(course).to have_attributes(
          original_attrs
        )

        categories = course.categories.to_a
        expect(categories.size).to eq(2)
        expect(categories.first).to have_attributes(original_category_attrs.first)
        expect(categories.first.current_scoring_ruleset).to have_attributes(
          original_scoring_ruleset_attrs
        )
        expect(categories.last).to have_attributes(original_category_attrs.last)

        # Verify non-posted attributes were set in the controller action.
        expect(course).to have_attributes(
          owner_id: instructor.id,
          program_id: program.id
        )

        # Verify instructor-created activities from previous course are
        # not copied when copy_created_activities_from_previous_course param
        # is specified as false
        expect(
          CourseLibraryActivity.where(
            activity_id: instructor_activity.id,
            course_id: course.id
          )
        ).not_to exist

        # Verify licensing API calls to create course license records.
        expect(CourseLicenseCreatorWorker).to have_received(:perform_in)
          .with(3.seconds, course.guid, original_course_package_ids)

        # Verify that the focus is set to the newly created course.
        expect(session[:focus][program.id.to_s]['course_id']).to eq(course.id)
      end

      it 'creates a new course record with help requests and score review ' \
         'disabled when program is supersite junior and valid params ' \
         'are specified' do
        program.update!(family: 'supersites_jr')

        do_request

        expect(response).to be_created

        course = Course.last

        expect(course).to have_attributes(
          allows_help_requests: false,
          allows_review_requests: false
        )
      end

      it 'copies instructor-created activities from previous courses if ' \
         'copy_created_activities_from_previous_course is specified as true' do
        do_post_with_json_params(
          create_params.deep_merge(
            course: { copy_created_activities_from_previous_course: true }
          )
        )

        course = Course.last

        expect(
          CourseLibraryActivity.where(
            activity_id: instructor_activity.id,
            course_id: course.id
          )
        ).to exist
      end
    end
  end

  describe 'POST /express_course_create' do
    let(:section_names) { ['section 1', 'section 2'] }

    let(:activity_1) do
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
    end

    let(:activity_2) do
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
    end

    let(:category_attrs) do
      {
        Credit: {
          accept_late_work: true,
          credit_only: true,
          late_work_penalty: 'flat_percent',
          max_attempts: -1,
          name: 'Credit',
          penalty_percent: 50,
          rank: 1,
          weighting_percent: 20
        },
        Graded: {
          accept_late_work: false,
          credit_only: false,
          late_work_penalty: 'percent_per_day',
          max_attempts: 2,
          name: 'Graded',
          penalty_percent: 20,
          rank: 2,
          weighting_percent: 80
        }
      }
    end

    let(:assignment_attrs) do
      [
        {
          category: 'Credit',
          due_date: 14.days.from_now.to_date,
          group_id: 1,
          id: activity_1.id
        },
        {
          category: 'Graded',
          due_date: 15.days.from_now.to_date,
          group_id: 2,
          id: activity_2.id
        }
      ]
    end

    # Params have due dates as keys, with values being an array of
    # activities to be assigned on the day. e.g.
    # {
    #   '10/22/2019' => [
    #     { id: 42217, group_id: 1, category: 'Credit' }
    #   ]
    # }
    let(:assignment_params) do
      assignment_attrs.each_with_object({}) do |attrs, memo|
        due_date = attrs[:due_date].strftime('%m/%d/%Y')
        memo[due_date] = [attrs.except(:due_date)]
      end
    end

    let(:target_path) do
      instructor_courses_express_create_path(program_id: program.id)
    end

    let(:express_create_params) do
      create_params.deep_merge(
        assignments: assignment_params,
        categories: category_attrs,
        course: { categories_attributes: nil },
        sections: section_names
      )
    end

    def do_request
      do_post_with_json_params(express_create_params)
    end

    include_examples 'require instructor with program access'

    context 'with a valid user,' do
      before do
        create(
          :course_library_activity,
          activity: instructor_activity,
          course: previous_course
        )
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'raises validation errors when invalid params are specified' do
        expect do
          do_post_with_json_params(
            express_create_params.deep_merge(course: { name: '' })
          )
        end.to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Name is required'
        )
      end

      it 'creates a new course record when valid params are specified',
         new_gb_sync: true do
        do_request

        # for debugging validation errors
        puts JSON.parse(response.body).inspect if response.unprocessable?

        expect(response).to be_ok

        expect(flash[:notice]).to match(/created successfully/)

        course = Course.last

        # Verify the body is JSON containing the BulkAssignmentCreator job id.
        expect(JSON.parse(response.body)).to have_key('job_id')

        # Verify that posted params were permitted and saved.
        # DEFAULT_COURSE_ARGS take priority over posted params.
        expect(course).to have_attributes(
          original_attrs.merge(ExpressCourseCreator::DEFAULT_COURSE_ARGS)
        )

        categories = course.categories.to_a
        expect(categories.size).to eq(2)
        expect(categories.first).to have_attributes(category_attrs[:Credit])
        expect(categories.last).to have_attributes(category_attrs[:Graded])

        # Verify sections were created with specified names.
        sections = course.sections
        expect(sections.map(&:name)).to match_array(section_names)
        sections.each do |section|
          assignment_attrs.each do |attrs|
            result = section.assignments.where(assignable_id: attrs[:id]).first
            expect(result.due_date).to eq(attrs[:due_date])
            expect(result.category.name).to eq(attrs[:category])
          end
        end

        # Verify non-posted attributes were set in the controller action.
        expect(course).to have_attributes(
          owner_id: instructor.id,
          program_id: program.id
        )

        # Verify instructor-created activities from previous course are
        # not copied when copy_created_activities_from_previous_course param
        # is specified as false
        expect(
          CourseLibraryActivity.where(
            activity_id: instructor_activity.id,
            course_id: course.id
          )
        ).not_to exist

        # Verify licensing API calls to create course license records.
        expect(CourseLicenseCreatorWorker).to have_received(:perform_in)
          .with(3.seconds, course.guid, original_course_package_ids)

        # Verify that the focus is set to the newly created course.
        expect(session[:focus][program.id.to_s]['course_id']).to eq(course.id)
      end

      it 'creates a new course record with help requests and score review ' \
         'disabled when program is supersite junior and valid params ' \
         'are specified' do
        program.update!(family: 'supersites_jr')

        do_request

        expect(response).to be_ok

        expect(flash[:notice]).to match(/created successfully/)

        course = Course.last

        expect(course).to have_attributes(
          allows_help_requests: false,
          allows_review_requests: false
        )
      end

      it 'copies instructor-created activities from previous courses if ' \
         'copy_created_activities_from_previous_course is specified as true' do
        do_post_with_json_params(
          express_create_params.deep_merge(
            course: { copy_created_activities_from_previous_course: true }
          )
        )

        course = Course.last

        expect(
          CourseLibraryActivity.where(
            activity_id: instructor_activity.id,
            course_id: course.id
          )
        ).to exist
      end

      context 'when the school disabled chat support,' do
        before do
          create(:school_config, school:, chat_support_disabled: true)
        end

        it 'creates a course with the chat level set to disabled' do
          expect do
            do_request
          end.to change(Course, :count).by(1)

          expect(response).to be_ok
          expect(flash[:notice]).to match(/created successfully/)

          expect(Course.last).to have_attributes(
            chat_level: 'disabled'
          )
        end
      end
    end
  end

  describe 'PUT /update' do
    let!(:course) do
      create(
        :course,
        original_attrs.merge(
          categories_attributes: category_attrs_with_scoring_rulesets,
          owner: instructor,
          program_id: program.id
        )
      )
    end

    let(:new_school) { create(:school) }
    let(:new_course_package_ids) { %w[4 5 6] }
    let(:category_1) { course.categories.first }
    let(:old_cat_1_ruleset_id) { category_1.current_scoring_ruleset_id }

    let(:new_attrs) do
      {
        allow_audio_transcripts: false,
        allow_video_popup_translation: false,
        allows_help_requests: false,
        allows_review_requests: false,
        chat_level: 'new chat level',
        course_package_ids: new_course_package_ids,
        enable_vocab_tutorial_translations: true,
        end_date: 60.days.from_now.to_date,
        first_unit_id: program.units.last.id,
        last_unit_id: program.units.last.id,
        level: 'new level',
        name: 'new course name',
        school_id: new_school.id,
        show_estimated_times: false,
        start_date: 4.days.from_now.to_date,
        video_subtitle_languages: 'new subtitle languages',
        video_transcript_languages: 'new transcript languages'
      }
    end

    let(:new_category_attrs) do
      [
        {
          id: nil,
          accept_late_work: false,
          credit_only: false,
          drop_low_scores: 0,
          enhanced_feedback_disabled: false,
          late_work_penalty: 'new late penalty 2',
          max_attempts: 4,
          name: 'new cat2 name',
          penalty_percent: 30,
          rank: 1,
          weighting_percent: 30
        },
        { id: course.categories.last.id, _destroy: true },
        {
          id: category_1.id,
          accept_late_work: true,
          credit_only: true,
          drop_low_scores: 1,
          enhanced_feedback_disabled: true,
          late_work_penalty: 'new late penalty',
          max_attempts: 2,
          name: 'new cat1 name',
          penalty_percent: 20,
          rank: 2,
          weighting_percent: 70
        }
      ]
    end

    let(:new_scoring_ruleset_attrs) do
      {
        category_id: category_1.id,
        ignore_accents: true,
        ignore_capitalization: true,
        ignore_punctuation: true
      }
    end

    let(:category_params) do
      # Use .map and .merge to avoid mutating new_caetegory_attrs.
      new_category_attrs.map do |attr|
        # Add some nested scoring ruleset changes to one of the original
        # categories.
        if attr == new_category_attrs.last
          attr.merge(
            scoring_rulesets_attributes: [
              new_scoring_ruleset_attrs.merge(id: nil),
              { id: old_cat_1_ruleset_id, _destroy: true }
            ]
          )
        else
          attr
        end
      end
    end

    let(:update_params) do
      {
        course: new_attrs.merge(
          categories_attributes: category_params,
          end_date: new_attrs[:end_date].to_s,
          start_date: new_attrs[:start_date].to_s
        )
      }
    end

    let(:target_path) do
      instructor_course_path(id: course.id, program_id: program.id)
    end

    def do_request
      put(target_path, params: update_params)
    end

    include_examples 'require instructor with program access'

    it 'does not allow updating courses that logged in user does not own' do
      non_owner = create(:instructor)
      log_in_user_with_access_to_programs(non_owner, [program])

      do_request

      expect(response).to redirect_to(
        instructor_dashboard_path(program_id: program.id)
      )

      expect(flash[:error]).to eq(
        described_class::COURSE_OWNER_REQUIRED_MESSAGE
      )
    end

    context 'with a valid user,' do
      before do
        log_in_user_with_access_to_programs(instructor, [program])
      end

      it 'requires a root key :course in the params' do
        expect { put(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: course/
        )
      end

      it 'does not allow updating courses in districts' do
        new_school.update!(school_type: 'district')

        do_request

        expect(response).to redirect_to best_default_path
      end

      it 'does not allow updating courses by non-clever users in clever schools' do
        new_school.update!(clever_id: 'abc123')

        do_request

        expect(response).to redirect_to best_default_path
      end

      it 'renders validation errors as JSON when invalid params are specified' do
        put(
          target_path,
          params: update_params.deep_merge(course: { name: '' })
        )

        expect_error('Name is required')
        expect(response).to be_unprocessable

        put(
          target_path,
          params: update_params.deep_merge(
            course: {
              categories_attributes: [
                { id: course.categories.first.id, _destroy: true },
                { id: course.categories.last.id, _destroy: true }
              ]
            }
          )
        )

        expect_error('Category weights must add up to 100%, currently 0%')
        expect(response).to be_unprocessable

        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Course).to receive(:save).and_raise('error')
        # rubocop:enable RSpec/AnyInstance

        do_request

        expect_error("We're sorry, your course could not be saved.", 'courses')
        expect(response).to be_server_error
      end

      it 'updates the course with the specified id when valid ' \
        'params are specified' do
        do_request

        # for debugging validation errors
        puts JSON.parse(response.body).inspect if response.unprocessable?

        expect(response).to be_ok

        course.reload

        # Verify the body is a JSON representation of the updated course.
        expect(JSON.parse(response.body)).to match hash_including(
          'end_date' => new_attrs[:end_date].to_s,
          'first_unit_id' => new_attrs[:first_unit_id],
          'last_unit_id' => new_attrs[:last_unit_id],
          'level' => new_attrs[:level],
          'name' => new_attrs[:name],
          'owner_id' => instructor.id,
          'program_id' => program.id,
          'start_date' => new_attrs[:start_date].to_s
        )

        # Verify that posted params were permitted and saved.
        expect(course).to have_attributes(new_attrs)
        categories = course.categories.to_a
        expect(categories.size).to eq(2)
        expect(categories.first).to have_attributes(
          new_category_attrs.first.except(:id)
        )
        expect(categories.last).to have_attributes(new_category_attrs.last)
        expect(categories.last.current_scoring_ruleset_id).not_to eq(
          old_cat_1_ruleset_id
        )
        expect(categories.last.current_scoring_ruleset).to have_attributes(
          new_scoring_ruleset_attrs
        )

        # Verify licensing API calls to update course license records.
        expect(CourseLicenseCreatorWorker).to have_received(:perform_in)
          .with(3.seconds, course.guid, new_course_package_ids)
      end

      context 'when the school disabled chat support,' do
        before do
          create(:school_config, school: new_school, chat_support_disabled: true)
        end

        it 'updates the course with the chat level set to disabled' do
          expect do
            do_request
          end.not_to change(Course, :count)

          expect(response).to be_ok

          expect(course.reload).to have_attributes(
            new_attrs.merge(chat_level: 'disabled')
          )
        end
      end

      context 'when the program has no standard set,' do
        it 'renders validation errors when a standard set is specified' do
          standard_set = create(:standard_set)

          put(
            target_path,
            params: update_params.deep_merge(course: { standard_set_ids: [standard_set.id] })
          )

          expect_error('Standard sets must be blank')
          expect(response).to be_unprocessable
        end
      end

      context 'when the program supports a list of standard sets,' do
        let(:standard_set_1) { create(:standard_set) }
        let(:standard_set_2) { create(:standard_set) }
        let(:standard_set_3) { create(:standard_set) }

        before do
          create(
            :program_config_with_standard_sets,
            program:,
            supported_standard_sets: [standard_set_1, standard_set_2, standard_set_3]
          )
          course.update!(standard_sets: [standard_set_1])
        end

        it 'does not generate validation errors when no standard set is specified' do
          do_request

          expect(response).to be_ok
        end

        it 'updates the course with the specified id when valid params are specified' do
          put(
            target_path,
            params: update_params.deep_merge(
              course: { standard_set_ids: [standard_set_2.id, standard_set_3.id] }
            )
          )

          expect(response).to be_ok

          course.reload

          # Verify course standard sets are updated
          expect(course.standard_sets).to contain_exactly(
            standard_set_2, standard_set_3
          )
        end
      end
    end
  end
end
