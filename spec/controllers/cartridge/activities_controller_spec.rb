describe Cartridge::ActivitiesController, core: true, type: :controller do
  let(:activity_type) { 'fill_in_the_blanks'.freeze }
  let(:score) { instance_double(GradebookEngine::ScoreAction) }
  let(:scope) { double('Scope') }

  def mock_content_object
    wol_format = 'question <input type="text"id="55"size="20"/>'
    allow(MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item).to receive(:format_wol_as_input).with(1, 'question <wol ref="55"/> prompt').and_return(wol_format)
    item = double(MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item, prompt: 'question <wol ref="55"/> prompt', prompt_id: 1)
    allow(item).to receive(:label).with(0).and_return('question_01')
    items = [item]
    double(MaestroActivityEngine::ActivityContent::FillInTheBlanksContent, class: MaestroActivityEngine::ActivityContent::FillInTheBlanksContent, items: items,
                                                                           style: nil, max_attempts: nil, activity_type: 'fill_in_the_blanks',
                                                                           vocablist_content?: false, audio_reference_media_item: nil, grading_method: nil, content_summary: nil,
                                                                           submittable?: true, points_possible: 1)
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
                                     group_chat?: false,
                                     solo_video_recording?: false,
                                     :activity_in_study_plan= => false,
                                     solo_video_recording_or_included_in_multipart_activity?: false )
  end

  let(:access_guardian) do
    double('AccessGuardian',
           can_access_content?: true,
           has_grace_period?: false,
           has_mobile_app?: false)
  end

  before do
    allow(Activity).to receive(:unscoped).and_return(scope)
    allow(Maestro::User).to receive(:accessible_programs).and_return([double('AccessibleProgram', id: 1)])
    allow(controller).to receive(:access_guardian).and_return(access_guardian)
    @user = create(:cartridge_student_user_link).user
    @classwork = instance_double(Classwork)
    allow(Classwork).to receive(:new).and_return(@classwork)
    attempt = build_stubbed(:attempt)
    allow(attempt).to receive(:activity=)
    allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)
    allow(presenter.notifications).to receive(:dismiss_all!)

    student_grade = instance_double(
      GradebookEngine::AssignmentGrade,
      adjusted?: false,
      submitted?: true
    )
    allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade)
      .and_return(student_grade)
  end

  it_should_have_help

  it_behaves_like 'an action that prevents access to a blocked enrollment' do
    let(:student) { create(:cartridge_student_user_link).user }
  end

  describe '#show' do
    it_behaves_like 'an action that shows an activity' do
      let(:instructor_user) { build_stubbed(:cartridge_instructor_user_link).user }

      context 'when activity is an assessment and has not been released' do
        it_behaves_like 'an action that informs the assessment is not available'
      end

      context 'given a student who is enrolled in a section for the current activity program,' do
        let(:active_section) { build_stubbed(:section_with_course) }

        before do
          allow(@user).to receive(:current_section_in_program).and_return( active_section )
        end

        it_behaves_like 'an action that renders the show view'
      end

      context 'when the user is an instructor' do
        let(:user) { build_stubbed(:cartridge_instructor_user_link).user }

        before do
          allow(user).to receive(:cartridge?).and_return( true )
        end

        it_behaves_like 'an action that sets up an assignment validator'
      end
    end
  end

  describe '#re-try' do
    it_behaves_like 'an action that allows to re-try the activity'
  end

  describe '#submit' do
    it_behaves_like 'an action that submits an activity' do
      it_behaves_like 'an action that ensures access to the activity' do
        let(:user) { build_stubbed(:cartridge_instructor_user_link).user }
        let(:message) { 'Sorry, but you do not have access to this item. %s' }
      end

      context 'when the attempt is already marked as complete,' do
        it_behaves_like 'an action that validates attempt'
      end
    end
  end

  describe '#practice' do
    it_behaves_like 'an action that start practice mode'
  end

  describe '#answer_key' do
    it_behaves_like 'an action that shows answer key' do
      let!(:instructor) { build_stubbed(:cartridge_instructor_user_link).user }
    end
  end

  describe '#finalize' do
    it_behaves_like 'an action to finalize the activity' do
      let(:expected_path) { cartridge_section_activity_path('0', '55') }

      it_behaves_like 'an action that ensures access to the activity' do
        let(:user) { build_stubbed(:cartridge_instructor_user_link).user }
        let(:message) { 'Sorry, but you do not have access to this item. %s' }

        before do
          allow(user).to receive(:cartridge?).and_return( true )
        end
      end
    end
  end

  describe '#save' do
    it_behaves_like 'an action that saves the activity' do
      let(:student) { build_stubbed(:student) }
    end
  end
end
