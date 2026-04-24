# encoding:  utf-8

describe ActivitiesController, core: true, type: :controller do
  let(:scope) { double('Scope') }
  let(:activity_type) { 'fill_in_the_blanks'.freeze }
  let(:score) { instance_double(GradebookEngine::ScoreAction) }

  before do
    allow(BestDefaultPath).to receive(:best_default_path).and_return('/home')
    allow(Activity).to receive(:unscoped).and_return(scope)
  end

  def mock_content_object
    wol_format = 'question <input type="text"id="55"size="20"/>'
    allow(MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item).to receive(:format_wol_as_input).with(1, 'question <wol ref="55"/> prompt').and_return(wol_format)
    item = double(MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item, prompt: 'question <wol ref="55"/> prompt', prompt_id: 1)
    allow(item).to receive(:label).with(0).and_return('question_01')
    items = [item]
    double(MaestroActivityEngine::ActivityContent::FillInTheBlanksContent, class: MaestroActivityEngine::ActivityContent::FillInTheBlanksContent, items: items,
                                                                           style: nil, max_attempts: nil, activity_type: 'fill_in_the_blanks',
                                                                           vocablist_content?: false, audio_reference_media_item: nil, grading_method: nil, content_summary: nil,
                                                                           submittable?: true, points_possible: 1, language: 'es', validate_responses: {})
  end

  def mock_attempt_track(options = {})
    double(AttemptTrack, { number: 1,
                           max: 'unlimited',
                           final: false,
                           used: 0,
                           remaining: 'unlimited',
                           complete: false,
                           view_only: false,
                           practice?: false }.merge(options))
  end

  def ensure_correct_section(correct_section = nil)
    allow(@controller).to receive(:current_section).and_return(correct_section || Section.section_zero)
    allow(@user).to receive(:current_section_in_program).and_return(correct_section)
  end

  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }

  let(:presenter) do
    double(StudentActivityPresenter, activity: @activity,
                                     should_show_answers: nil,
                                     activity_list_header: 'Leccion 1 | Adelante | Lectura',
                                     lesson_header: 'Leccion 1',
                                     video_settings: 'valid_video_settings',
                                     notifications: [],
                                     redirect_to_dashboard: false,
                                     flash_notice: nil,
                                     section: (@section || section),
                                     course: (@course || course),
                                     should_show_answers?: false,
                                     redirect_to_dashboard?: false,
                                     partner_chat?: false,
                                     :activity_in_study_plan= => false,
                                     solo_video_recording_or_included_in_multipart_activity?: false,
                                     group_chat?: false)
  end

  let(:access_guardian) do
    double('AccessGuardian',
           can_access_content?: true,
           has_grace_period?: false,
           has_mobile_app?: false)
  end

  describe '#scored_rubric' do
    let(:rubric_activity) { create(:activity) }
    let(:student) { create(:student) }

    def do_scored_rubric(params)
      get(:scored_rubric, params: params)
    end

    before do
      instructor = create(:instructor)

      fake_login(instructor)
      allow(scope).to receive(:find).and_return(rubric_activity)
      ensure_correct_section(@section)
      allow(rubric_activity).to receive(:has_rubric?).and_return true
      allow(rubric_activity).to receive(:rubric).and_return({})
      allow(rubric_activity).to receive(:ensure_correct_version)
      allow(Activity).to receive(:unscoped).and_call_original
      create(
        :attempt_reset,
        user_id: student.id,
        activity_id: rubric_activity.id,
        section_id: 2
      )
      create(
        :attempt_completed,
        user_id: student.id,
        activity_id: rubric_activity.id,
        section_id: 2
      )
      allow(Activity).to receive(:unscoped).and_return(scope)
      allow(RubricPresenter).to receive(:new).and_return({})
    end

    it 'renders the scored rubric view if a completed attempt exists' do
      do_scored_rubric(section_id: 2, id: rubric_activity.id, user_id: student.id)
      expect(response).to render_template(:rubric)
    end

    it 'raises an error if a completed attempt does not exist' do
      expect do
        do_scored_rubric(section_id: 3, id: rubric_activity.id, user_id: 1)
      end.to raise_error(StandardError, 'The completed attempt could not be found.')
    end
  end

  describe '#rubric' do
    let(:instructor) { create(:instructor) }
    let(:student) { create(:student) }
    let(:program) { create(:program_with_lessons) }
    let!(:rubric_activity) { create(:activity_with_program) }
    let(:course) do
      create(
        :course,
        owner: instructor,
        program: program,
        allows_help_requests: true,
        allows_review_requests: true
      )
    end

    let(:section) { create(:section, course: course, instructor: instructor) }

    def do_rubric(params)
      get(:rubric, params: params)
    end

    before do
      allow(scope).to receive(:find).and_return(rubric_activity)
      allow(rubric_activity).to receive(:has_rubric?).and_return true
      allow(rubric_activity).to receive(:rubric).and_return({})
      allow(rubric_activity).to receive(:ensure_correct_version)
      allow(RubricPresenter).to receive(:new).and_return({})
    end

    context 'with an instructor' do
      before do
        fake_login(instructor)
      end

      it 'renders the rubric static view' do
        do_rubric(section_id: 0, id: rubric_activity.id)
        expect(response).to render_template(:rubric)
      end

      it 'sets a flag to disable chat on the popup' do
        do_rubric(section_id: 0, id: rubric_activity.id)
        expect(assigns(:disable_chat_on_page)).to be true
      end

      it 'assigns a page title based on the "from" the query param if present' do
        do_rubric(section_id: 0, id: rubric_activity.id, from: 'grading')
        expect(assigns(:page_title)).to eq('Grade Using Rubric')
      end

      it 'assigns a page title when the "from" query param is not present' do
        do_rubric(section_id: 0, id: rubric_activity.id)
        expect(assigns(:page_title)).to eq('Rubric')
      end

      it 'sets a flag to not show the app shell' do
        do_rubric(section_id: 0, id: rubric_activity.id)
        expect(assigns(:no_app_shell)).to be true
      end

      it 'shows a flash message if activity does not have a rubric' do
        allow(rubric_activity).to receive(:has_rubric?).and_return false
        allow(rubric_activity).to receive(:has_external_rubric?).and_return false
        do_rubric(section_id: 0, id: rubric_activity.cms_revision_id)
        expect(flash[:error]).to eq('There is no rubric for this activity.')
      end

      context 'when there is a custom rubric activity' do
        let(:rubric_xml) do
          <<-RUBRIC
            <rubric id="1" rubric_revision_id="2">
              <header_row>
                <header_column id="1"> 5 </header_column>
              </header_row>
              <criteria>
                  <title> Content </title>
                <performance header_id="1">
                  <description> some description </description>
                  <score> 30 </score>
                </performance>
              </criteria>
            </rubric>
          RUBRIC
        end
        let(:content_object) do
          instance_double(
            MaestroActivityEngine::ActivityContent::CompositionContent,
            activity_type: 'composition',
            content_summary: { question_1: 1 },
            grading_method: 'instructor_graded',
            max_attempts: 2,
            points_possible: 10,
            submittable?: true,
            randomizable?: true
          )
        end
        let(:custom_rubric) do
          instance_double(CustomRubric, stored_rubric: rubric_xml, source_rubric_id: 1)
        end

        let(:doc) do
          Nokogiri::XML.parse(
            File.new('spec/fixtures/xml/solo_video_recording_with_rubric.xml')
          )
        end

        let(:rubric) do
          MaestroActivityEngine::TagParser::Rubric.new(doc, '//rubric').parse.first
        end

        let!(:attempt) do
          create(
            :attempt_completed,
            section_id: section.id,
            user_id: student.id,
            activity: rubric_activity
          )
        end
        let(:activity_args) do
          {
            source_rubric_id: 1,
            draft: false,
            course_id: course.id
          }
        end

        before do
          fake_login(student)
          allow(CustomRubric).to receive(:find_by)
            .with(activity_args).and_return(custom_rubric)
          allow(rubric_activity).to receive(:content_object).and_return(content_object)
          allow(content_object).to receive(:rubric).and_return(rubric)
          allow(custom_rubric).to receive(:[]).and_return(rubric_xml)
          allow(rubric_activity).to receive(:rubric).and_return(rubric)
          allow(content_object).to receive(:update_rubric).and_return(rubric)
          allow(content_object).to receive(:external_rubric).and_return(content_object)
        end

        it 'assigns the custom rubric activity to the presenter' do
          rubric.cms_rubric_id = 1
          do_rubric(section_id: section.id, id: rubric_activity.id)
          expect(RubricPresenter)
            .to have_received(:new) do |expected_rubric, expected_attempt|
            expect(expected_rubric)
              .to be_a MaestroActivityEngine::ActivityContent::Common::Rubric
            expect(expected_rubric.criterias.first.performances.first)
              .to eq(
                { description: 'The brochure uses a sufficient amount of lesson '\
                  'vocabulary to describe in detail the suggested activities.',
                  description_language: nil,
                  header_id: '1', score: 30 }
              )
            expect(expected_attempt.user_id).to eq(student.id)
            expect(expected_attempt.section_id).to eq(section.id)
            expect(expected_attempt.activity_id).to eq(rubric_activity.id)
          end
        end
      end
    end

    context 'with a student' do
      before do
        fake_login(student)
        allow(rubric_activity).to receive(:has_external_rubric?).and_return(false)
      end

      context 'when an opened attempt exists' do
        let!(:attempt) do
          create(
            :attempt_opened,
            section_id: section.id,
            user_id: student.id,
            activity: rubric_activity
          )
        end

        it 'finds the revision associated with an attempt' do
          do_rubric(section_id: section.id, id: rubric_activity.id)
          expect(rubric_activity)
            .to have_received(:ensure_correct_version).with(attempt.cms_revision_id)
        end
      end

      context 'when a completed attempt exists' do
        let!(:attempt) do
          create(
            :attempt_completed,
            section_id: section.id,
            user_id: student.id,
            activity: rubric_activity
          )
        end

        it 'finds the revision associated with an attempt' do
          do_rubric(section_id: section.id, id: rubric_activity.id)
          expect(rubric_activity)
            .to have_received(:ensure_correct_version).with(attempt.cms_revision_id)
        end
      end

      context 'when a reset and completed attempt exists' do
        it 'finds the completed attempt, not the reset attempt' do
          attempt_reset = create(
            :attempt_reset,
            user_id: student.id,
            section_id: section.id,
            activity: rubric_activity,
            cms_revision_id: 1
          )
          attempt_complete = create(
            :attempt_completed,
            user_id: student.id,
            section_id: section.id,
            activity: rubric_activity,
            cms_revision_id: 2
          )
          allow(RubricPresenter).to receive(:new).with({}, attempt_complete).and_return({})
          do_rubric(section_id: section.id, id: rubric_activity.id)
          expect(RubricPresenter).to have_received(:new).with({}, attempt_complete)
        end
      end
    end
  end

  before do
    allow(Maestro::User).to receive(:accessible_programs).and_return([double('AccessibleProgram', id: 1)])
    allow(controller).to receive(:access_guardian).and_return(access_guardian)
    @user = create(:student)
    @classwork = instance_double(Classwork)
    allow(Classwork).to receive(:new).and_return(@classwork)
    attempt = build_stubbed(:attempt)
    allow(attempt).to receive(:activity=)
    allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)
    allow(@classwork).to receive(:current_workset).and_return(nil)
    allow(presenter.notifications).to receive(:dismiss_all!)

    student_grade = instance_double(
      GradebookEngine::AssignmentGrade,
      adjusted?: false,
      submitted?: true
    )
    allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade)
      .and_return(student_grade)
  end

  describe 'security policy' do
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, program:, school:, owner: instructor, chat_level: 'disabled') }
    let(:section) { create(:section, course:) }
    let(:activity) { create(:activity) }

    before do
      allow(scope).to receive(:find).with(activity.id.to_s).and_return(activity)
      allow(controller).to receive(:ensure_correct_section)
      allow(controller).to receive(:require_program_access).and_return(true)
      allow(controller).to receive(:warn_insufficient_course_access).and_return(true)
      allow(controller).to receive(:common_prep)
      allow(controller).to receive(:assign_video_settings)
      allow(controller).to receive(:assign_show_correct_answers)
      allow(controller).to receive(:set_assignment_validator)
      allow(controller).to receive(:process_show_activity)
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)

      allow(controller).to receive(:current_section).and_return(section)
      allow(BestDefaultPath).to receive(:best_default_path).and_return('/home')
    end

    it 'requires a logged in user' do
      allow(controller).to receive(:current_user).and_return(false)
      get :show, params: { section_id: section.id, id: activity.id }
      expect(response.redirect?).to be_truthy
    end

    describe 'when viewing a partner chat activity' do
      before do
        activity.update!(activity_type: 'partner_chat')
      end

      context 'for students' do
        before do
          fake_login(student)
        end

        context 'when enrolled in a course,' do
          it 'denies access when the school has disabled chat support' do
            create(:school_config, school:, chat_support_disabled: true)

            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your institution has disabled chat support.')
          end

          it 'denies access when the course has chat support disabled' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your instructor has disabled Partner Chat for this course')
          end

          it 'allows access when the course has chat support enabled' do
            course.update!(chat_level: 'partner_chat')

            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end

        context 'when not enrolled in a course,' do
          let(:section) { Section.section_zero }

          it 'denies access' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq(
              'You are not enrolled in a course, Partner Chat is disabled.'
            )
          end
        end
      end

      context 'for instructors' do
        let(:focus) { instance_double(Focus, course:) }

        before do
          fake_login(instructor)
          allow(controller).to receive(:current_focus).and_return(focus)
        end

        it 'denies access when the school has disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_redirect
          expect(flash[:error]).to eq('Your institution has disabled chat support.')
        end

        it 'allows access when the course has chat support disabled' do
          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_ok
          expect(flash[:error]).to be_blank
        end

        it 'allows access when the course has chat support enabled' do
          course.update!(chat_level: 'partner_chat')

          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_ok
          expect(flash[:error]).to be_blank
        end

        context 'when no section is selected,' do
          let(:section) { Section.section_zero }

          it 'allows access' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end
      end
    end

    describe 'when viewing a group chat activity' do
      before do
        activity.update!(activity_type: 'group_chat')
      end

      context 'for students' do
        before do
          fake_login(student)
        end

        context 'when enrolled in a course,' do
          it 'denies access when the school has disabled chat support' do
            create(:school_config, school:, chat_support_disabled: true)

            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your institution has disabled chat support.')
          end

          it 'denies access when the course has chat support disabled' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your instructor has disabled Group Chat for this course')
          end

          it 'allows access when the course has chat support enabled' do
            course.update!(chat_level: 'partner_chat')

            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end

        context 'when not enrolled in a course,' do
          let(:section) { Section.section_zero }

          it 'denies access' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_redirect
            expect(flash[:error]).to eq(
              'You are not enrolled in a course, Group Chat is disabled.'
            )
          end
        end
      end

      context 'for instructors' do
        let(:focus) { instance_double(Focus, course:) }

        before do
          fake_login(instructor)
          allow(controller).to receive(:current_focus).and_return(focus)
        end

        it 'denies access when the school has disabled chat support' do
          create(:school_config, school:, chat_support_disabled: true)

          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_redirect
          expect(flash[:error]).to eq('Your institution has disabled chat support.')
        end

        it 'allows access when the course has chat support disabled' do
          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_ok
          expect(flash[:error]).to be_blank
        end

        it 'allows access when the course has chat support enabled' do
          course.update!(chat_level: 'partner_chat')

          get :show, params: { section_id: section.id, id: activity.id }

          expect(response).to be_ok
          expect(flash[:error]).to be_blank
        end

        context 'when no section is selected,' do
          let(:section) { Section.section_zero }

          it 'allows access' do
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end
      end
    end

    describe 'when viewing an ai virtual chat activity' do
      before do
        activity.update!(activity_type: 'ai_virtual_chat')
      end

      context 'for students' do
        before do
          fake_login(student)
        end

        context 'when enrolled in a course,' do
          it 'denies access when the school has disabled chat support' do
            create(:school_config, school: school, chat_support_disabled: true)
            get :show, params: { section_id: section.id, id: activity.id }
            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your institution has disabled chat support.')
          end

          it 'denies access when the course has ai virtual chat disabled' do
            course.update!(ai_virtual_chat_level: false)
            get :show, params: { section_id: section.id, id: activity.id }
            expect(response).to be_redirect
            expect(flash[:error]).to eq('Your instructor has disabled AI Chat for this course')
          end

          it 'allows access when the course has ai virtual chat enabled' do
            course.update!(ai_virtual_chat_level: true)
            get :show, params: { section_id: section.id, id: activity.id }
            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end
      end

      context 'for instructors' do
        let(:focus) { instance_double(Focus, course:) }

        before do
          fake_login(instructor)
          allow(controller).to receive(:current_focus).and_return(focus)
        end

        it 'allows access regardless of ai_virtual_chat_level setting' do
          [false, true].each do |chat_level|
            course.update!(ai_virtual_chat_level: chat_level)
            get :show, params: { section_id: section.id, id: activity.id }

            expect(response).to be_ok
            expect(flash[:error]).to be_blank
          end
        end
      end
    end

    describe 'require_ai_virtual_chat_enabled callback' do
      let(:ai_virtual_chat_activity) { create(:activity, activity_type: 'ai_virtual_chat') }
      let(:student) { create(:student) }
      let(:course) { create(:course, ai_virtual_chat_level: false) }
      let(:section) { create(:section, course: course) }

      before do
        fake_login(student)
        allow(scope).to receive(:find).with(ai_virtual_chat_activity.id.to_s).and_return(ai_virtual_chat_activity)
        allow(controller).to receive(:current_section).and_return(section)
        allow(controller).to receive(:current_section_id).and_return(section.id)
        allow(controller).to receive(:current_user).and_return(student)
        allow(controller).to receive(:current_program).and_return(ai_virtual_chat_activity.program)
        allow(BestDefaultPath).to receive(:best_default_path).and_return('/home')

        # Stub the classwork methods
        workset = instance_double(Workset, next_activity: nil)
        allow(@classwork).to receive(:current_workset).with(ai_virtual_chat_activity).and_return(workset)
      end

      it 'redirects student when ai virtual chat is disabled' do
        get :show, params: { section_id: section.id, id: ai_virtual_chat_activity.id }

        expect(response).to be_redirect
        expect(flash[:error]).to eq('Your instructor has disabled AI Chat for this course')
      end

      it 'allows access when ai virtual chat is enabled' do
        course.update!(ai_virtual_chat_level: true)

        get :show, params: { section_id: section.id, id: ai_virtual_chat_activity.id }

        expect(response).not_to be_redirect
        expect(flash[:error]).to be_blank
      end

      it 'redirects to next activity when ai virtual chat is disabled and next activity exists' do
        next_activity = create(:activity, title: 'Next Activity')
        workset = instance_double(Workset, next_activity: next_activity)
        allow(@classwork).to receive(:current_workset).with(ai_virtual_chat_activity).and_return(workset)

        get :show, params: { section_id: section.id, id: ai_virtual_chat_activity.id }

        expect(response).to redirect_to(section_activity_path(section.id, next_activity.id))
        expect(flash[:error]).to eq('Your instructor has disabled AI Chat for this course')
      end

      it 'shows error when ai virtual chat is disabled and no next activity exists' do
        workset = instance_double(Workset, next_activity: Workset::LAST_ACTIVITY)
        allow(@classwork).to receive(:current_workset).with(ai_virtual_chat_activity).and_return(workset)

        get :show, params: { section_id: section.id, id: ai_virtual_chat_activity.id }

        expect(response).to redirect_to('/home')
        expect(flash[:error]).to eq('Your instructor has disabled AI Chat for this course')
      end
    end
  end

  it_should_have_help

  it_behaves_like 'an action that prevents access to a blocked enrollment' do
    let(:student) { create(:student) }
  end

  describe '#show' do
    it_behaves_like 'an action that shows an activity' do
      let(:instructor_user) { build_stubbed(:instructor) }

      context 'popup layouts' do
        it 'returns popup layout when popup passes is 1' do
          fake_login(@user)
          expect(scope).to receive(:find).with('37').and_return(@activity)
          do_request('0', '37', popup: '1')
          expect(response).to render_template(layout: 'layouts/activity_popup')
        end

        it 'returns popup layout when popup passes is true' do
          fake_login(@user)
          expect(scope).to receive(:find).with('37').and_return(@activity)
          do_request('0', '37', popup: 'true')
          expect(response).to render_template(layout: 'layouts/activity_popup')
        end

        it ' returns normal activity layout when popup passes neither 1 or true' do
          fake_login(@user)
          expect(scope).to receive(:find).with('37').and_return(@activity)
          do_request('0', '37', popup: 'not_1_or_true')
          expect(response).to render_template(layout: 'layouts/activity')
        end
      end

      describe 'skipping to practice mode' do
        before do
          allow(@classwork).to receive(:practice_attempt).and_return(@attempt)
          allow(@attempt).to receive(:validate_responses).and_return(
            instance_double(
              MaestroActivityEngine::ActivityContent::Results,
              complete?: false
            )
          )
        end

        it 'skips to practice mode when pratice param is set to true' do
          fake_login(@user)
          do_request(section.id, nil, practice: 'true')
          expect(@classwork).to have_received(:practice_attempt)
        end

        it 'does not skip to practice mode for non-partner-chat activities' do
          fake_login(@user)
          allow(presenter).to receive(:partner_chat?).and_return(false)
          do_request(section.id)
          expect(@classwork).not_to have_received(:practice_attempt)
        end

        context 'with a partner-chat activity' do
          before do
            allow(presenter).to receive(:partner_chat?).and_return(true)
            fake_login(@user)
          end

          it 'does not skip to practice mode if joinchat param is not true' do
            do_request(section.id, nil, joinchat: 'false')
            expect(@classwork).not_to have_received(:practice_attempt)
          end

          it 'does not skip to practice mode if joinchat param is true ' \
             'but the user has no completed attempt' do
            do_request(section.id, nil, joinchat: 'true')
            expect(@classwork).not_to have_received(:practice_attempt)
          end

          it 'skips to practice mode if joinchat param is true ' \
             'and the user has a completed attempt' do
            allow(Activity).to receive(:unscoped).and_call_original
            create(
              :attempt_completed,
              activity_id: @activity.id,
              section_id: section.id,
              user_id: @user.id
            )
            allow(Activity).to receive(:unscoped).and_return(scope)
            do_request(section.id, nil, joinchat: 'true')
            expect(@classwork).to have_received(:practice_attempt)
          end

          # It behaves the same as for a student
          context 'for instructor' do
            let(:practice_instructor) { create(:instructor) }

            before do
              allow(practice_instructor).to receive(:has_current_access_to?).and_return(true)
              fake_login(practice_instructor)
            end

            it 'does not skip to practice mode if joinchat param is true ' \
               'but the user has no completed attempt' do
              do_request(0, nil, joinchat: 'true')
              expect(@classwork).not_to have_received(:practice_attempt)
              # expect(response).to render_template(partial: 'preview')
            end

            it 'skips to practice mode if joinchat param is true ' \
               'and the user has a completed attempt' do
              allow(Activity).to receive(:unscoped).and_call_original
              create(
                :attempt_completed,
                activity_id: @activity.id,
                section_id: 0,
                user_id: practice_instructor.id
              )
              allow(Activity).to receive(:unscoped).and_return(scope)
              do_request(0, nil, joinchat: 'true')
              expect(@classwork).to have_received(:practice_attempt)
              # expect(response).to render_template(partial: 'preview')
            end
          end
        end
      end

      context 'when activity is an assessment and has not been released' do
        it_behaves_like 'an action that informs the assessment is not available' do
          it 'redirects to the non-Junior student dashboard when program is ' +
             'not a Supersite Junior program' do
            allow(@activity.program).to receive(:supersite_junior?).and_return(false)
            fake_login(@user)
            do_request(section.id)
            expect(response).to redirect_to course_section_path(course, section)
          end

          it 'redirects to the SS Junior student dashboard when program is ' +
             'Supersite Junior program' do
            allow(@activity.program).to receive(:supersite_junior?).and_return(true)
            fake_login(@user)
            do_request(section.id)
            expect(response).to redirect_to jr_course_section_path(course, section)
          end
        end
      end

      context 'given a student who is not enrolled in any section for the current activity program,' do
        before do
          allow(@user).to receive(:current_section_in_program).with(@program).and_return(nil)
        end

        context 'when a section param of zero is specified,' do
          it 'renders the show view and does not redirect them' do
            fake_login(@user)
            do_request('0')
            expect(response.redirect_url).to be_nil
            expect(response).to render_template :show
          end
        end

        context 'when a non-zero section param for a section that exists is specified,' do
          it 'redirects them to the show page for the same activity but with section id zero' do
            other_section = build_stubbed(:section_with_course)
            allow(controller).to receive(:current_section).and_return(other_section)
            fake_login(@user)
            do_request(other_section.id.to_s)
            expect(response).to redirect_to section_activity_path(section_id: 0, id: @activity.id)
            expect(flash[:notice]).to eq('You have been redirected to the correct address for this activity.')
          end
        end

        context 'when a non-zero section param for a section that does not exist is specified,' do
          it 'redirects them to the show page for the same activity but with section id zero' do
            non_existing_section_id = '12345'
            allow(controller).to receive(:current_section).and_return(nil)
            fake_login(@user)
            do_request(non_existing_section_id)
            expect(response).to redirect_to section_activity_path(0, @activity.id)
            expect(flash[:notice]).to eq('You have been redirected to the correct address for this activity.')
          end
        end
      end

      context 'given a student who is enrolled in a section for the current activity program,' do
        let(:active_section) { build_stubbed(:section_with_course) }

        before do
          allow(@user).to receive(:current_section_in_program).and_return( active_section )
        end

        it_behaves_like 'an action that renders the show view'

        context 'when the specified section param is for a section other than their active section,' do
          it 'redirects them to the show page for the same activity but for their active section' do
            other_section = build_stubbed(:section_with_course)
            allow(controller).to receive(:current_section).and_return(other_section)
            fake_login(@user)
            do_request(other_section.id.to_s)
            expect(response).to redirect_to section_activity_path(section_id: active_section, id: @activity.id)
            expect(flash[:notice]).to eq('You have been redirected to the correct address for this activity.')
          end

          it 'redirects them to the show page for the same activity but for their active section and passes along all params' do
            other_section = build_stubbed(:section_with_course)
            params = { begin_work: 'foo' }
            allow(controller).to receive(:current_section).and_return(other_section)
            fake_login(@user)
            do_request(other_section.id.to_s, nil, params)
            expect(response).to redirect_to section_activity_path(params.merge(section_id: active_section))
            expect(flash[:notice]).to eq('You have been redirected to the correct address for this activity.')
          end
        end

        context 'when section param of zero is specified,' do
          it 'redirects them to the show page for the same activity but for their active section' do
            allow(controller).to receive(:current_section).and_return(Section.section_zero)
            fake_login(@user)
            do_request('0')
            expect(response).to redirect_to section_activity_path(section_id: active_section, id: @activity.id)
            expect(flash[:notice]).to eq('You have been redirected to the correct address for this activity.')
          end
        end
      end

      it 'assigns the activity return link' do
        session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
        fake_login(@user)
        do_request('0')
        expect(assigns(:return_label)).to eq('Somewhere')
        expect(assigns(:return_url)).to eq('/valid/path')
      end

      it 'should assign instructor_feedback ' do
        allow(@attempt).to receive(:common_instructor_feedback).and_return(double(FeedbackItem))
        session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
        fake_login(@user)
        do_request('0')
        expect(assigns(:instructor_feedback)).not_to be_nil
      end

      context 'with section_id of zero,' do
        it 'assigns next_activity_link to nil' do
          fake_login(@user)
          do_request('0')
          expect(assigns(:next_activity_link)).to be_nil
        end
      end

      context 'when the user is an instructor' do
        let(:user) { build_stubbed(:instructor) }

        it_behaves_like 'an action that sets up an assignment validator'
      end

      context 'when activity launched from Google classroom is an assessment
        and student is not enrolled in the course' do
        before do
          allow(presenter).to receive(:redirect_to_dashboard?).and_return(true)
          allow(presenter).to receive(:course).and_return(nil)
          allow(@activity).to receive(:assessment?).and_return(true)
          ensure_correct_section(section)
        end

        it 'redirects to the student homepage' do
          fake_login(@user)
          do_request(section.id, @activity.id)
          expect(response).to redirect_to ua_home_path
        end

        it 'displays a message informing that student is not enrolled' do
          fake_login(@user)
          do_request(section.id, @activity.id)
          warning_msg = 'Assessment content is only available for enrolled students.'
          expect(cookies[:ua_home_warning]).to eq(warning_msg)
        end
      end
    end
  end

  describe '#next_activity' do
    context 'when pressing Next Activity button.' do
      let(:activity) { build_stubbed(:activity) }
      let(:classwork) { instance_double(Classwork) }

      before do
        fake_login(@user)
        allow(Classwork).to receive(:new).and_return(classwork)
        allow(activity).to receive(:gradable?).and_return(true)
        allow(scope).to receive(:find).and_return(activity)
      end

      it 'redirects to the next activity when one exists' do
        next_activity = instance_double(Activity, id: 56, title: 'The next Activity')
        workset = instance_double(Workset, next_activity:)
        allow(classwork).to receive(:current_workset).and_return(workset)

        get :next_activity, params: { id: '55', section_id: '0' }
        expect(response).to redirect_to(section_activity_path('0', '56'))
      end

      it 'redirects to the section TOC when the current activity is the last activity' do
        workset = instance_double(Workset, next_activity: 'last_activity')
        allow(classwork).to receive(:current_workset).and_return(workset)
        allow(activity).to receive(:program).and_return 21

        get :next_activity, params: { id: '55', section_id: '0' }
        expect(response).to redirect_to(section_toc_path('0', '21'))
      end

      it 'redirects to the section TOC otherwise.' do
        allow(classwork).to receive(:current_workset)
        allow(activity).to receive(:program).and_return 21

        get :next_activity, params: { id: '55', section_id: '0' }
        expect(response).to redirect_to(section_toc_path('0', '21'))
      end
    end
  end

  describe '#re-try' do
    it_behaves_like 'an action that allows to re-try the activity'
  end

  describe '#submit' do
    it_behaves_like 'an action that submits an activity' do
      it_behaves_like 'an action that ensures access to the activity' do
        let(:user) { build_stubbed(:instructor) }
        let(:message) { 'Sorry, but you cannot access that activity.' }
      end

      it 'assigns the activity return link' do
        allow(@attempt).to receive(:complete?).and_return(false)
        allow(@attempt).to receive(:submission_length).and_return(nil)
        allow(@results).to receive(:complete?).and_return(false)
        session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
        do_request
        expect(assigns(:return_label)).to eq('Somewhere')
        expect(assigns(:return_url)).to eq('/valid/path')
      end

      context 'when the activity is a partner chat' do
        let(:partner) { create(:student) }
        let(:attempt) { create(:attempt, user: partner, activity: @activity) }
        let!(:recording) { create(:partner_chat_recording, user: @user, partner: partner, activity: @activity) }
        let(:content_object) { double('ContentObject', validate_responses: @results, activity_type: 'partner_chat') }
        let(:recording_path) { 'fake/partner/chat/recording/path' }
        let(:token) { 'test-token' }

        before do
          allow(controller).to receive(:require_chat_enabled).and_return(true)
          allow(@activity).to receive(:activity_type).and_return('partner_chat')
          allow(@activity).to receive(:partner_chat?).and_return(true)
          allow(@activity).to receive(:content_object).and_return(content_object)
          allow(presenter).to receive(:partner_chat?).and_return(true)
          allow(attempt).to receive(:write_results)
          allow(attempt).to receive(:submission_length).and_return(100)
          allow(attempt).to receive(:time_spent).and_return(1)
          attempt.scoring_ruleset = ScoringRuleset.default
          allow(@attempt).to receive(:results).and_return(@results)
          allow(Attempt).to receive(:first).and_return(attempt)
          allow(@results.first).to receive(:label)
          allow(@results).to receive(:response).and_return(user_id: @user.id, partner_id: partner.id,
                                                           user_section_id: @section.id, partner_section_id: @section.id,
                                                           recording_path: recording_path, token: token)
          allow(@results).to receive(:set_response)
          @partner_chat_submission = double('partner_chat_submission')
          allow(@partner_chat_submission).to receive(:video_path).and_return('video_path')
          allow(@partner_chat_submission).to receive(:prepare_for_submission)
          allow(@partner_chat_submission).to receive(:results).and_return(@results)
        end

        it 'create partner chat submission object' do
          expect(PartnerChatSubmission).to receive(:new).with(@results, @activity, anything()).and_return(@partner_chat_submission)
          do_request
        end

        it 'call prepare for submisson on partner chat submission object' do
          expect(@partner_chat_submission).to receive(:prepare_for_submission)
          allow(PartnerChatSubmission).to receive(:new).and_return(@partner_chat_submission)
          do_request
        end

        it 'assigns video path and results' do
          allow(PartnerChatSubmission).to receive(:new).and_return(@partner_chat_submission)
          do_request

          expect(assigns(:video_path)).to eq('video_path')
          expect(assigns(:results)).to eq(@results)
        end

        context 'when the attempt is already marked as complete,' do
          it_behaves_like 'an action that validates attempt' do
            describe 'when the activity is a partner chat' do
              it 'creates PartnerChatRecording object from results hash' do
                # This test is strange, but here's the reason for it: By
                # overwriting @results with the results from the attempt
                # object, we get a PartnerChatRecording object built from
                # the results hash.
                recording = double('PartnerChatRecording')
                allow(@attempt).to receive(:stored_responses).and_return(Hash.new)
                expect(@attempt).to receive(:results).and_return(recording)
                allow(presenter).to receive(:partner_chat?).and_return(true)
                do_request
                expect(assigns[:results]).to eq(recording)
              end
            end
          end
        end
      end

      context 'when the activity is a solo video recording' do
        let(:partner) { create(:student) }
        let(:attempt) { create(:attempt, user: partner, activity: @activity) }
        let!(:recording) { create(:partner_chat_recording, user: @user, partner: partner, activity: @activity) }
        let(:content_object) { double('ContentObject', validate_responses: @results, activity_type: 'solo_video_recording') }
        let(:recording_path) { 'fake/solo/recording/path' }
        let(:solo_video_recording_submission) { instance_double(SoloVideoRecordingSubmission, results: @results) }

        before do
          allow(@activity).to receive(:activity_type).and_return('solo_video_recording')
          allow(@activity).to receive(:solo_video_recording?).and_return(true)
          allow(@activity).to receive(:content_object).and_return(content_object)
          allow(presenter).to receive(:solo_video_recording?).and_return(true)
          allow(attempt).to receive(:write_results)
          allow(attempt).to receive(:submission_length).and_return(100)
          allow(attempt).to receive(:time_spent).and_return(1)
          attempt.scoring_ruleset = ScoringRuleset.default
          allow(@attempt).to receive(:results).and_return(@results)
          allow(Attempt).to receive(:first).and_return(attempt)
          allow(@results.first).to receive(:label)
          allow(@results).to receive(:response).and_return(user_id: @user.id,
                                                           user_section_id: @section.id,
                                                           recording_path: recording_path)
          allow(@results).to receive(:set_response)
          allow(solo_video_recording_submission).to receive(:prepare_for_submission)
          allow(solo_video_recording_submission).to receive(:results).and_return(@results)
          allow(presenter).to receive(:solo_video_recording_or_included_in_multipart_activity?).and_return(true)
        end

        it 'assigns video path and results' do
          do_request

          expect(assigns(:video_path)).to eq(recording_path)
          expect(assigns(:results)).to eq(@results)
        end
      end

      context 'when the activity is a group chat recording' do
        let(:partner_1){ create(:student) }
        let(:partner_ids) { [partner_1.id, create(:student).id, create(:student).id] }
        let(:attempt) { create(:attempt, user: partner_1, activity: @activity) }
        let!(:recording) { create(:group_chat_recording, user: @user, participants: partner_ids, activity: @activity) }
        let(:content_object) { instance_double('ContentObject', validate_responses: @results, activity_type: 'group_chat_recording') }
        let(:recording_path) { 'fake/group_chat/recording/path' }
        let(:group_chat_submission) { instance_double(GroupChatSubmission, results: @results) }
        let(:token) { 'test-token' }

        before do
          allow(controller).to receive(:require_chat_enabled).and_return(true)
          allow(@activity).to receive(:activity_type).and_return('group_chat')
          allow(@activity).to receive(:group_chat?).and_return(true)
          allow(@activity).to receive(:content_object).and_return(content_object)
          allow(presenter).to receive(:group_chat?).and_return(true)
          allow(attempt).to receive(:write_results)
          allow(attempt).to receive(:submission_length).and_return(100)
          allow(attempt).to receive(:time_spent).and_return(1)
          attempt.scoring_ruleset = ScoringRuleset.default
          allow(@attempt).to receive(:results).and_return(@results)
          allow(Attempt).to receive(:first).and_return(attempt)
          allow(@results.first).to receive(:label)
          allow(@results).to receive(:response).and_return(user_id: @user.id, partner_ids: partner_ids,
                                                           user_section_id: @section.id, partner_section_id: @section.id,
                                                           recording_path: recording_path, token: token)
          allow(@results).to receive(:set_response)
          @group_chat_submission = double('group_chat_submission')
          allow(@group_chat_submission).to receive(:video_path).and_return('video_path')
          allow(@group_chat_submission).to receive(:prepare_for_submission)
          allow(@group_chat_submission).to receive(:results).and_return(@results)
        end

        it 'creates a group chat submission object' do
          expect(GroupChatSubmission).to receive(:new).with(@results, @activity, anything()).and_return(@group_chat_submission)
          do_request
        end

        it 'calls prepare for submission on group chat submission object' do
          expect(@group_chat_submission).to receive(:prepare_for_submission)
          allow(GroupChatSubmission).to receive(:new).and_return(@group_chat_submission)
          do_request
        end

        it 'assigns video path and results' do
          allow(GroupChatSubmission).to receive(:new).and_return(@group_chat_submission)
          do_request
          expect(assigns(:video_path)).to eq('video_path')
          expect(assigns(:results)).to eq(@results)
        end
      end

      context 'when the attempt is already marked as complete,' do
        it_behaves_like 'an action that validates attempt' do
          describe 'when the activity is a solo video recording' do
            it 'creates SoloVideoRecording object from results hash' do
              recording = instance_double(SoloVideoRecording)
              allow(@attempt).to receive(:stored_responses).and_return(Hash.new)
              expect(@attempt).to receive(:results).and_return(recording)
              allow(presenter).to receive(:solo_video_recording_or_included_in_multipart_activity?).and_return(true)
              do_request
              expect(assigns[:results]).to eq(recording)
            end
          end
        end
      end
    end
  end

  describe '#submit_nongradable' do
    let(:activity) { build_stubbed(:activity) }
    let(:submission) { double('Submission', submit_nongradable: true) }
    let(:section) { build_stubbed(:section) }

    before do
      fake_login(@user)
      allow(Activity).to receive(:find).and_return(activity)
      allow(scope).to receive(:find).and_return(activity)
      allow(Gradebook::Submission).to receive(:new).and_return(submission)
      allow(Attempt).to receive(:create_completed)
      allow(controller).to receive(:current_user).and_return(@user)
      allow(controller).to receive(:current_section).and_return(section)
    end

    it 'creates a submission for a non-gradable activity' do
      expect(submission).to receive(:submit_nongradable)
      post 'submit_nongradable', params: { id: activity.id, section_id: section.id }
    end

    it 'marks the attempt record as completed' do
      expect(Attempt).to receive(:create_completed).with(@user, activity, section)
      post 'submit_nongradable', params: { id: activity.id, section_id: section.id }
    end

    it 'calls the gradepassback with the new attempt if the student is a cartridge one' do
      attempt = instance_double(Attempt)
      grade_passback_obj = instance_double(Cartridge::GradePassback, process: nil)
      cartridge_consumer_guid = 'school_cartridge_guid'
      session[:cartridge] = { 'consumer_guid' => cartridge_consumer_guid }
      allow(@user).to receive(:cartridge?).and_return(true)
      allow(Attempt).to receive(:create_completed)
        .with(@user, activity, section)
        .and_return(attempt)
      allow(Cartridge::GradePassback).to receive(:new)
        .with(@user, attempt, { consumer_guid: cartridge_consumer_guid })
        .and_return(grade_passback_obj)
      post 'submit_nongradable', params: { id: activity.id, section_id: section.id }
      expect(grade_passback_obj).to have_received(:process)
    end
  end

  describe '#practice' do
    it_behaves_like 'an action that start practice mode' do
      context 'when the activity is a santillana book,' do
        let(:iframe_src) { 'iframe_src' }
        let(:content_object) do
          instance_double(
            MaestroActivityEngine::ActivityContent::SmartBookContent,
            activity_type: 'smart_book'
          )
        end
        let(:lossless_policy_token) { SecureRandom.uuid }
        let(:lossless_policy) do
          instance_double(Lossless::Policy, token: lossless_policy_token)
        end
        let(:basic_auth_credentials) { 'basic_auth_credentials' }
        let(:xapi_mbox) { 'xapi_mbox' }
        let(:xapi_user_token) { instance_double(XapiUserToken, mbox: xapi_mbox) }

        def do_request
          get :practice, params: { id: '55', section_id: '0' }
        end

        before do
          allow(@activity).to receive(:activity_type).and_return('smart_book')
          allow(@activity).to receive(:santillana?).and_return(true)
          allow(@activity).to receive(:ai_virtual_chat?).and_return(false)
          allow(@activity).to receive(:content_object).and_return(content_object)
          allow(@attempt).to receive(:id).and_return(1234)
          allow(Xapi::BasicAuthCredential).to receive(:generate_credentials)
            .with(@user).and_return(basic_auth_credentials)
          allow(XapiUserToken).to receive(:new).and_return(xapi_user_token)
          allow(content_object).to receive(:iframe_src).and_return(iframe_src)
          allow(Lossless::Policy).to receive(:new).and_return(lossless_policy)

          fake_login(@user)
        end

        it 'displays the show view and display a practice flash notice' do
          do_request

          expect(response).to render_template(:show)
          expect(flash[:notice]).to eq('Practice mode. Answers will not be saved!')
        end

        it 'generate a lossless policy token' do
          do_request

          expect(assigns(:lossless_auth_token)).to eq(lossless_policy_token)
        end

        it 'assigns the iframe src with unlimited number of attempts' do
          do_request

          expect(content_object).to have_received(:iframe_src).with(
            activity_id: 55,
            auth: basic_auth_credentials,
            max_attempts: -1,
            mbox: xapi_mbox,
            role: MaestroActivityEngine::ActivityContent::SmartBookContent::STUDENT_ROLE,
            request: anything
          )
          expect(assigns(:iframe_src)).to eq(iframe_src)
        end

        it 'makes Xapi mbox non modifiable' do
          do_request

          expect(XapiUserToken).to have_received(:new).with(
            attempt_id: @attempt.id,
            user_id: @user.id,
            state_modifiable: false
          )
        end
      end
    end
  end

  describe '#answer_key' do
    it_behaves_like 'an action that shows answer key' do
      let!(:instructor) { build_stubbed(:instructor) }
    end
  end

  describe '#finalize' do
    it_behaves_like 'an action to finalize the activity' do
      let(:expected_path) { section_activity_path('0', '55') }

      it_behaves_like 'an action that ensures access to the activity' do
        let(:user) { build_stubbed(:instructor) }
        let(:message) { 'Sorry, but you cannot access that activity.' }
      end
    end
  end

  describe '#save' do
    it_behaves_like 'an action that saves the activity' do
      let(:student) { build_stubbed(:student) }
    end
  end

  describe '#popup' do
    before do
      @program = build_stubbed(:program)
      @section = build_stubbed(:section)
      @strand = build_stubbed(:toc_entry)
      @lesson = build_stubbed(:lesson)
      allow(@lesson).to receive(:strand_for_toc_location).and_return(@strand)
      allow(@lesson).to receive(:substrand_for_toc_location).and_return(@strand)
      allow(@lesson).to receive(:display_name).and_return('Lesson 1')
      @activity = double(
        'Activity',
        :read_only= => nil,
        activity_type: activity_type,
        cms_activity_id: 1234,
        cms_revision_id: 222,
        composition?: false,
        content_object: mock_content_object,
        gradable: false,
        id: 55,
        lesson: @lesson,
        listed?: false,
        partner_chat?: false,
        program: @program,
        question_bank?: false,
        title: 'A Doubled Activity',
        toc_location: @strand.id,
        assessment?: false
      )
      allow(@activity).to receive(:list_header).and_return('lesson foo / strand bar')
      allow(@activity).to receive(:vtext_link=)

      notification_scope = double('Notification')
      allow(notification_scope).to receive(:by_user_and_section).and_return(double('Notification', dismiss_all!: ''))
      allow(@activity).to receive(:notifications).and_return(notification_scope)
      allow(@activity).to receive(:ensure_correct_version)
      allow(@activity).to receive(:gradable?).and_return(false)
      allow(@activity).to receive(:santillana?).and_return(false)
      allow(@activity).to receive(:ai_virtual_chat?).and_return(false)
      content_object = mock_content_object

      @params = { id: @activity.cms_activity_id, section_id: @section.id }

      allow(Activity).to receive(:find_by_cms_activity_id_in_program).and_return(@activity)
      allow(controller).to receive(:current_section_id).and_return(@section.id)

      attempt = build_stubbed(:attempt, cms_revision_id: 222)
      allow(attempt).to receive(:attempt_track).and_return(double(AttemptTrack, max: 1))
      allow(attempt).to receive(:activity=)
      @classwork = double(Classwork)
      allow(@classwork).to receive(:find_or_new_attempt).with(@activity).and_return(attempt)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      allow(Classwork).to receive(:new).and_return(@classwork)
      allow(@controller).to receive(:in_section?).and_return(false)
      fake_login(@user)
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:find_or_create_attempt).and_return(attempt)
      allow(presenter).to receive(:study_plan_practice=)
      allow(controller).to receive(:require_program_access).and_return(true)
      allow(controller).to receive(:ensure_correct_section)
      allow(controller).to receive(:current_section).and_return(@section)

      student_grade = instance_double(GradebookEngine::AssignmentGrade,
                                      submitted?: true,
                                      adjusted?: false)
      allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade)
        .and_return(student_grade)
    end

    def do_request(params = {})
      get :popup, params: @params.merge(params)
    end

    it_behaves_like 'an action that finds and assigns activity by cms_activity_id'
    it_behaves_like 'an action that assigns an activity presenter' do
      before do
        allow(@user).to receive(:instructor?).and_return(false)
      end
    end
    it_behaves_like 'an action that assigns video settings from the presenter'

    it_behaves_like 'an action that requires the program access'
    it_behaves_like 'an action that ensures the correct section'

    it 'should replace the id passed into params by the id found by cms_activity_id' do
      allow(controller).to receive(:render).and_call_original
      expect(controller).to receive(:show_activity).with(hash_including('id' => @activity.id), 'layouts/activity_popup').and_call_original
      get :popup, params: @params
    end

    it 'assigns true to show_vocab_footer if the activity is a vocab list' do
      allow(@activity.content_object).to receive(:vocablist_content?).and_return(true)
      get :popup, params: @params
      expect(assigns(:show_vocab_footer)).to be_truthy
    end

    it 'assigns false to show_vocab_footer if the activity is not a vocab list' do
      allow(@activity.content_object).to receive(:vocablist_content?).and_return(false)
      get :popup, params: @params
      expect(assigns(:show_vocab_footer)).to be_falsey
    end

    it 'should assign @no_activity_footer' do
      get :popup, params: @params
      expect(assigns(:no_activity_footer)).to eq(true)
    end

    it 'should assign true to is_popup' do
      get :popup, params: @params
      expect(assigns(:is_popup)).to be_truthy
    end

    it 'should use the popup layout' do
      get :popup, params: @params
      expect(response).to render_template('layouts/activity_popup')
    end

    it 'should render show' do
      get :popup, params: @params
      expect(response).to render_template(:show)
    end
  end

  describe '#popup_submit' do
    before do
      @activity = double(
        'Activity',
        id: 999,
        content_object: mock_content_object,
        lesson: double(Lesson),
        cms_activity_id: 1234,
        composition?: false,
        partner_chat?: false,
        question_bank?: false,
        title: 'A Doubled Activity',
        listed?: false,
        assessment?: false
      )
      allow(@activity).to receive(:ensure_correct_version)
      allow(scope).to receive(:find).and_return(@activity)
      allow(Activity).to receive(:find_by_cms_activity_id_in_program).and_return(@activity)
      allow(@activity).to receive(:vtext_link=)
      allow(controller).to receive(:current_section_id).and_return(section.id)
      @params = {}

      @user = build_stubbed(:student)
      fake_login(@user)
      allow(controller).to receive(:current_section).and_return(section)
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
      allow(controller).to receive(:submit)
      allow(controller).to receive(:render)
    end

    def do_request(params = {})
      default_params = { section_id: 1, id: @activity.cms_activity_id.to_s }
      post :popup_submit, params: default_params.merge(params)
    end

    it 'calls submit, specifying the popup layout' do
      expect(controller).to receive(:submit).with('layouts/activity_popup')
      do_request
    end

    it 'assigns true to is_popup' do
      allow(controller).to receive(:submit)
      do_request
      expect(assigns(:is_popup)).to be_truthy
      @user = build_stubbed(:student)
      fake_login(@user)
      @attempt = build_stubbed(:attempt)
      allow(@attempt).to receive(:complete?).and_return(true)
      allow(@attempt).to receive(:validate_responses).and_return(nil)
      allow(controller).to receive(:current_section).and_return(@section)
      student_activity_presenter = double('StudentActivityPresenter', activity: @activity,
                                                                      lesson_header: 'Leccion 1')
      allow(student_activity_presenter).to receive(:activity_list_header).and_return('Leccion 1 | Adelante | Lectura')
      allow(StudentActivityPresenter).to receive(:new).and_return(student_activity_presenter)
    end

    it_behaves_like 'an action that finds and assigns activity by cms_activity_id'
    it_behaves_like 'an action that assigns an activity presenter' do
      before do
        allow(@user).to receive(:instructor?).and_return(false)
      end
    end
    it_behaves_like 'an action that assigns video settings from the presenter'
  end

  describe '#swf' do
    before do
      include FakeFS::SpecHelpers
      fake_login
      player_path = File.join('public', 'players', 'valid_swf.swf')
      File.open(player_path, 'wb') { |file| file.write('abcd') }
      get 'swf', params: { section_id: 1, swf: 'valid_swf.swf' }
    end

    it 'should render with no layout' do
      expect(response).to render_template(layout: false)
    end

    it 'sets the correct content type' do
      expect(response.content_type).to eq(
        'application/x-shockwave-flash; charset=utf-8'
      )
    end

    it 'should assign the specified swf file from the public players directory' do
      expect(assigns(:swf_file).read).to eq('abcd')
    end
  end

  describe '#image' do
    it 'redirects to the location of the file in the media S3 bucket' do
      fake_login
      expected_image = 'spec_image.jpg'
      get :image, params: { section_id: 1, image: expected_image }
      expect(response).to redirect_to "#{MediaItem::CDN_URL_PREFIX}/zip_contents/#{expected_image}"
    end
  end

  describe '#vocab_tutorial_iframe' do
    let(:program) { build_stubbed(:program) }
    let(:activity) { build_stubbed(:activity) }
    let(:content_object) { double('ActivityContent', populate_dirs_from_media: nil) }

    before do
      allow(scope).to receive(:find).and_return(activity)
      allow(activity).to receive(:program).and_return(program)
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(activity).to receive(:vtext_link=)
      allow(controller).to receive(:current_user).and_return(@user)
      fake_login
    end

    def do_request
      get :vocab_tutorial_iframe, params: { id: activity.id.to_s, rails_env: 'test', media_type: 'vocab_tutorial', id_part1: '1234', id_part2: '4567' }
    end

    it 'finds and assigns the activity specified by id' do
      expect(scope).to receive(:find).with(activity.id.to_s).and_return(activity)
      do_request
      expect(assigns(:activity)).to eq(activity)
    end

    it "assigns the activity's program" do
      do_request
      expect(assigns(:current_program)).to eq(program)
    end
  end

  describe '#recording' do
    context 'for standard ARC activities' do
      before do
        @user = build_stubbed(:student)
        fake_login(@user)

        style = double(MaestroActivityEngine::ActivityContent::Recording::Style, layout: 'sentence')
        @content_object = double(MaestroActivityEngine::ActivityContent::Content, questions: Array.new, style: style, model: nil)
        @recording_activity = double(Activity, save: nil, content: '<activity activity_type="recording"></activity>', content_object: @content_object)
        attempt = build_stubbed(:attempt)
        classwork = double('Classwork', find_or_new_attempt: attempt)
        allow(Classwork).to receive(:new).and_return(classwork)
        allow(scope).to receive(:find).with('1').and_return(@recording_activity)
        allow(Activity).to receive(:find).with('1').and_return(@recording_activity)
        allow(@recording_activity).to receive(:content_object).and_return(@content_object)
        get 'recording', params: { id: 1, section_id: 1 }
      end

      it 'should render with no layout' do
        expect(response).to render_template(layout: false)
      end

      it 'should assign activity content as xml' do
        expect(assigns(:activity).content).to eq(@recording_activity.content)
        expect(assigns(:questions)).to        eq(@content_object.questions)
        expect(assigns(:style)).to            eq(@content_object.style)
        expect(response).to render_template('activities/data/recording')
      end
    end

    context 'for composition activities' do
      before do
        @user = build_stubbed(:student)
        fake_login(@user)

        style = double(MaestroActivityEngine::ActivityContent::Recording::Style, layout: 'sentence')
        @content_object = double(MaestroActivityEngine::ActivityContent::CompositionRecordingContent, questions: [], items: Array.new, style: style, model: nil)
        @recording_activity = double(Activity, save: nil, content: '<activity activity_type="composition_recording"></activity>', content_object: @content_object)
        attempt = build_stubbed(:attempt)
        classwork = double('Classwork', find_or_new_attempt: attempt)
        allow(Classwork).to receive(:new).and_return(classwork)
        allow(scope).to receive(:find).with('1').and_return(@recording_activity)
        allow(Activity).to receive(:find).with('1').and_return(@recording_activity)
        allow(@recording_activity).to receive(:content_object).and_return(@content_object)
        get 'recording', params: { id: 1, section_id: 1 }
      end

      it 'should set @questions' do
        expect(assigns(:questions)).to eq(@content_object.items)
      end
    end
  end

  describe '#update_time_spent' do
    before do
      @program = build_stubbed(:program)
      @activity = double(
        'Activity',
        :read_only= => nil,
        activity_type: activity_type,
        composition?: false,
        content_object: mock_content_object,
        id: 55,
        lesson: double(Lesson),
        listed?: false,
        partner_chat?: false,
        program: @program,
        question_bank?: false,
        title: 'A Doubled Activity',
        assessment?: false
      )
      allow(@activity.content_object).to receive(:external_references).and_return([])
      allow(@activity).to receive(:gradable?).and_return(true)
      allow(@activity).to receive(:vtext_link=)
      allow(scope).to receive(:find).and_return(@activity)
      @attempt = create(:attempt)
      allow(@classwork).to receive(:find_or_new_attempt).and_return(@attempt)
      allow(@classwork).to receive(:current_workset)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      @start_time = '1234567890'
      allow(@attempt).to receive(:add_time_spent)
      allow(@attempt).to receive(:propagate_time_spent_to_score)

      fake_login(@user)
      allow(@controller).to receive(:time_now_in_seconds).and_return(1234567890)
      allow(@controller).to receive(:in_section?).and_return(false)
      allow(controller).to receive(:current_section)
        .and_return(build_stubbed(:section))

      student_grade = instance_double(GradebookEngine::AssignmentGrade,
                                      submitted?: true,
                                      adjusted?: false)
      allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade)
        .and_return(student_grade)
    end

    def do_request
      post 'update_time_spent', params: { section_id: 1, id: 10, start_time: @start_time }
    end

    context 'when the activity is a smart_book activity' do
      let(:activity_type) { 'smart_book' }

      before do
        allow(Xapi::StatementWriter).to receive(:update_time_tracking)
      end

      it 'finds the current attempt or creates a new one' do
        do_request
        expect(@classwork).to have_received(:find_or_new_attempt).with(@activity)
      end

      it 'calls Xapi::StatementWriter.update_time_tracking' do
        do_request
        expect(Xapi::StatementWriter).to have_received(:update_time_tracking).with(
          :pause, @attempt, @user, true
        )
      end

      it 'sets the correct content type' do
        do_request
        expect(response.content_type).to eq('text/html')
      end

      it 'propagates the time spent update to the score' do
        do_request
        expect(@attempt).to have_received(:propagate_time_spent_to_score)
      end
    end

    context 'when the activity is not a smart_book activity' do
      it_behaves_like 'an action that handles timespent error cases'

      it 'should find the current attempt or create a new one' do
        expect(@classwork).to receive(:find_or_new_attempt).with(@activity)
        do_request
      end

      it 'should update the attempt record with the time spent' do
        now = 1234567899
        allow(@controller).to receive(:time_now_in_seconds).and_return(now)

        expect(@attempt).to receive(:add_time_spent).with(@start_time.to_i, now)
        do_request
      end

      it 'sets the correct content type' do
        do_request
        expect(response.content_type).to eq('text/html')
      end

      it 'propagates the time spent update to the score' do
        do_request
        expect(@attempt).to have_received(:propagate_time_spent_to_score)
      end
    end
  end

  describe 'smartbook_resume_time_tracking' do
    let(:program) { build_stubbed(:program) }
    let(:activity) do
      double(
        'Activity',
        id: 55,
        content_object: mock_content_object,
        :read_only= => nil,
        program: program,
        lesson: double(Lesson),
        :composition? => false,
        :partner_chat? => false,
        :listed? => false,
        title: 'A Doubled Activity',
        activity_type: 'smart_book'
      )
    end
    let(:attempt) { create(:attempt) }

    before do
      allow(activity).to receive(:vtext_link=)
      allow(scope).to receive(:find).and_return(activity)
      allow(Activity).to receive(:find).and_return(activity)
      allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)
      allow(@classwork).to receive(:current_workset)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      allow(controller).to receive(:current_section)
        .and_return(build_stubbed(:section))
      fake_login(@user)
    end

    def do_request
      get 'smartbook_resume_time_tracking', params: { section_id: 1, id: 10  }
    end

    before do
      allow(Xapi::StatementWriter).to receive(:update_time_tracking)
    end

    it 'calls Xapi::StatementWriter.smartbook_resume_time_tracking' do
      do_request
      expect(Xapi::StatementWriter).to have_received(:update_time_tracking)
        .with(:resume, attempt, @user, true)
    end
  end

  describe '#permalink' do
    let(:lesson) { create(:lesson_with_unit) }
    let!(:activity) { create(:activity, lesson: lesson) }

    before do
      allow(Activity).to receive(:unscoped).and_call_original
    end

    context 'when the user is a student' do
      let(:student) { create(:student) }

      before do
        fake_login(student)
        allow(student).to receive(:has_current_access_to?).and_return(true)
      end

      it 'redirects the student to the correct url if they are in an active section for this program' do
        program = activity.program
        course = create(:course, program: program)
        section = create(:section, course: course)
        student.enrollments.create! section: section, state: 'enrolled'
        get :permalink, params: { id: activity.id }
        expect(response).to redirect_to(popup_section_activity_path(section, activity.cms_activity_id, program_id: activity.program))
      end

      it 'redirects the student to a section zero url if the are not in an active section' do
        get :permalink, params: { id: activity.id }
        expect(response).to redirect_to(popup_section_activity_path(0, activity.cms_activity_id, program_id: activity.program))
      end

      context 'when it is a chat-type activity' do
        let(:school) { create(:school) }
        let(:program) { activity.program }
        let(:course) { create(:course, program: program, school: school) }
        let(:section) { create(:section, course: course) }

        before do
          allow(controller).to receive(:chat_activity?).and_return(true)
          student.enrollments.create!(section: section, state: 'enrolled')
        end

        it 'does not redirect to the correct URL and shows an error message, '\
          'when chat support is disabled at the course level' do
          course.update!(chat_level: 'disabled')
          get :permalink, params: { id: activity.id }

          expect(response).not_to redirect_to(popup_section_activity_path(section, activity.cms_activity_id, program_id: program))
          expect(flash[:error]).to eq('Your instructor has disabled chat for this course')
        end

        it 'does not redirect to the correct URL and shows an error message, '\
          'when chat support is disabled at the school level' do
          create(:school_config, school: school, chat_support_disabled: true)
          get :permalink, params: { id: activity.id }

          expect(response).not_to redirect_to(popup_section_activity_path(section, activity.cms_activity_id, program_id: program))
          expect(flash[:error]).to eq('Your institution has disabled chat support.')
        end

        it 'redirects the student to the correct URL, when chat support is enabled' do
          get :permalink, params: { id: activity.id }

          expect(response).to redirect_to(popup_section_activity_path(section, activity.cms_activity_id, program_id: program))
        end
      end
    end

    context 'when the user is an instructor' do
      let(:instructor) { create(:instructor) }

      before do
        fake_login(instructor)
        allow(instructor).to receive(:has_current_access_to?).and_return(true)
      end

      it 'redirects the instructor to the correct url' do
        get :permalink, params: { id: activity.id }
        expect(response).to redirect_to(popup_section_activity_path(0, activity.cms_activity_id, program_id: activity.program))
      end
    end
  end
