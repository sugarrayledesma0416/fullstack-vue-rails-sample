describe InstructorGradingSubmission do
  let(:points_possible) { 10 }
  let(:instructor) { create(:instructor) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }
    let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:question_klass) do
    MaestroActivityEngine::ActivityContent::OpenEnded::Item
  end
  let(:question_1) do
    instance_double(
      question_klass,
      label: 'question_1',
      points_possible:
    )
  end
  let(:question_2) do
    instance_double(
      question_klass,
      label: 'question_2',
      points_possible:
    )
  end
  let(:questions) { [question_1, question_2] }
  let(:response_id) { create_response_id(student_1, question_1) }
  let(:params) do
    {
      "score_for_#{create_response_id(student_1, question_1)}" => points_possible,
      "score_for_#{create_response_id(student_2, question_1)}" => points_possible,
      "score_for_#{create_response_id(student_1, question_2)}" => points_possible,
      "score_for_#{create_response_id(student_2, question_2)}" => points_possible,
      rubric_graded: false
    }
  end
  let(:attempt_student_1) { create(:attempt, activity:, section:, user: student_1) }
  let(:attempt_student_2) { create(:attempt, activity:, section:, user: student_2) }
  let(:grading_feedback) do
    GradingFeedback.new(
      activity:,
      questions: [question_1, question_2],
      students: [student_1, student_2],
      sections: [section]
    )
  end
  let(:attempts_by_user_id) { {} }
  let(:students) { [student_1, student_2] }
  let(:grading_submission) do
    described_class.new(
      instructor,
      activity,
      students,
      [question_1, question_2],
      grading_feedback,
      attempts_by_user_id,
      params
    )
  end
  let(:grading_submission_student_1_question_1) do
    instance_double(
      StudentGradingSubmission,
      score_field: "score_for_#{question_1.label}_student_#{student_1.id}",
      submit: true,
      valid?: true,
      concurrent_enrollment_ai_bug_detected: false,
      student: student_1
    )
  end
  let(:grading_submission_student_1_question_2) do
    instance_double(
      StudentGradingSubmission,
      score_field: "score_for_#{question_2.label}_student_#{student_1.id}",
      submit: true,
      valid?: true,
      concurrent_enrollment_ai_bug_detected: false,
      student: student_1
    )
  end
  let(:grading_submission_student_2_question_1) do
    instance_double(
      StudentGradingSubmission,
      score_field: "score_for_#{question_1.label}_student_#{student_2.id}",
      submit: true,
      valid?: true,
      concurrent_enrollment_ai_bug_detected: false,
      student: student_2
    )
  end
  let(:grading_submission_student_2_question_2) do
    instance_double(
      StudentGradingSubmission,
      score_field: "score_for_#{question_2.label}_student_#{student_2.id}",
      submit: true,
      valid?: true,
      concurrent_enrollment_ai_bug_detected: false,
      student: student_2
    )
  end

  def create_response_id(student, question)
    "#{question.label}_student_#{student.id}"
  end

  before do
    allow(student_1).to receive(:full_name).and_return('John Doe')
    allow(student_2).to receive(:full_name).and_return('Jane Smith')

    allow(StudentGradingSubmission).to receive(:new).with(
      params:,
      student: student_1,
      question: question_1,
      attempt: attempt_student_1,
      activity:,
      instructor:,
      grading_feedback:
    ).and_return(grading_submission_student_1_question_1)
    allow(StudentGradingSubmission).to receive(:new).with(
      params:,
      student: student_1,
      question: question_2,
      attempt: attempt_student_1,
      activity:,
      instructor:,
      grading_feedback:
    ).and_return(grading_submission_student_1_question_2)
    allow(StudentGradingSubmission).to receive(:new).with(
      params:,
      student: student_2,
      question: question_1,
      attempt: attempt_student_2,
      activity:,
      instructor:,
      grading_feedback:
    ).and_return(grading_submission_student_2_question_1)
    allow(StudentGradingSubmission).to receive(:new).with(
      params:,
      student: student_2,
      question: question_2,
      attempt: attempt_student_2,
      activity:,
      instructor:,
      grading_feedback:
    ).and_return(grading_submission_student_2_question_2)
  end

  describe '#submission_valid?' do
    it 'checks that all score fields are valid' do
      grading_submission.submission_valid?

      expect(grading_submission_student_1_question_1).to have_received(:valid?)
      expect(grading_submission_student_1_question_2).to have_received(:valid?)
      expect(grading_submission_student_2_question_1).to have_received(:valid?)
      expect(grading_submission_student_2_question_2).to have_received(:valid?)
    end

    it 'returns true if all the grading submissions are valid' do
      expect(grading_submission.submission_valid?).to be(true)
    end

    it 'returns false if not all the grading submissions are valid' do
      allow(grading_submission_student_2_question_1).to receive(:valid?).and_return(false)

      expect(grading_submission.submission_valid?).to be(false)
    end

    it 'registers invalid scores in an array' do
      allow(grading_submission_student_1_question_2).to receive(:valid?).and_return(false)
      allow(grading_submission_student_2_question_1).to receive(:valid?).and_return(false)

      grading_submission.submission_valid?

      expect(grading_submission.invalid_scores).to contain_exactly(
        grading_submission_student_1_question_2.score_field,
        grading_submission_student_2_question_1.score_field
      )
    end
  end

  describe '#process_submission' do
    it 'validates that all score fields are valid' do
      grading_submission.process_submission

      expect(grading_submission_student_1_question_1).to have_received(:valid?)
      expect(grading_submission_student_1_question_2).to have_received(:valid?)
      expect(grading_submission_student_2_question_1).to have_received(:valid?)
      expect(grading_submission_student_2_question_2).to have_received(:valid?)
    end

    context 'when there are some invalid scores,' do
      before do
        allow(grading_submission_student_1_question_2).to receive(:valid?).and_return(false)
      end

      it 'does not submit any feedback' do
        grading_submission.process_submission

        expect(grading_submission_student_1_question_1).not_to have_received(:submit)
        expect(grading_submission_student_1_question_2).not_to have_received(:submit)
        expect(grading_submission_student_2_question_1).not_to have_received(:submit)
        expect(grading_submission_student_2_question_2).not_to have_received(:submit)
      end

      it 'returns false' do
        expect(grading_submission.process_submission).to be(false)
      end
    end

    context 'when all scores are valid,' do
      it 'submits feedback for every student and question' do
        grading_submission.process_submission

        expect(grading_submission_student_1_question_1).to have_received(:submit)
        expect(grading_submission_student_1_question_2).to have_received(:submit)
        expect(grading_submission_student_2_question_1).to have_received(:submit)
        expect(grading_submission_student_2_question_2).to have_received(:submit)
      end

      it 'returns true' do
        expect(grading_submission.process_submission).to be(true)
      end

      context 'when some students have concurrent enrollment warnings' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'still submits feedback for every student and question' do
          grading_submission.process_submission

          expect(grading_submission_student_1_question_1).to have_received(:submit)
          expect(grading_submission_student_1_question_2).to have_received(:submit)
          expect(grading_submission_student_2_question_1).to have_received(:submit)
          expect(grading_submission_student_2_question_2).to have_received(:submit)
        end

        it 'returns true (CE warnings do not block navigation)' do
          expect(grading_submission.process_submission).to be(true)
        end

        it 'tracks failed CE students' do
          grading_submission.process_submission
          expect(grading_submission.concurrent_enrollment_failures?).to be(true)
        end

        it 'tracks successful students' do
          grading_submission.process_submission
          expect(grading_submission.all_students_failed_ce?).to be(false)
        end
      end

      context 'when all students have concurrent enrollment warnings' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'still submits feedback for every student and question' do
          grading_submission.process_submission

          expect(grading_submission_student_1_question_1).to have_received(:submit)
          expect(grading_submission_student_1_question_2).to have_received(:submit)
          expect(grading_submission_student_2_question_1).to have_received(:submit)
          expect(grading_submission_student_2_question_2).to have_received(:submit)
        end

        it 'returns true (CE warnings do not block navigation)' do
          expect(grading_submission.process_submission).to be(true)
        end

        it 'tracks that all students failed CE' do
          grading_submission.process_submission
          expect(grading_submission.all_students_failed_ce?).to be(true)
        end
      end
    end

    context 'for table_activity with inline_open_ended' do
      let(:activity) { create(:activity, activity_type: 'table_activity') }
      let(:question_klass) do
        MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
      end
      let(:question_1_wol_1) do
        double('WriteOnLine')
      end
      let(:question_1_wol_2) do
        double('WriteOnLine')
      end
      let(:question_2_wol_1) do
        double('WriteOnLine')
      end
      let(:question_1) do
        instance_double(
          question_klass,
          label: 'question_1',
          points_possible:,
          wols: [question_1_wol_1, question_1_wol_2]
        )
      end
      let(:question_2) do
        instance_double(
          question_klass,
          label: 'question_1',
          points_possible:,
          wols: [question_2_wol_1]
        )
      end
      let(:grading_submission_student_1_question_1_wol_1) do
        instance_double(
          StudentGradingSubmission,
          score_field: "score_for_#{question_1.label}_student_#{student_1.id}",
          submit: true,
          valid?: true,
          concurrent_enrollment_ai_bug_detected: false,
          student: student_1
        )
      end
      let(:grading_submission_student_1_question_1_wol_2) do
        instance_double(
          StudentGradingSubmission,
          score_field: "score_for_#{question_1.label}_student_#{student_1.id}",
          submit: true,
          valid?: true,
          concurrent_enrollment_ai_bug_detected: false,
          student: student_1
        )
      end
      let(:grading_submission_student_1_question_2_wol_1) do
        instance_double(
          StudentGradingSubmission,
          score_field: "score_for_#{question_1.label}_student_#{student_1.id}",
          submit: true,
          valid?: true,
          concurrent_enrollment_ai_bug_detected: false,
          student: student_1
        )
      end
      let(:students) { [student_1] }

      before do
        allow(StudentGradingSubmission).to receive(:new).with(
          params:,
          student: student_1,
          question: question_1_wol_1,
          attempt: attempt_student_1,
          activity:,
          instructor:,
          grading_feedback:
        ).and_return(grading_submission_student_1_question_1_wol_1)
        allow(StudentGradingSubmission).to receive(:new).with(
          params:,
          student: student_1,
          question: question_1_wol_2,
          attempt: attempt_student_1,
          activity:,
          instructor:,
          grading_feedback:
        ).and_return(grading_submission_student_1_question_1_wol_2)
        allow(StudentGradingSubmission).to receive(:new).with(
          params:,
          student: student_1,
          question: question_2_wol_1,
          attempt: attempt_student_1,
          activity:,
          instructor:,
          grading_feedback:
        ).and_return(grading_submission_student_1_question_2_wol_1)

        allow(question_1).to receive(:is_a?).with(question_klass).and_return(true)
        allow(question_2).to receive(:is_a?).with(question_klass).and_return(true)
      end

      it 'submits each wol for each student' do
        grading_submission.process_submission

        expect(grading_submission_student_1_question_1_wol_1).to have_received(:submit)
        expect(grading_submission_student_1_question_1_wol_2).to have_received(:submit)
        expect(grading_submission_student_1_question_1).not_to have_received(:submit)
        expect(grading_submission_student_1_question_1).not_to have_received(:submit)
        expect(grading_submission_student_1_question_2).not_to have_received(:submit)
        expect(grading_submission_student_2_question_1).not_to have_received(:submit)
        expect(grading_submission_student_2_question_2).not_to have_received(:submit)
      end
    end
  end

  describe '#concurrent_enrollment_failures?' do
    context 'when process_submission has not been called' do
      it 'returns nil' do
        expect(grading_submission.concurrent_enrollment_failures?).to be_nil
      end
    end

    context 'when process_submission has been called' do
      context 'when no students have concurrent enrollment warnings' do
        it 'returns false' do
          grading_submission.process_submission
          expect(grading_submission.concurrent_enrollment_failures?).to be(false)
        end
      end

      context 'when some students have concurrent enrollment warnings' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'returns true' do
          grading_submission.process_submission
          expect(grading_submission.concurrent_enrollment_failures?).to be(true)
        end
      end
    end
  end

  describe '#all_students_failed_ce?' do
    context 'when process_submission has not been called' do
      it 'returns nil' do
        expect(grading_submission.all_students_failed_ce?).to be_nil
      end
    end

    context 'when process_submission has been called' do
      context 'when no students have concurrent enrollment warnings' do
        it 'returns false' do
          grading_submission.process_submission
          expect(grading_submission.all_students_failed_ce?).to be(false)
        end
      end

      context 'when some students have concurrent enrollment warnings' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'returns false' do
          grading_submission.process_submission
          expect(grading_submission.all_students_failed_ce?).to be(false)
        end
      end

      context 'when all students have concurrent enrollment warnings' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'returns true' do
          grading_submission.process_submission
          expect(grading_submission.all_students_failed_ce?).to be(true)
        end
      end
    end
  end

  describe '#concurrent_enrollment_warning_message' do
    context 'when there are no concurrent enrollment failures' do
      it 'returns nil' do
        grading_submission.process_submission
        expect(grading_submission.concurrent_enrollment_warning_message).to be_nil
      end
    end

    context 'when there are concurrent enrollment failures' do
      context 'with one student having failures' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'returns a message with the student name' do
          grading_submission.process_submission
          expect(grading_submission.concurrent_enrollment_warning_message).to eq(
            'John Doe is enrolled in multiple sections. Navigate to each section to grade submissions.'
          )
        end
      end

      context 'with multiple students having failures' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        it 'returns a message with all student names' do
          grading_submission.process_submission
          expect(grading_submission.concurrent_enrollment_warning_message).to eq(
            'John Doe, Jane Smith are enrolled in multiple sections. Navigate to each section to grade submissions.'
          )
        end
      end

      context 'with multiple students having failures' do
        before do
          allow(grading_submission_student_1_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_1_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_1).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
          allow(grading_submission_student_2_question_2).to receive(:concurrent_enrollment_ai_bug_detected).and_return(true)
        end

        # TODO: Add this spec once the warning message is defined
        # it 'returns a message with all student names' do
        #   grading_submission.process_submission
        #   expect(grading_submission.concurrent_enrollment_warning_message).to eq(
        #     'John Doe, Jane Smith had concurrent enrollment data inconsistency. Please focus to the individual section.'
        #   )
        # end
      end
    end
  end
end
