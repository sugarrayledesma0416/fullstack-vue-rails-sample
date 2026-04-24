describe GradingFeedback do
  let(:sections) { build_stubbed(:section) }
  let(:activity) { build_stubbed(:activity) }
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }
  let(:attempt_1) { build_stubbed(:attempt, :user_id => student_1.id) }
  let(:attempt_2) { build_stubbed(:attempt, :user_id => student_2.id) }
  let(:attempts) { [attempt_1, attempt_2] }
  let(:students) { [student_1, student_2] }
  let(:question_1) { double('Question', :label => 'question_1') }
  let(:question_2) { double('Question', :label => 'question_02_wol_1') }
  let(:questions) { [question_1, question_2] }
  let(:feedback_items) { [ double(FeedbackItem, :user_id => student_1.id,
                                                    :question_label => question_1.label,
                                                    :points_earned => 9.5,
                                                    :comment => 's1 q1 comment',
                                                    :inline_corrections => 'student_1 inline_corrections',
                                                    :recording => double(Recording)),
                           double(FeedbackItem, :user_id => student_1.id,
                                                    :question_label => question_2.label,
                                                    :points_earned => 9.3,
                                                    :comment => 's1 q2 comment',
                                                    :inline_corrections => 's1 q1 inline_corrections',
                                                    :recording => nil),
                           double(FeedbackItem, :user_id => student_2.id,
                                                    :question_label => question_1.label,
                                                    :points_earned => 8.5,
                                                    :comment => 's2 q1 comment',
                                                    :inline_corrections => 's2 q1 inline_corrections',
                                                    :recording => double(Recording)),
                           double(FeedbackItem, :user_id => student_2.id,  # general feedback comment
                                                    :question_label => nil,
                                                    :points_earned => nil,
                                                    :comment => 's2 q1 comment',
                                                    :inline_corrections => nil,
                                                    :recording => nil) ] }

  before do
    allow(Attempt).to receive(:activity_attempts).and_return(attempts)
    allow(FeedbackItem).to receive(:by_attempts).and_return(feedback_items)
  end

  describe "#feedback_items" do
    it "retrieves all feedback items for the page" do
      expect(FeedbackItem).to receive(:by_attempts).with(attempts.map(&:id)).and_return(feedback_items)
      GradingFeedback.new(:activity => activity,
                          :students => students,
                          :questions => questions,
                          :sections => sections).feedback_items
    end
  end

  describe "#attempt_for_student" do
    it "exposes the relevant attempt for a student" do
      fb = GradingFeedback.new(:activity => activity,
                               :students => students,
                               :questions => questions,
                               :sections => sections)
      students.each do |student|
        attempt = fb.attempt_for_student(student)
        expect(attempt.user_id).to eq(student.id)
      end
      # prove that we didn't modify the attempt objects
      expect(attempts.map(&:user_id)).to eq(students.map(&:id))
    end
  end


  context "when retrieving feedback" do
    before do
      @grading_feedback = GradingFeedback.new(:activity => activity,
                                              :students => students,
                                              :questions => questions,
                                              :sections => sections)
    end
    describe "#question_comment" do
      it "returns the instructor comment for a student and question" do
        expect(@grading_feedback.question_comment(student_1, question_1.label)).to eq(feedback_items[0].comment)
        expect(@grading_feedback.question_comment(student_1, question_2.label)).to eq(feedback_items[1].comment)
        expect(@grading_feedback.question_comment(student_2, question_1.label)).to eq(feedback_items[2].comment)
        expect(@grading_feedback.question_comment(student_2, question_2.label)).to be_nil # no feedback_item
      end
    end

    describe "#question_markup" do
      it "returns the instructor inline corrections for a student and question" do
        expect(@grading_feedback.question_markup(student_1, question_1.label)).to eq(feedback_items[0].inline_corrections)
        expect(@grading_feedback.question_markup(student_1, question_2.label)).to eq(feedback_items[1].inline_corrections)
        expect(@grading_feedback.question_markup(student_2, question_1.label)).to eq(feedback_items[2].inline_corrections)
        expect(@grading_feedback.question_markup(student_2, question_2.label)).to be_nil # no feedback_item
      end
    end

    describe "#question_recording" do
      it "returns the instructor recording for a student and question" do
        expect(@grading_feedback.question_recording(student_1, question_1.label)).to eq(feedback_items[0].recording)
        expect(@grading_feedback.question_recording(student_1, question_2.label)).to be_nil # the feedback_item has no recording
        expect(@grading_feedback.question_recording(student_2, question_1.label)).to eq(feedback_items[2].recording)
        expect(@grading_feedback.question_recording(student_2, question_2.label)).to be_nil # no feedback_item
      end
    end

    describe "#question_points" do
      it "returns the points earned for a student and question" do
        expect(@grading_feedback.question_points(student_1, question_1.label)).to eq(feedback_items[0].points_earned)
        expect(@grading_feedback.question_points(student_1, question_2.label)).to eq(feedback_items[1].points_earned)
        expect(@grading_feedback.question_points(student_2, question_1.label)).to eq(feedback_items[2].points_earned)
        expect(@grading_feedback.question_points(student_2, question_2.label)).to be_nil # no feedback_item
      end
    end

    describe "#general_feedback" do
      it "returns the general feedback for a student" do
        expect(@grading_feedback.general_feedback(student_1)).to be_nil
        expect(@grading_feedback.general_feedback(student_2)).to eq(feedback_items[3])
      end
    end

    describe "#[]" do
      it "returns the correct feedback item" do
        expect(@grading_feedback["#{question_1.label}_student_#{student_1.id}"]).to eq(feedback_items[0])
        expect(@grading_feedback["#{question_2.label}_student_#{student_1.id}"]).to eq(feedback_items[1])
        expect(@grading_feedback["#{question_1.label}_student_#{student_2.id}"]).to eq(feedback_items[2])
      end

      it "returns nil when there is no feedback for a proper key" do
        expect(@grading_feedback["#{question_2.label}_student_#{student_2.id}"]).to be_nil
      end

      it "returns nil when the student_id does not match and the question label is valid" do
        expect(@grading_feedback["#{question_2.label}_student_123"]).to be_nil
      end

      it "returns nil when the question label does not match and the student_id is valid" do
        expect(@grading_feedback["question_99_student_#{student_2.id}"]).to be_nil
      end

      it "returns nil when the key does not match" do
        expect(@grading_feedback["garbage string"]).to be_nil
      end
    end
  end

end
