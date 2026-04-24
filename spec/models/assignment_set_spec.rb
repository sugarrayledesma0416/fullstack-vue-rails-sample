require 'rails_helper'

RSpec.describe AssignmentSet, type: :model do
  let(:section) { create(:section_with_course) }

  before do
    create(:assignment_set, section: section)
  end

  describe 'validations' do
    describe 'due_date' do
      it 'validates the presence of a due date' do
        assignment_set = described_class.create
        expect(assignment_set.errors[:due_date]).to(
          include(I18n.t('activerecord.errors.messages')[:blank])
        )
      end

      it 'validates that the due date is unique for the section' do
        section.reload
        new_assignment_set = described_class.create(section: section, due_date: Time.zone.today)
        expect(new_assignment_set.errors[:due_date]).to(
          include('already exists for this assignment set')
        )
      end

      context 'when due_date is before the course start_date' do
        it 'adds an error' do
          new_assignment_set = described_class.create(
            section: section,
            due_date: section.course_start_date - 1.day
          )
          expect(new_assignment_set.errors[:due_date]).to(
            include('must be within the section start and end dates.')
          )
        end
      end

      context 'when due_date is after the course end_date' do
        it 'adds an error' do
          new_assignment_set = described_class.create(
            section: section,
            due_date: section.course_end_date + 1.day
          )
          expect(new_assignment_set.errors[:due_date]).to(
            include('must be within the section start and end dates.')
          )
        end
      end
    end

    it 'validates the presence of a section' do
      assignment_set = described_class.create
      expect(assignment_set.errors[:section]).to(
        include(I18n.t('activerecord.errors.messages')[:blank])
      )
    end
  end

  describe '#dates_for_sections' do
    context 'when there are not assignment sets records' do
      before do
        described_class.destroy_all
      end

      it 'returns an empty list' do
        expect(described_class.dates_for_sections([section.id])).to eq([])
      end
    end

    context 'when there are assignment sets records' do
      before do
        described_class.destroy_all
        described_class.create(
          section: section,
          due_date: section.course_end_date - 1.day
        )
      end

      it 'returns a list of unique dates in dd-mm-yyyy format for the sections on focus' do
        expect(described_class.dates_for_sections([section.id])).to eq(
          [(section.course_end_date - 1.day).strftime('%m/%d/%Y').to_s]
        )
      end
    end
  end
end
