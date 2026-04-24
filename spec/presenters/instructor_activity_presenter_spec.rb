describe InstructorActivityPresenter do
  let(:activity) { create(:activity) }
  let(:instructor) { create(:instructor) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:instructor_presenter) do
    described_class.new(activity, instructor, section, course)
  end

  describe 'behaviours' do
    it 'should be a SharedActivityViewer' do
      expect(instructor_presenter).to be_a(SharedActivityViewer)
    end
  end

  describe '#notifications' do
    let(:strand) { create(:toc_entry) }

    it 'returns an empty list of notifications' do
      allow_any_instance_of(Lesson).to receive(:strand_for_toc_location).and_return(strand)

      # notification for a different user
      create(
        :activity_graded_notification,
        section:,
        user: create(:user),
        activity:,
      )
      # notification for a different section
      create(
        :activity_graded_notification,
        section: create(:section),
        user: instructor,
        activity:,
      )
      # dismissed notification for the user and section
      notification = create(
        :activity_graded_notification,
        section:,
        user: instructor,
        activity:,
        dismissed_at: 2.days.ago.to_date
      )
      # unreviewed notification for the user and section
      create(
        :activity_feedback_notification,
        section:,
        user: instructor,
        activity:
      )

      expect(instructor_presenter.notifications).to be_empty
    end
  end

  describe '#unreviewed_notifications' do
    let(:strand) { create(:toc_entry) }

    it 'returns an empty list of notifications' do
      allow_any_instance_of(Lesson).to receive(:strand_for_toc_location).and_return(strand)

      create(
        :activity_graded_notification,
        section:,
        user: instructor,
        activity:,
        dismissed_at: 2.days.ago.to_date
      )
      create(
        :activity_feedback_notification,
        section:,
        user: instructor,
        activity:
      )

      expect(instructor_presenter.notifications).to be_empty
    end
  end

  describe '#assignment' do
    let(:assignment) { build_stubbed(:assignment) }

    before do
      allow(section).to receive(:assignment_by_activity)
        .and_return(assignment)
    end

    it 'looks up the assignment for the current activity and current section' do
      instructor_presenter.assignment
      expect(section).to have_received(:assignment_by_activity).with(activity)
    end

    it 'returns the retrieved assignment' do
      expect(instructor_presenter.assignment).to eq(assignment)
    end
  end

  describe '#has_smartbook_attempt_with_feedback?' do
    it 'returns false' do
      expect(instructor_presenter.has_smartbook_attempt_with_feedback?).to be_falsey
    end
  end

  describe '#allow_audio_transcripts?' do
    it 'returns true if audio transcript is not allowed' do
      course.update!(allow_audio_transcripts: false)

      expect(instructor_presenter.allow_audio_transcripts?).to be_truthy
    end

    it 'returns true if audio transcript is allowed' do
      course.update!(allow_audio_transcripts: true)

      expect(instructor_presenter.allow_audio_transcripts?).to be_truthy
    end
  end
end
