require 'requests/login_helper_methods'

describe InstitutionAdmin::CourseTemplatesController do
  let(:school) { create(:school) }
  let(:program) { create(:program_with_lessons) }
  let(:institution_admin) { create(:institution_admin) }
  let(:instructor) { create(:instructor, schools: [school]) }

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
      hide_from_instructor_dashboard: false,
      last_unit_id: program.units.first.id,
      level: 'original level',
      name: 'original course name',
      owner_id: instructor.id,
      school_id: school.id,
      show_estimated_times: true,
      start_date: 2.days.from_now.to_date,
      video_subtitle_languages: 'original subtitle languages',
      video_transcript_languages: 'original transcript languages'
    }
  end

  let(:section_attrs) do
    {
      class_days: '1, 3, 5'
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

  def do_post_request(request_params)
    post(target_path, params: request_params)
  end

  def do_put_request(request_params)
    put(target_path, params: request_params)
  end

  def expect_error(message, key = 'errors')
    expect(response.parsed_body[key]).to include(message)
  end

  before do
    create(
      :school_program_admin_user,
      account_type: institution_admin.account_type,
      program:,
      school:,
      user: institution_admin
    )
    create(
      :school_user,
      user: institution_admin,
      school:
    )
  end

  before do
    log_in_user_with_access_to_programs(institution_admin, [program])
  end

  describe 'POST /create' do
    let(:target_path) do
      institution_admin_create_course_template_path(program_id: program.id, school_id: school.id)
    end

    let(:create_params) do
      {
        course: original_attrs.merge(
          categories_attributes: category_attrs_with_scoring_rulesets,
          end_date: original_attrs[:end_date].to_s,
          start_date: original_attrs[:start_date].to_s
        ),
        section: section_attrs
      }
    end

    context 'when invalid params are specified' do
      before { do_post_request(create_invalid_params) }

      context 'when empty course name' do
        let(:create_invalid_params) { create_params.deep_merge(course: { name: '' }) }

        it { expect(response).to be_unprocessable }
        it { expect_error('Name is required') }
      end

      context 'when empty categories_attributes' do
        let(:create_invalid_params) do
          create_params.deep_merge(course: { categories_attributes: [] })
        end

        it { expect(response).to be_unprocessable }
        it { expect_error('Course must have at least one category.') }
      end

      context 'when empty class_days' do
        let(:create_invalid_params) { create_params.deep_merge(section: { class_days: '' }) }

        it { expect(response).to be_unprocessable }
        it { expect_error('Enterprise section class days is required') }
      end
    end

    context 'when an error occurs when saving the course' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Course).to receive(:save).and_raise('error')
        # rubocop:enable RSpec/AnyInstance
        do_post_request(create_params)
      end

      it { expect(response).to be_server_error }
      it { expect_error("We're sorry, your course could not be saved.", 'courses') }
    end

    context 'when valid params are specified' do
      it 'creates a new course and section enterprise' do
        expect do
          do_post_request(create_params)
        end.to change(Course, :count).by(1).and change(Section.enterprise, :count).by(1)

        expect(response).to be_created

        course = Course.last
        expect(course).to have_attributes(
          owner_id: instructor.id,
          program_id: program.id,
          is_enterprise: true,
          hide_from_instructor_dashboard: original_attrs[:hide_from_instructor_dashboard]
        )

        expect(course.enterprise_section).to have_attributes(
          name: "Enterprise Section: #{course.name}",
          instructor_id: course.owner_id,
          class_days: section_attrs[:class_days]
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:target_path) do
      institution_admin_update_course_template_path(
        id: course.id,
        program_id: program.id,
        school_id: school.id
      )
    end

    let(:update_params) do
      {
        course: new_attrs.merge(
          end_date: new_attrs[:end_date].to_s,
          start_date: new_attrs[:start_date].to_s
        ),
        section: new_section_attrs
      }
    end

    let!(:course) do
      create(
        :enterprise_course,
        original_attrs.merge(
          categories_attributes: category_attrs_with_scoring_rulesets,
          owner: instructor,
          program_id: program.id,
          enterprise_section: create(:enterprise_section, section_attrs.merge(instructor:))
        )
      )
    end

    let(:new_course_package_ids) { %w[4 5 6] }
    let(:new_section_attrs) { { class_days: '2, 4' } }
    let(:new_instructor) { create(:instructor, schools: [school]) }

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
        hide_from_instructor_dashboard: false,
        last_unit_id: program.units.last.id,
        level: 'new level',
        name: 'new course name',
        owner_id: new_instructor.id,
        school_id: school.id,
        show_estimated_times: false,
        start_date: 4.days.from_now.to_date,
        video_subtitle_languages: 'new subtitle languages',
        video_transcript_languages: 'new transcript languages'
      }
    end

   context 'when invalid params are specified' do
      before { do_put_request(request_invalid_params) }

      context 'when empty course name' do
        let(:request_invalid_params) { update_params.deep_merge(course: { name: '' }) }

        it { expect(response).to be_unprocessable }
        it { expect_error('Name is required') }
      end

      context 'when empty owner' do
        let(:request_invalid_params) { update_params.deep_merge(course: { owner_id: '' }) }

        it { expect(response).to be_unprocessable }
        it { expect_error('Owner must exist') }
        it { expect_error('Enterprise section instructor must exist') }
      end

      context 'when empty class_days' do
        let(:request_invalid_params) { update_params.deep_merge(section: { class_days: '' }) }

        it { expect(response).to be_unprocessable }
        it { expect_error('Enterprise section class days is required') }
      end
    end

    context 'when an error occurs when saving the course' do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Enterprise::CourseUpdater).to receive(:update).and_raise('error')
        # rubocop:enable RSpec/AnyInstance
        do_put_request(update_params)
      end

      it { expect(response).to be_server_error }
      it { expect_error("We're sorry, your course could not be saved.", 'courses') }
    end

    context 'when valid params are specified' do
      before { do_put_request(update_params) }

      it { expect(response).to be_ok }

      it 'updates the course' do
        expect(course.reload).to have_attributes(
          name: new_attrs[:name],
          owner_id: new_instructor.id,
          hide_from_instructor_dashboard: new_attrs[:hide_from_instructor_dashboard]
        )
      end

      # if the enterprise section was updated, all sections were updated. Already tested in
      # spec/models/enterprise/course_updater_spec and models/enterprise/course_owner_updater_spec
      it 'updates the enterprise section' do
        expect(course.reload.enterprise_section).to have_attributes(
          name: "Enterprise Section: #{course.name}",
          instructor_id: new_instructor.id,
          class_days: new_section_attrs[:class_days]
        )
      end
    end
  end
end
