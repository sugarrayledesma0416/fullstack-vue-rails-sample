describe NewStudentDashboardController do
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:presenter) { double('presenter') }
  let(:user) {  build_stubbed(:student) }

  describe '#past_assignment_summaries' do
    it_should_require_a_logged_in_user { get :past_assignment_summaries, params: { course_id: course, section_id: section } }

    it 'render the due date tabs partial' do
      fake_context(user: user, section: section)
      expect(presenter).to receive(:past_assignment_summaries)
      expect(StudentDashboardPresenter).to receive(:new).with(user, section).and_return(presenter)
      get :past_assignment_summaries, params: { course_id: course.id, section_id: section.id }
      expect(subject).to render_template('sections/_due_date_tabs')
    end
  end

  describe '#assignments_by_due_date' do
    let(:due_date) { double('due_date') }
    it_should_require_a_logged_in_user { get :assignments_by_due_date, params: { course_id: course, section_id: section, due_date: Date.today } }

    it 'render the assignments by concept partial' do
      fake_context(user: user, section: section)
      expect(due_date).to receive(:assignment_groups)
      expect(DueDate).to receive(:new).with(section.id, Date.today.to_param, user.id).and_return(due_date)

      get :assignments_by_due_date, params: { course_id: course.id, section_id: section.id, due_date: Date.today }
      expect(subject).to render_template('sections/_assignments_by_concepts')
    end
  end

  describe '#assignments' do
    it_should_require_a_logged_in_user { get :assignments, params: { course_id: course, section_id: section } }
  end

  describe '#unit_assignments', test_debt: true do
    it_should_require_a_logged_in_user { get :unit_assignments, params: { course_id: course, section_id: section, included_activity_id: build_stubbed(:activity) } }
  end

  describe '#progress' do
    it_should_require_a_logged_in_user { get :progress, params: { course_id: course, section_id: section } }
  end
end
