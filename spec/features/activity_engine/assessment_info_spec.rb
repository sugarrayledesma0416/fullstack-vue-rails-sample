feature 'Assessment Info and Connectivity Test', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:assessment_strand) { create(:toc_entry) }
  let(:course) do
    create(
      :course,
      owner: instructor,
      program:,
      allows_help_requests: true,
      allows_review_requests: true
    )
  end
  let(:section) { create(:section, course:, instructor:) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [assessment_strand], unit:) }
  let(:activity) do
    create(:json_assessment_for_assessment_info, title: 'Mid-Unit Assessment', lesson:)
  end

  let(:category) { create(:category, course:, penalty_percent: 0) }
  let!(:assignment) do
    create(
      :assignment,
      assignable: activity,
      category:,
      due_date: Date.tomorrow,
      section:,
      show_at: 1.day.ago
    ).tap do |assignment|
      create_assigned_assessment(
        assignment,
        time_limit: 60,
        number_of_attempts: 2,
        password: 'password'
      )
    end
  end

  def assignment_rules
    msg = {
      accents: 'Extra or missing accent marks',
      capitalization: 'Incorrect capitalization',
      punctuation: 'Punctuation errors'
    }
    msg_suffix = 'affect your score.'

    assignment.scoring_ruleset.respected_features_list.map do |rule|
      format_rule_text(rule, msg, msg_suffix)
    end
  end

  def format_rule_text(rule, msg, msg_suffix)
    "#{msg[rule[:text].to_sym]} #{rule['status'] ? 'WILL NOT' : 'WILL'} #{msg_suffix}"
  end

  def create_assigned_assessment(assignment, attrs = {})
    create(
      :assigned_assessment_detail,
      assignment:,
      time_limit: attrs[:time_limit],
      number_of_attempts: attrs[:number_of_attempts],
      password: attrs[:password]
    )
  end

  scenario 'As a student I can validate the "Assessment Info" and "Connectivity Test" screens' do
    allow(Activity).to receive_message_chain(
      :unscoped,
      :find
    ).with(activity.id.to_s).and_return(activity)
    allow(activity).to receive(:assessment?).and_return(true)
    allow(activity).to receive(:icon).and_return('solo_video_recording')
    create(:enrollment, user: student, section:)
    give_user_access_to_program(student, program)
    log_in_as(student)
    visit section_activity_path(section_id: section.id, id: activity.id)

    step 'I can see the password screen.' do
      expect(page).to have_selector(
        '.test-enter-password-info',
        text: 'Enter the password required to begin this assessment.'
      )
    end

    step 'Enter the password' do
      fill_in('assessment_password', with: 'password')
    end

    step 'Click on "Continue"' do
      find('.test-password-continue').click
    end

    step 'I do not see the password screen' do
      expect(page).not_to have_selector('.test-enter-password-info')
    end

    step 'I can see the assessment time limit information' do
      expect(page).to have_selector('.test-assessment-info-timed')
    end

    step 'I can see the correct assessment time limit' do
      expect(page).to have_selector(
        '.test-assessment-info-bold',
        text: 'You have 1 hour to complete this assessment.'
      )
    end

    step 'I can see the total number of questions correctly' do
      expect(page).to have_selector(
        '.test-total-question-info',
        text: 'This assessment has 2 Questions'
      )
    end

    step 'I can see the details of questions correctly' do
      questions = all('.test-question-info-text')
      expect(questions.map(&:text)).to eq(
        ['1 Open ended', '1 Video Recording']
      )
    end

    step 'I can see the list of requirements correctly' do
      requirements = all('.test-requirement-list-item')
      expect(requirements.map(&:text)).to eq(
        ['Listening', 'Speaking', 'Video Recording']
      )
    end

    step 'I can see the list of requirements correctly' do
      rules = all('.test-strictness-list-item')
      expect(rules.map(&:text)).to eq(
        assignment_rules
      )
    end

    step 'I can see the "Test Connection" button' do
      expect(page).to have_selector(
        '.test-pre-test-connection',
        text: 'Test Connection'
      )
    end

    step 'Click the "Test Connection" button' do
      find('.test-pre-test-connection').click
    end

    step 'I can see the "Connectivity Test" dialog' do
      expect(page).to have_selector(
        '.test-dialog-box .test-dialog-heading',
        text: 'Connectivity Test'
      )
    end

    step 'I can see the "Internet Connection" step' do
      expect(page).to have_selector(
        '.test-progress-level-title',
        text: 'Internet Connection'
      )
    end

    step 'I can see the "Test Connection" result message' do
      expect(page).to have_selector(
        '.test-result-message-text',
        text: 'Test failed due to technical reasons.'
      )
    end

    step 'I can see the audio quality as "Not Available"' do
      expect(page).to have_selector(
        '.test-result-stats-audio-body',
        text: 'Not Available'
      )
    end

    step 'I can see the video quality as "Not Available"' do
      expect(page).to have_selector(
        '.test-result-stats-video-body',
        text: 'Not Available'
      )
    end

    step 'I can see the "Re-test" button' do
      expect(page).to have_selector(
        '.test-pretest-again-btn',
        text: 'Re-test'
      )
    end

    step 'I can see the "Begin Assessment" button' do
      expect(page).to have_selector(
        '.test-begin-assessment-btn',
        text: 'Begin Assessment'
      )
    end

    step 'Click on "Re-test" button' do
      find('.test-pretest-again-btn').click
    end

    step 'I can see the "Connectivity Test" dialog' do
      expect(page).to have_selector(
        '.test-dialog-box .test-dialog-heading',
        text: 'Connectivity Test'
      )
    end
  end
end
