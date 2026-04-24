describe Gradebook::StudentPracticeTestPresenter do
  include RspecJsContentHelpers

  let(:student) { create(:student) }
  let(:student_not_in_section) { create(:student) }
  let(:program) do
    program = create(:program)
    create(:unit, rank: 1, program: program)
    create(:unit, rank: 2, program: program)
    program
  end
  let(:first_lesson) { create(:lesson, rank: 1, unit: program.units[0]) }
  let(:lesson_m3) { create(:lesson, rank: 3, unit: program.units[1]) }
  let(:section_1) { create(:section) }
  let(:section_2) { create(:section) }

  let!(:activities) do
    {
      formative: create_formative_activity(program, lesson: lesson_m3),
      summative: create_summative_activity(program, lesson: lesson_m3)
    }
  end

  let!(:attempt) do
    create(:attempt,
           user_id: student.id,
           section_id: section_1.id,
           activity_id: activities[:summative].id,
           status_code: AttemptStatus::CODE_COMPLETED)
  end

  let(:presenter) do
    described_class.new(
      {
        student_id: student.id,
        program_id: program.id,
        section_id: section_1.id,
        lesson_id: lesson_m3.id
      }
    )
  end

  let(:presenter_student_not_in_section) do
    described_class.new({ student_id: student_not_in_section.id,
                          program_id: program.id,
                          section_id: section_1.id,
                          lesson_id: lesson_m3.id })
  end

  before do
    create(:active_enrollment, user: student, section: section_1)
    create(:active_enrollment, user: student_not_in_section, section: section_2)
    first_lesson
    lesson_m3
  end

  describe '#lesson_focus' do
    describe 'for a single tier program' do
      it 'returns the first lesson if no lesson is selected' do
        presenter = described_class.new(
          {
            student_id: student_not_in_section.id,
            program_id: program.id,
            section_id: section_1.id
          }
        )
        expect(presenter.lesson_focus).to eq [first_lesson]
      end

      it 'returns the selected lesson if one is selected' do
        expect(presenter.lesson_focus).to eq [lesson_m3]
      end
    end

    describe 'for a two tier program' do
      let(:second_lesson) { create(:lesson, rank: 2, unit: program.units[0]) }
      let(:fourth_lesson) { create(:lesson, rank: 4, unit: program.units[1]) }

      before do
        second_lesson
      end

      it 'returns the lessons of the first unit, if no unit is selected' do
        presenter = described_class.new(
          {
            student_id: student_not_in_section.id,
            program_id: program.id,
            section_id: section_1.id
          }
        )
        expect(presenter.lesson_focus).to eq [first_lesson, second_lesson]
      end

      it 'returns the lessons of the selected unit if one is selected' do
        presenter = described_class.new(
          {
            student_id: student_not_in_section.id,
            program_id: program.id,
            section_id: section_1.id,
            unit_id: program.units[1].id
          }
        )
        expect(presenter.lesson_focus).to eq [lesson_m3, fourth_lesson]
      end
    end
  end

  describe '#activity' do
    it 'returns an activity filtered by lesson and activity type' do
      expect(presenter.activity).to eq(activities[:summative])
    end
  end

  describe '#attempt' do
    context 'when there is a completed attempt for the summative activity' do
      it 'returns an attempt filtered by student focus, section, attempt_status, and activity' do
        expect(presenter.attempt).to eq(attempt)
      end
    end

    context 'when there is an opened attempt for the summative activity' do
      it 'returns nil' do
        student_with_opened_attempt = create(:student)
        create(:active_enrollment, user: student_with_opened_attempt, section: section_1)
        create(:attempt,
               user_id: student_with_opened_attempt.id,
               section_id: section_1.id,
               activity_id: activities[:summative].id,
               status_code: AttemptStatus::CODE_OPENED)

        presenter_opened_attempt = described_class.new(student_id: student_with_opened_attempt.id,
                                                       program_id: program.id,
                                                       section_id: section_1.id,
                                                       lesson_id: lesson_m3.id)

        expect(presenter_opened_attempt.attempt).to eq(nil)
      end
    end
  end

  describe '#student_focus' do
    it 'returns a student if found in the section' do
      expect(presenter.student_focus).to eq(student)
    end

    it 'does not find students in another section' do
      expect do
        presenter_student_not_in_section.student_focus
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#lessons' do
    it 'returns a lesson set related to a unit and a specific program' do
      expect(presenter.lessons).to eq program.lessons
    end
  end

  describe '#units' do
    it 'returns the visible units of a program' do
      expect(presenter.units).to eq program.units
    end
  end

  describe '#selected_lesson_id' do
    it 'returns the lesson_id that was passed to the constructor, if one is given' do
      expect(presenter.selected_lesson_id).to eq(lesson_m3.id)
    end

    it 'returns the first visible lesson of the program if not lesson_id is given to the constructor' do
      presenter = described_class.new(
        {
          student_id: student_not_in_section.id,
          program_id: program.id,
          section_id: section_1.id
        }
      )
      expect(presenter.selected_lesson_id).to eq first_lesson.id
    end
  end

  describe '#selected_unit_id' do
    it 'return the unit_id that was passed to the constructor, if one is given' do
      presenter = described_class.new(
        {
          student_id: student_not_in_section.id,
          program_id: program.id,
          section_id: section_1.id,
          unit_id: program.units[1].id
        }
      )
      expect(presenter.selected_unit_id).to eq program.units[1].id
    end

    it 'returns the first visible unit of the program if not unit_id is given to the constructor' do
      presenter = described_class.new(
        {
          student_id: student_not_in_section.id,
          program_id: program.id,
          section_id: section_1.id
        }
      )
      expect(presenter.selected_unit_id).to eq program.units[0].id
    end
  end

  describe '#section' do
    it 'returns a section' do
      expect(presenter.section).to eq(section_1)
    end
  end
end
