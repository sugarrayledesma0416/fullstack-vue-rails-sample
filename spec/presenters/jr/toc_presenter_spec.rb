describe Jr::TocPresenter do

  let(:program) { build_stubbed(:program) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:user) { build_stubbed(:student) }
  let(:lesson) { build_stubbed(:lesson) }
  let(:strand) { create(:toc_entry) }

  let(:presenter) do
    described_class.new(
      lesson: lesson,
      program: program,
      section: section,
      strand: strand,
      user: user
    )
  end

  let(:presenter_with_no_section) do
    described_class.new(
      lesson: lesson,
      program: program,
      strand: strand,
      user: user
    )
  end

  describe '#activities' do
    let(:activity_1) { create(:activity) }
    let(:activity_2) { create(:activity) }
    let(:activity_3) { create(:activity) }

    before do
      allow(Services::TocActivityList).to receive(:all_for_toc_location).and_return(
        [activity_1.id, activity_2.id, activity_3.id]
      )
    end

    it 'calls all_for_toc_location on the TocActivityList service, passing ' \
       'in the specified strand the current course' do
      presenter.activities

      expect(Services::TocActivityList).to have_received(:all_for_toc_location)
        .with(strand.location, sections: [section], current_user: user)
    end

    it 'specifies a nil course in the all_for_toc_location call when no ' \
       'section is defined' do
      presenter_with_no_section.activities

      expect(Services::TocActivityList).to have_received(:all_for_toc_location)
        .with(strand.location, sections: [nil], current_user: user)
    end

    it 'retrieves only the activities obtained from the TocActivityList service' do
      expect(presenter.activities).to contain_exactly(activity_1, activity_2, activity_3)
    end

    it 'returns instructor-created activities first' do
      activity_2.update!(instructor_revision_id: 1)

      expect(presenter.activities).to eq([activity_2, activity_1, activity_3])
    end

    it 'sorts non-instructor-created activities by their toc rank' do
      activity_2.update!(toc_location_rank: 1)
      activity_1.update!(toc_location_rank: 2)
      activity_3.update!(toc_location_rank: 3)

      expect(presenter.activities).to eq([activity_2, activity_1, activity_3])
    end

    it 'assigns the lesson specified on initialize to each activity to ' \
       'avoid unnecessary lesson lookups' do
      expect(presenter.activities.map(&:lesson)).to eq([lesson, lesson, lesson])
    end
  end

  describe '#current_topic' do
    it 'returns the location of the specified strand' do
      expect(presenter.current_topic).to eq(strand.location)
    end
  end

  describe '#grading_strand' do
    it 'returns the location of the specified strand' do
      expect(presenter.grading_strand).to eq(strand.location)
    end
  end

  describe '#section_id' do
    it 'returns the id of the section when one is specified' do
      expect(presenter.section_id).to eq(section.id)
    end

    it 'returns 0 when section is nil' do
      expect(presenter_with_no_section.section_id).to eq(0)
    end
  end
end