end

describe ActivitiesController, 'student_and_completed_activity?' do
  # interactions between the real ActivitiesController and the anonymous
  # controller used in this test make it necessary to define this test class
  # otherwise these 4 specs will fail if run after any other spec in this file.
  class TestActivitiesController < ActivitiesController
  end

  controller(TestActivitiesController) do
    skip_before_action :require_user, :ensure_can_access_activity, only: :index

    def index
      if params[:id]
        @activity = Activity.find(params[:id])
        assign_activity_presenter
      end

      @results = student_and_completed_activity?

      render plain: 'empty method'
    end
  end

  it 'is false if current user is not a student' do
    allow(controller).to receive(:current_user).and_return(build(:instructor))

    get :index, params: { practice: 'true' }

    expect(assigns(:results)).to be false
  end

  context 'with a student,' do
    let(:student) { create(:student) }

    before do
      allow(controller).to receive(:current_user).and_return(student)
    end

    it 'is false if practice param is set to true' do
      get :index, params: { practice: 'true' }
      expect(assigns(:results)).to be false
    end

    context 'when practice param is not set to true,' do
      let(:activity) { create(:activity) }
      let(:section) { create(:section) }

      def create_attempt(attrs = {})
        default_attrs = {
          activity_id: activity.id,
          section_id: section.id,
          status_code: AttemptStatus::CODE_COMPLETED,
          user_id: student.id
        }
        create(:attempt, default_attrs.merge(attrs))
      end

      before do
        allow(controller).to receive(:current_section_id).and_return(section.id)
      end

      it 'is false when no completed attempt exists for the current user, ' \
       'section, and activity' do
        other_activity = create(:activity)
        other_section = create(:section)
        other_user = create(:student)
        create_attempt(activity_id: other_activity.id)
        create_attempt(section_id: other_section.id)
        create_attempt(user_id: other_user.id)
        create_attempt(status_code: AttemptStatus::CODE_OPENED)

        get :index, params: { id: activity.id, practice: 'false' }

        expect(assigns(:results)).to be false
      end

      it 'is true when a completed attempt exists for the current user, ' \
         'section, and activity' do
        create_attempt(
          activity_id: activity.id,
          section_id: section.id,
          status_code: AttemptStatus::CODE_COMPLETED,
          user_id: student.id
        )

        get :index, params: { id: activity.id, practice: 'false' }

        expect(assigns(:results)).to be true
      end
    end
  end
