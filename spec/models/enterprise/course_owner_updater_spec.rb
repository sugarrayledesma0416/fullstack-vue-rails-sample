RSpec.describe Enterprise::CourseOwnerUpdater do
  subject(:updater) { described_class.new(course, previous_owner, new_owner) }

  let(:program) { create(:program) }
  let(:school) { create(:school) }
  let(:previous_owner) { create(:instructor, schools: [school]) }
  let(:new_owner) { create(:instructor, schools: [school]) }
  # when calling the updater, the course should have already been updated with the new instructor
  let(:course) { create(:enterprise_course, program:, owner: new_owner) }
  let!(:section_1) do
    create(
      :section,
      name: 'section 1',
      course:,
      instructor: previous_owner
    )
  end
  let!(:section_2) do
    create(
      :section,
      name: 'section 2',
      course:,
      instructor: previous_owner
    )
  end
  let(:sections) { [section_1, section_2] }
  let!(:section_1_previous_owner) do
    SectionInstructor.find_by!(section: section_1, instructor: previous_owner)
  end
  let!(:section_2_previous_owner) do
    SectionInstructor.find_by!(section: section_2, instructor: previous_owner)
  end
  let!(:section_1_different_instructor) do
    create(
      :section_co_instructor,
      section: section_1,
      instructor: create(:instructor)
    )
  end

  describe '#to_update?' do
    context 'when the previous and new owner are different' do
      it { expect(updater.to_update?).to be true }
    end

    context 'when the previous and new owner are the same' do
      let(:previous_owner) { new_owner }

      it { expect(updater.to_update?).to be false }
    end
  end

  describe '#update' do
    before { course.reload }

    it_behaves_like 'a new owner that is a valid instructor in one of the schools ' \
                    'the current owner belongs to'

    it_behaves_like 'a new owner that is co-instructor in a section of the course'

    context 'when the course is closed' do
      before do
        course.update(
          start_date: 1.year.ago.to_date,
          end_date: 2.months.ago.to_date,
          allow_past_end_date: true
        )
        updater.update
      end

      it { expect(updater.errors).to contain_exactly('The course is closed.') }

      it 'does not transfers the sections' do
        sections.each do |section|
          expect(section.reload.instructor).to eq(previous_owner)
        end
      end
    end

    context 'when the course is closed but editable' do
      before do
        course.update(
          start_date: 2.months.ago.to_date,
          end_date: 1.month.ago.to_date,
          allow_past_end_date: true
        )
        updater.update
      end

      it { expect(updater.errors).to be_empty }

      it 'transfers the sections' do
        sections.each do |section|
          expect(section.reload.instructor).to eq(new_owner)
        end
      end
    end

    context 'when the course is archived' do
      before do
        course.update(is_archived: true)
        updater.update
      end

      it { expect(updater.errors).to contain_exactly('The course is archived.') }

      it 'does not transfers the sections' do
        sections.each do |section|
          expect(section.reload.instructor).to eq(previous_owner)
        end
      end
    end
  end
end
