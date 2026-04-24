require 'rails_helper'

RSpec.describe CourseWithSectionBuilder do
  let!(:course_owner) { create(:instructor) }
  let!(:program) { create(:program) }

  let!(:enterprise_course) do
    create(
      :enterprise_course,
      program:,
      enterprise_section: create(:enterprise_section, class_days: '2, 5'),
      owner: course_owner
    )
  end

  let!(:course) { create(:course, program:) }
  let!(:section1) { create(:section, course:, class_days: '2, 5') }
  let!(:section2) { create(:section, course:, class_days: '2, 5') }

  before do
    create(:section_instructor, instructor: course_owner, section: section1)
    create(:section_instructor, instructor: course_owner, section: section2)
  end

  describe '#build' do
    let(:course_options) { CourseOptions.new(course_owner, enterprise_course, program) }

    context 'when the course is enterprise' do
      let(:result) { described_class.new(enterprise_course, course_options).build }

      it 'includes the enterprise course with the enterprise section' do
        enterprise_section = enterprise_course.enterprise_section
        expect(result).to include(
          id: enterprise_course.id,
          name: enterprise_course.name,
          enterprise: true,
          sections: [
            {
              id: enterprise_section.id,
              class_days_count: 2,
              name: enterprise_section.name
            }
          ]
        )
      end
    end

    context 'when the course is not enterprise but has assignments in sections' do
      before do
        create(:assignment, section: section1)
        create(:assignment, section: section2)
      end

      let(:regular_course_options) { CourseOptions.new(course_owner, course, program) }
      let(:regular_course_result) { described_class.new(course, regular_course_options).build }

      it 'includes the regular course and its sections with assignments' do
        expect(regular_course_result).to include(
          id: course.id,
          name: course.name,
          enterprise: false,
          sections: [
            {
              id: section1.id,
              class_days_count: 2,
              name: section1.name
            },
            {
              id: section2.id,
              class_days_count: 2,
              name: section2.name
            }
          ]
        )
      end
    end

    context 'when the course has sections with external items but no assignments' do
      before do
        allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
          .with(section1.id).and_return([{ id: 1, name: 'External Item 1' }])
        allow(GradebookEngine::GradebookAPI).to receive(:find_external_items_by_section)
          .with(section2.id).and_return([{ id: 2, name: 'External Item 2' }])
      end

      let(:regular_course_options) { CourseOptions.new(course_owner, course, program) }
      let(:regular_course_result) { described_class.new(course, regular_course_options).build }

      it 'includes the regular course and its sections with external items' do
        expect(regular_course_result).to include(
          id: course.id,
          name: course.name,
          enterprise: false,
          sections: [
            {
              id: section1.id,
              class_days_count: 2,
              name: section1.name
            },
            {
              id: section2.id,
              class_days_count: 2,
              name: section2.name
            }
          ]
        )
      end
    end

    context 'when the course has sections without assignments or external items' do
      let(:regular_course_options) { CourseOptions.new(course_owner, course, program) }
      let(:regular_course_result) { described_class.new(course, regular_course_options).build }

      it 'does not include the course or its sections' do
        expect(regular_course_result[:sections]).to eq([])
      end
    end
  end
end