end

describe ActivitiesController, 'ensure_can_access_activity_filter' do
  RSpec.shared_examples 'common no redirect cases' do
    it 'does not redirect if user is not a student' do
      allow(user).to receive(:student?).and_return(false)
      get :index
      expect(response).not_to be_redirect
    end

    it 'does not redirect if user is student and activity is not listed' do
      allow(activity).to receive(:listed?).and_return(false)
      get :index
      expect(response).not_to be_redirect
    end

    it 'does not redirect if user is student and activity is listed and has activity access' do
      allow(activity).to receive(:listed?).and_return(true)
      allow(access_guardian).to receive(:can_access_content?).and_return(true)
      get :index
      expect(response).not_to be_redirect
    end
  end

  controller(ActivitiesController) do
    skip_before_action *_process_action_callbacks.map { |callback| callback.filter if callback.kind == :before }.compact
    before_action :activity_setup
    before_action :ensure_can_access_activity

    def index
      render plain: 'empty method'
    end

    private def activity_setup
      @activity = Activity.first
    end

    private def current_user
      @current_user ||= User.first
    end

    private def access_guardian
      @access_guardian ||= AccessGuardian.new
    end
  end

  let(:user) { create(:student) }
  let(:activity) { create(:activity) }
  let(:access_guardian) { instance_double(AccessGuardian) }

  before do
    allow(Activity).to receive(:first).and_return(activity)
    allow(AccessGuardian).to receive(:new).and_return(access_guardian)
  end

  context 'with a regular student' do
    let(:expected_url_redirect) { 'expected_url_redirect' }

    before do
      allow(User).to receive(:first).and_return(user)
      allow(BestDefaultPath).to receive(:best_default_path).and_return(expected_url_redirect)
    end

    include_examples 'common no redirect cases'

    it 'redirects if the user is student and activity is listed and has no activity access' do
      allow(activity).to receive(:listed?).and_return(true)
      allow(access_guardian).to receive(:can_access_content?).and_return(false)
      get :index
      expect(response).to redirect_to(expected_url_redirect)
    end
  end

  context 'with a cartridge student' do
    before do
      allow(User).to receive(:first).and_return(user)
      allow(user).to receive(:cartridge?).and_return(true)
    end

    include_examples 'common no redirect cases'

    it 'redirects if the user is student and activity is listed and has no activity access' do
      allow(activity).to receive(:listed?).and_return(true)
      allow(access_guardian).to receive(:can_access_content?).and_return(false)
      get :index
      expect(response).to redirect_to(cartridge_access_denied_path(activity.id))
    end
  end
end
