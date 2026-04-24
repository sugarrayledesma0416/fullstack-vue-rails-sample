describe AssessmentsPresenter do
  include AssessmentHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::SanitizeHelper

  let(:program) { build_stubbed(:program) }
  let(:school) { build_stubbed(:school) }
  let(:course) { build_stubbed(:course, program: program, school: school) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:user) { build_stubbed(:user) }
  let(:presenter) { described_class.new(program, section, user) }

  describe '#to_do_and_finished_list' do
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:section) { create(:section) }
    let(:user) { create(:user) }
    let(:unit) { create(:unit, program: program) }
    let(:strand) { create(:toc_entry, assessment: true) }
    let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
    let(:due_date) { 5.days.from_now.to_date }

    let(:concept) do
      create(
        :concept,
        assessment: true,
        id: strand.location,
        lesson: lesson,
        program: program
      )
    end

    let(:assessment) do
      create(
        :activity,
        concept: concept,
        lesson: lesson,
        toc_location: strand.location
      )
    end

    it 'has "to-do" and "finished" keys with empty arrays when there ' \
       'are no assigned assessments' do
      expect(presenter.to_do_and_finished_list).to eq(
        'to-do': [],
        'finished': []
      )
    end

    it 'returns the due date, lesson, title, and an activity link for each ' \
       'released, incomplete assessment' do
      assignment = create(
        :assignment,
        assignable: assessment,
        due_date: due_date,
        section: section,
        show_at: 1.day.ago
      )

      expect(presenter.to_do_and_finished_list[:'to-do']).to contain_exactly(
        due_date: assignment.due_date_time.to_s(:short_ordinal),
        lesson: lesson.display_name,
        link: section_activity_path(id: assessment.id, section_id: section.id),
        title: concept.name
      )
    end

    it 'returns the due date, title, and an activity link for each ' \
       'completed assessment' do
      create(
        :assignment,
        assignable: assessment,
        due_date: due_date,
        section: section,
        show_at: 1.day.ago
      )

      create(:attempt_completed, activity: assessment, section: section, user: user)

      expect(presenter.to_do_and_finished_list[:finished]).to contain_exactly(
        due_date: due_date.strftime('%a %-m/%-d'),
        link: section_activity_path(id: assessment.id, section_id: section.id),
        title: format_assessment_assignment_title_text(assessment)
      )
    end
  end

  describe '#current_assessments' do
    it 'returns current assessments' do
      obj = double(Assignment, assignable: 1)
      allow(presenter).to receive(:current_assignments).and_return([obj])
      expect(presenter.current_assessments).to eq([1])
    end
  end

  describe '#current_assigmnents' do
    it 'returns current assignments' do
      obj = double()
      expect(obj).to receive(:incomplete_released_non_practice_by_activity_list)
        .with(program.assessments(sections: course.sections, current_user: user), user, section)
      allow(section).to receive(:assignments).and_return(obj)
      presenter.current_assignments
    end
  end

  describe '#sorted_current_assignments' do
    it 'returns assignments sorted by due date' do
      assignment_1 = instance_double(Assignment, due_date: Date.today)
      assignment_2 = instance_double(Assignment, due_date: Date.yesterday)
      allow(presenter).to receive(:current_assignments)
        .and_return([assignment_1, assignment_2])
      expect(presenter.sorted_current_assignments).to eq([assignment_2, assignment_1])
    end
  end

  describe '#score_for' do
    it 'gets the score via the gradebook engine API' do
      assignment = build_stubbed(:assignment)
      student = build_stubbed(:student)
      score = double('score', net_ratio: 0.73)
      grades = { assignment.assignable.id => score }
      allow(presenter).to receive(:user).and_return(student)
      expect(GradebookEngine::GradebookAPI).to receive(:user_section_grades)
        .with(user: student, section: section).and_return(grades)

      expect(presenter.score_for(assignment)).to eq(score)
    end
  end

  describe '#grade_availability_description' do
    let(:assignment) do
      build_stubbed(:assignment).tap do |memo|
       allow(memo).to receive(:assessment_grade_available?).and_return(false)
      end
    end

    it "should process the 'on_release' availability option" do
      allow(assignment).to receive(:grade_availability).and_return(:on_release)
      expect(presenter.grade_availability_description(assignment)).to eq(
        'Your grade will be available when your instructor releases it.'
      )
    end

    it "should process the 'on_grading' availability option" do
      allow(assignment).to receive(:grade_availability).and_return(:on_grading)
      expect(presenter.grade_availability_description(assignment)).to eq(
        'Your grade will be available when all students have been graded.'
      )
    end

    it "should process the 'on_specific_date' availability option" do
      allow(assignment).to receive(:grade_availability).and_return(:on_specific_date)
      grade_availability_date = Time.parse('2013-01-01 13:15:00')
      allow(assignment).to receive(:grades_available_at).and_return(grade_availability_date)
      expect(presenter.grade_availability_description(assignment)).to eq(
        'Your grade will be available after ' +
        grade_availability_date.strftime("%a, %b #{grade_availability_date.day.ordinalize} %I:%M %p.")
      )
    end

    it "should process the 'on_due_date' availability option" do
      allow(assignment).to receive(:grade_availability).and_return(:on_due_date)
      due_date = Time.parse('2012-05-12 17:08:00')
      allow(assignment).to receive(:due_date).and_return(due_date)
      expect(presenter.grade_availability_description(assignment)).to eq(
        'Your grade will be available after ' +
        due_date.strftime("%a, %b #{due_date.day.ordinalize} %I:%M %p.")
      )
    end

    it "should process the 'never' availability option" do
      allow(assignment).to receive(:grade_availability).and_return(:never)
      expect(presenter.grade_availability_description(assignment)).to eq(
        'Your instructor has chosen not to show this grade online.'
      )
    end
  end
end
