describe StudentWorkTransfer, test_debt: true do
  let(:student)  { create(:student) }
  let(:course_from) { create(:course) }
  let(:section_from) { create(:section, course: course_from) }
  let(:category_from) { create(:category, :course_id => course_from) }
  let(:course_to) { create(:course) }
  let(:section_to) { create(:section, course: course_to) }
  let(:category_to) { create(:category, :course_id => course_to) }
  let(:results) { MaestroActivityEngine::ActivityContent::Results.new }  # empty reponse results so we can write out attempt responses

  before do
    stub_request(:post, /.*\/submissions/).to_return(status: 200, body: {id: 10000}.to_json, headers: {})
  end

  describe "destination section has no work" do
    before do
      @activities = []
      @assignments = []
      @attempts = []
      @scores = []

      # these global allow's are needed so grades can be created when scores are marked current.
      allow_any_instance_of(Activity).to receive(:strand)
        .and_return(double('Strand', title: 'Strand 1', location: 9347659))
      allow_any_instance_of(Activity).to receive(:lesson)
        .and_return(double('Lesson', id: 925, program_id: 79))

      # create a couple of assignments, scores, and attempts
      (0..1).each do
        @activities << create_activity
        @assignments << create_current_assignment(section_from, @activities.last, category_from)
        @attempts << create_completed_attempt(student, section_from, @activities.last)
        @scores << create_score(student, section_from, @activities.last, @assignments.last)
      end

      # create matching assignments in destination section
      @assignments.each_with_index do |assignment, idx|
        create_current_assignment(section_to, @activities[idx], category_to)
      end
      section_to.students << student
    end

    it "moves all the work to the new section" do
      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      expect(Score.where(:user_id => student, :section_id => section_from).count).to eq(0)
      expect(Score.where(:user_id => student, :section_id => section_to).count).to eq(2)
      expect(Attempt.where(:user_id => student, :section_id => section_from).count).to eq(0)
      expect(Attempt.where(:user_id => student, :section_id => section_to).count).to eq(2)
    end

    it "moves work from an archived section" do
      section_from.update(:is_archived => true)
      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      expect(Score.where(:user_id => student, :section_id => section_to).count).to eq(2)
      expect(Attempt.where(:user_id => student, :section_id => section_to).count).to eq(2)
    end

    it "moves work that is not assigned in the new section" do
      Assignment.last.delete
      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      expect(Score.where(user_id: student, section_id: section_from).count).to eq 0
      expect(Attempt.where(user_id: student, section_id: section_from).count).to eq 0
    end
  end

  describe "destination has some work" do
    before do
      @activities = []
      @assignments = []
      @attempts = []
      @scores = []

      # create a couple of assignments, scores, and attempts
      (0..2).each do
        @activities << create_activity
        @assignments << create_assignment(section_from, @activities.last, category_from)
        @attempts << create_completed_attempt(student, section_from, @activities.last)
        @scores << create_score(student, section_from, @activities.last, @assignments.last)
      end

      # create matching assignments in destination section
      @assignments.each_with_index do |assignment, idx|
        create_assignment(section_to, @activities[idx], category_to)
      end

      # create an attempt and score for one assignment in the destination section
      dest_attempt = create_completed_attempt(student, section_to, @activities.first)
      dest_score = create_score(student, section_to, @activities.first, @assignments.first)
      section_to.students << student
    end

    it "moves attempts and scores that do not exist in the destination section" do
      # we have a couple in the source section
      expect(Score.where(user_id: student, section_id: section_from).count).to eq(3)
      expect(Attempt.where(user_id: student, section_id: section_from).count).to eq(3)

      # we have 1 in the destination
      expect(Score.where(:user_id => student, :section_id => section_to).count).to eq(1)
      expect(Attempt.where(:user_id => student, :section_id => section_to).count).to eq(1)

      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      # the old section still has one record left
      expect(Score.where(:user_id => student, :section_id => section_from).count).to eq(1)
      expect(Attempt.where(:user_id => student, :section_id => section_from).count).to eq(1)
      # the new section now has 2 records
      expect(Score.where(user_id: student, section_id: section_to).count).to eq(3)
      expect(Attempt.where(user_id: student, section_id: section_to).count).to eq(3)
    end

    it "moves attempts and scores from an archived section" do
      # starting with one record
      expect(Score.where(:user_id => student, :section_id => section_to).count).to eq(1)
      expect(Attempt.where(:user_id => student, :section_id => section_to).count).to eq(1)

      section_from.update(:is_archived => true)
      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      # we end up with 3
      expect(Score.where(user_id: student, section_id: section_to).count).to eq(3)
      expect(Attempt.where(user_id: student, section_id: section_to).count).to eq(3)
    end

    it "moves work that is not assigned in the new section" do
      deleted_assignable_id = Assignment.last.assignable_id
      Assignment.last.delete

      # section_from has 3 scores/attempts
      expect(Score.where(user_id: student, section_id: section_from).count).to eq 3
      expect(Attempt.where(user_id: student, section_id: section_from).count).to eq 3
      # section_to has one score/attempt matching one in section_from
      expect(Score.where(user_id: student, section_id: section_to).count).to eq 1
      expect(Attempt.where(user_id: student, section_id: section_to).count).to eq 1

      worker = StudentWorkTransfer.new(student.id, section_from.id, section_to.id)
      allow(worker).to receive(:unblock_access!).and_return(true)
      worker.process

      # one left behind since it exists in the destination section
      expect(Score.where(user_id: student, section_id: section_from).count).to eq 1
      expect(Attempt.where(user_id: student, section_id: section_from).count).to eq 1
      # 2 scores/attempts moved
      expect(Score.where(user_id: student, section_id: section_to).count).to eq 3
      expect(Attempt.where(user_id: student, section_id: section_to).count).to eq 3
      expect(Score.where(user_id: student, section_id: section_to, scorable_id: deleted_assignable_id).count).to eq 1
      expect(Attempt.where(user_id: student, section_id: section_to, activity_id: deleted_assignable_id).count).to eq 1
    end
  end

  def create_current_assignment(section, activity, category, due_date = 1.day.ago.to_date)
    create_assignment(section, activity, category, due_date, true)
  end

  def create_assignment(section, activity, category, due_date = 1.day.ago.to_date, current = false)
    Assignment.create_with_grades(section_from, { :section_id => section.id,
                                                  :assignable => activity,
                                                  :due_date => due_date,
                                                  :category_id => category.id,
                                                  :current => current })
  end

  def create_completed_attempt(student, section, activity)
    attempt = Attempt.find_or_create_with_scoring_ruleset(student, activity, section.id)
    attempt.write_results(results, AttemptStatus::CODE_COMPLETED)
    attempt
  end

  def create_score(student, section, activity, assignment = nil)
    score = Score.create_or_find(student, section, activity, activity.points_possible)
    if assignment.present?
      score.update(assigned: true,
                              current: assignment.current,
                              submitted_at: Time.now)
    end
  end

  def create_activity
    activity = create(:activity)
    allow(activity).to receive(:result_labels).and_return([])
    activity
  end
end
