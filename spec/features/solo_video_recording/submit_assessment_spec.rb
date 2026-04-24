feature 'Submit activity', chrome: true, js: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) { create(:program) }
  let(:assessment_strand) { create(:toc_entry) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:section) { create(:section, course:, instructor:) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, toc_entries: [assessment_strand], unit:) }
  let(:activity) do
    create(:json_assessment_with_svr, title: 'Mid-Unit Assessment', lesson:)
  end

  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      move_file: nil,
      store_file_contents!: nil
    )
  end

  let(:attempt) do
    create(
      :attempt_submitted,
      activity:,
      user: student,
      section:,
      time_spent: 300,
      save_record_length: 500
    )
  end

  def add_attempt_results(recording_path = nil)
    MaestroActivityEngine::ActivityContent::Results.new(
      activity.content_object
    ).tap do |results|
      results.add(
        label: 'question_01',
        points_earned: 0,
        points_possible: 1,
        submitted: true,
        response: {
          user_id: student.id,
          user_section_id: section.id,
          recording_path:
        }
      )
    end
  end

  before do
    create(:enrollment, user: student, section:)
    create(
      :assignment,
      assignable: activity,
      due_date: Date.tomorrow,
      section:
    )
    allow(s3_bucket).to receive(:content_length).and_return(3414145)
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(Attempt).to receive(:active_attempt).and_return(attempt)
    give_user_access_to_program(student, program)
    log_in_as(student)
  end

  describe 'When the activity has no recording present' do
    before do
      attempt_results = add_attempt_results
      allow(attempt).to receive(:results).and_return(attempt_results)
      visit section_activity_path(section_id: section.id, id: activity.id)
    end

    it 'I can see a chat widget' do
      expect(page).to have_selector('.test-svr-chat-widget-wrapper')
    end

    it 'I cannot see the svr recording' do
      expect(page).not_to have_selector('.test-svr-recording-container')
    end
  end
end
