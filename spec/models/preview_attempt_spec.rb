describe PreviewAttempt do
  let(:user) { create(:instructor) }
  let(:section) { Section.section_zero }

  let(:content) do
    '<activity activity_type="blank" title="none" language="es"><dl/><items/></activity>'
  end

  let(:lesson) { create(:lesson) }

  let(:activity) do
    PreviewActivity.new(
      activity_type: 'blank',
      cms_revision_id: 123,
      concept_id: 94509,
      content: content,
      lesson_id: lesson.id,
      toc_location: 94509
    )
  end

  context '#attempt_track' do
    let(:attempt) do
      described_class.new(
        activity: activity,
        user: user,
        section: section
      )
    end

    it 'returns an object that has an attempt tracker' do
      expect(attempt.attempt_track).to be_a AttemptTrack
    end

    it 'simultates the number of remaining attempts' do
      expect(attempt.attempt_track.remaining).to eq 'unlimited'
    end
  end
end
