describe FeedbackItem, core: true do
  let(:student) { create(:student) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }
  let(:attempt) do
    create(
      :attempt,
      activity: activity,
      section: section,
      user: student
    )
  end
  let(:question_klass) do
    MaestroActivityEngine::ActivityContent::OpenEnded::Item
  end
  let(:question_1) { instance_double(question_klass, label: 'question_1') }
  let(:question_2) { instance_double(question_klass, label: 'question_2') }
  let(:question_3) { instance_double(question_klass, label: 'question_3') }

  describe 'scopes' do
    let!(:feedback_item) do
      described_class.create!(
        attempt: attempt,
        question_label: question_1.label,
        section: section,
        user: student
      )
    end
    let(:other_student) { create(:student) }
    let(:other_attempt) do
      create(
        :attempt,
        activity: activity,
        section: section,
        user: other_student
      )
    end
    let!(:other_feedback_item) do
      described_class.create!(
        attempt: other_attempt,
        question_label: question_2.label,
        section: section,
        user: other_student
      )
    end

    describe 'emoji removal' do
      it 'removes emojis from inline_corrections and comment before saving' do
        feedback_item = described_class.create!(
          attempt: attempt,
          question_label: "Question",
          section: section,
          user: student,
          inline_corrections: "Correction with emoji 🎉✅",
          comment: "Comment with emoji 🚀🔥"
        )

        expect(feedback_item.reload.inline_corrections).to eq("Correction with emoji")
        expect(feedback_item.reload.comment).to eq("Comment with emoji")
      end

      it 'does not modify text without emojis' do
        feedback_item = described_class.create!(
          attempt: attempt,
          question_label: "Question",
          section: section,
          user: student,
          inline_corrections: "Text without emojis",
          comment: "Comment without emojis"
        )

        expect(feedback_item.reload.inline_corrections).to eq("Text without emojis")
        expect(feedback_item.reload.comment).to eq("Comment without emojis")
      end
    end

    describe '.by_students' do
      it 'returns the feedback items for the student specified' do
        expect(described_class.by_students(student)).to eq([feedback_item])
      end

      it 'returns the feedback items for all students specified' do
        expect(
          described_class.by_students([student, other_student])
        ).to match_array([feedback_item, other_feedback_item])
      end
    end

    describe '.by_attempts' do
      it 'returns the feedback items for the attempt specified' do
        expect(described_class.by_attempts(attempt)).to eq([feedback_item])
      end

      it 'returns the feedback items for all attempts specified' do
        expect(
          described_class.by_attempts([attempt, other_attempt])
        ).to match_array([feedback_item, other_feedback_item])
      end
    end

    describe '.by_questions' do
      it 'returns the feedback items for the question label specified' do
        expect(
          described_class.by_questions(question_1.label)
        ).to eq([feedback_item])
      end

      it 'returns the feedback items for all attempts specified' do
        expect(
          described_class.by_questions([question_1.label, question_2.label])
        ).to match_array([feedback_item, other_feedback_item])
      end
    end

    describe '.by_sections' do
      let(:attempt_2) { create(:attempt) }
      let(:section_2) { create(:section) }
      let!(:feedback_item_2) do
        described_class.create!(
          attempt: attempt_2,
          question_label: question_1.label,
          section: section_2,
          user: other_student
        )
      end

      it 'returns the feedback items for the section specified' do
        expect(described_class.by_sections(section)).to eq(
          [feedback_item, other_feedback_item]
        )
      end

      it 'returns the feedback items for all attempts specified' do
        expect(
          described_class.by_sections([section, section_2])
        ).to match_array(
          [feedback_item, other_feedback_item, feedback_item_2]
        )
      end
    end
  end

  it "removes the attachment's draft flag after saving when attachment is present" do
    s3_bucket = instance_double(Radner::S3Storage, file_exist?: true)
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)

    attachment = create(:composition_attachment)

    feedback_item = create(:feedback_item, attachment_id: attachment.id)

    allow(CompositionAttachment).to receive(:remove_draft_flags_from)

    feedback_item.save!

    expect(CompositionAttachment).to have_received(:remove_draft_flags_from)
      .with(attachment.id)
  end

  describe '.remove_attachment' do
    it 'finds a feedback item record by the attachment_id passed' do
      allow(described_class).to receive(:find_by)

      described_class.remove_attachment(123)

      expect(described_class).to have_received(:find_by).with(attachment_id: 123)
    end

    it 'removes the attachment_id value from the found record' do
      create(:feedback_item, attachment_id: 10)

      described_class.remove_attachment(10)

      expect(described_class.first.attachment_id).to be_nil
    end
  end

  describe '.submit' do
    let(:assignment) { build_stubbed(:assignment) }
    let(:strand) { create(:toc_entry) }

    before do
      allow(activity).to receive(:questions).and_return([question_1, question_2])

      allow(Attempt).to receive(:find_by_student_section_and_activity)
        .and_return(attempt)
      allow(attempt).to receive(:process_instructor_grading)
      allow(attempt).to receive(:assignment).and_return(assignment)
      allow(activity).to receive(:strand).and_return(strand)
      allow(activity).to receive(:title).and_return('activity title')
      allow(assignment).to receive(:grade_availability)
      allow(activity.notifications).to receive(:dispatch)
    end

    def do_submit(params = {})
      opts = {
        activity: activity,
        comment: '',
        feedback_notification: true,
        inline_corrections: '',
        points_earned: 1.0,
        question_label: question_1.label,
        section: section,
        student: student
      }
      described_class.submit(opts.merge(params))
    end

    describe 'feedback notification' do
      let(:feedback_item) do
        described_class.new(attempt:, user: student, section:)
      end

      before do
        allow(described_class).to receive(:new).and_return(feedback_item)
      end

      context 'when no feedback notification exists for that activity,' do
        context 'when feedback_notification is set and grades were set to be available' do
          before do
            allow(assignment).to receive(:grade_availability).and_return(:on_release)
          end

          it 'creates a notification' do
            expect do
              do_submit
            end.to change(ActivityFeedbackNotification, :count).by(1)
          end

          it 'sets the AI flag to false when no AI feature has been used' do
            do_submit

            expect(ActivityFeedbackNotification.last).to have_attributes(
              activity:,
              ai_used: false,
              section:,
              user: student
            )
          end

          it 'sets the AI flag to true when there is an ai generated comment' do
            do_submit(
              feedback_item_ai_comments: { ai_generated_comment: true }
            )

            expect(ActivityFeedbackNotification.last).to have_attributes(
              activity:,
              ai_used: true,
              section:,
              user: student
            )
          end

          it 'sets the AI flag to true when there is an ai generated inline correction' do
            do_submit(
              feedback_item_ai_comments: { ai_generated_inline_corrections: true }
            )

            expect(ActivityFeedbackNotification.last).to have_attributes(
              activity:,
              ai_used: true,
              section:,
              user: student
            )
          end
        end

        it 'does not create a notification when feedback_notification is ' \
           'set to false' do
          allow(assignment).to receive(:grade_availability).and_return(:on_release)

          expect do
            do_submit(feedback_notification: false)
          end.not_to change(ActivityFeedbackNotification, :count)
        end

        it 'does not create a notification when feedback_notification is not set' do
          allow(assignment).to receive(:grade_availability).and_return(:on_release)

          expect do
            do_submit(feedback_notification: nil)
          end.not_to change(ActivityFeedbackNotification, :count)
        end

        it 'does not create a notification when grades were set not to be available' do
          allow(assignment).to receive(:grade_availability).and_return(:never)

          expect do
            do_submit
          end.not_to change(ActivityFeedbackNotification, :count)
        end

        it 'creates a notification if there is no assignment' do
          allow(attempt).to receive(:assignment).and_return(nil)

          do_submit

          expect(ActivityFeedbackNotification.last).to have_attributes(
            activity:,
            ai_used: false,
            section:,
            user: student
          )
        end
      end

      context 'when a no dismissed feedback notification exists for that activity,' do
        let!(:feedback_notification) do
          create(
            :activity_feedback_notification,
            activity:,
            ai_used: false,
            dismissed: false,
            section:,
            user: student
          )
        end

        context 'when feedback_notification is set and grades were set to be available' do
          before do
            allow(assignment).to receive(:grade_availability).and_return(:on_release)
          end

          it 'does not create new notification' do
            expect do
              do_submit
            end.not_to change(ActivityFeedbackNotification, :count)
          end

          context 'when the existing notification does not have the AI flag set,' do
            it 'does not update the notification when no AI feature has been used' do
              expect do
                do_submit
              end.not_to(change { feedback_notification.reload.attributes })
            end

            it 'sets the AI flag to true when there is an ai generated comment' do
              do_submit(
                feedback_item_ai_comments: { ai_generated_comment: true }
              )

              expect(feedback_notification.reload.ai_used).to be(true)
            end

            it 'sets the AI flag to true when there is an ai generated inline correction' do
              do_submit(
                feedback_item_ai_comments: { ai_generated_inline_corrections: true }
              )

              expect(feedback_notification.reload.ai_used).to be(true)
            end
          end

          context 'when the existing notification has the AI flag set,' do
            before do
              feedback_notification.update!(ai_used: true)
            end

            it 'does not update the notification when no AI feature has been used' do
              expect do
                do_submit
              end.not_to(change { feedback_notification.reload.attributes })
            end

            it 'does not update the notification when there is an ai generated comment' do
              expect do
                do_submit
              end.not_to(change { feedback_notification.reload.attributes })
            end

            it 'does not update the notification when there is an ai generated inline correction' do
              expect do
                do_submit
              end.not_to(change { feedback_notification.reload.attributes })
            end
          end
        end
      end

      context 'when a dismissed feedback notification exists for that activity,' do
        let!(:feedback_notification) do
          create(
            :activity_feedback_notification,
            activity:,
            ai_used: false,
            dismissed: true,
            section:,
            user: student
          )
        end

        it 'destroys the existing notification' do
          do_submit

          expect(Notification.where(id: feedback_notification.id)).not_to exist
        end

        it 'creates a new notification' do
          do_submit

          expect(ActivityFeedbackNotification.last).to have_attributes(
            activity:,
            ai_used: false,
            section:,
            user: student
          )
        end
      end
    end

    context 'when no feedback_item record exists for the current student and question,' do
      let(:instructor) { create(:instructor) }
      let(:expected_recording_path) { 'recording_file_path' }
      let(:params) do
        {
          activity: activity,
          comment: '',
          current_user: instructor,
          feedback_notification: false,
          inline_corrections: '',
          points_earned: 1.0,
          question_label: question_1.label,
          recording_path: expected_recording_path,
          section: section,
          student: student
        }
      end

      it 'creates a recording' do
        feedback_item = create(:feedback_item)
        allow(feedback_item).to receive(:update_recording)

        allow(described_class).to receive(:new).and_return(feedback_item)

        do_submit(params)

        expect(feedback_item).to have_received(:update_recording).with(
          instructor, expected_recording_path
        )
      end

      it 'creates a new record with specified user, section, and question label' do
        do_submit(params)

        feedback_item = described_class.where(user_id: student.id).first

        expect(feedback_item).to have_attributes(
          attempt: attempt,
          question_label: question_1.label,
          section: section
        )
      end

      it "does not create a recording if instructor didn't record a comment" do
        do_submit(params.merge(recording_path: ''))
        feedback_item = described_class.where(user_id: student.id).first
        expect(feedback_item.recording).to be_nil
      end

      it 'updates the points_earned, inline_corrections, and comment ' \
         'attributes of the new feedback record' do
        expected_points_earned = '5.5'
        expected_corrections = 'inline_corrections_text'
        expected_comment = 'comment_text'
        do_submit(
          params.merge(
            comment: expected_comment,
            inline_corrections: expected_corrections,
            points_earned: expected_points_earned
          )
        )
        feedback_item = described_class.where(user_id: student.id).first
        expect(feedback_item).to have_attributes(
          comment: expected_comment,
          inline_corrections: expected_corrections,
          points_earned: expected_points_earned.to_f
        )
      end

      it "sets attachment_id value when it's been submitted" do
        expected_attachment_id = 436

        do_submit(params.merge(attachment_id: expected_attachment_id))

        feedback_item = described_class.find_by(user_id: student.id)
        expect(feedback_item.attachment_id).to eq(expected_attachment_id)
      end

      it 'sets the ai_generated_comment attribute when it has been submitted' do
        do_submit(
          params.merge(
            feedback_item_ai_comments: { ai_generated_comment: true }
          )
        )

        feedback_item = described_class.find_by(user_id: student.id)

        expect(feedback_item.ai_generated_comment?).to be(true)
      end

      it 'sets the ai_generated_comment attribute to false when it has not been submitted' do
        do_submit(params)

        feedback_item = described_class.find_by(user_id: student.id)

        expect(feedback_item.ai_generated_comment?).to be(false)
      end

      it 'creates a new recording for given instructor and recording path' do
        do_submit(recording_path: 'recording_path')

        feedback_item = described_class.where(user_id: student.id).first

        expect(Recording.find(feedback_item.recording.id)).not_to be_nil
      end

      it 'tells the attempt to process instructor grading' do
        do_submit(params)

        expect(attempt).to have_received(:process_instructor_grading)
      end

      it 'uses the attempt object passed in params if present' do
        do_submit(params.merge(attempt: attempt))

        expect(Attempt).not_to have_received(:find_by_student_section_and_activity)
      end
    end

    context 'when a feedback_item record already exists for the current student and question,' do
      let(:instructor) { create(:instructor) }
      let(:recording) do
        create(:recording, user: instructor, recording_path: 'recording_path')
      end
      let(:params) do
        { feedback_notification: false }
      end
      let(:feedback_item) do
        create(:feedback_item, attempt: attempt, recording: recording)
      end

      it 'create or update a recording' do
        recording_path = 'recording_path'
        expected_points_earned = '5.5'
        expected_corrections = 'inline_corrections_text'
        expected_comment = 'comment_text'

        allow(feedback_item).to receive(:update_recording)
        allow(attempt).to receive(:feedback_item).and_return(feedback_item)

        do_submit(
          params.merge(
            comment: expected_comment,
            current_user: instructor,
            inline_corrections: expected_corrections,
            points_earned: expected_points_earned,
            recording_path: recording_path
          )
        )

        expect(feedback_item).to have_received(:update_recording)
          .with(instructor, recording_path)
      end

      it 'updates the points_earned, inline_corrections, and ' \
         'comment attributes of the existing feedback record' do
        expected_points_earned = '5.5'
        expected_corrections = 'inline_corrections_text'
        expected_comment = 'comment_text'

        do_submit(
          params.merge(
            comment: expected_comment,
            inline_corrections: expected_corrections,
            points_earned: expected_points_earned
          )
        )

        result = described_class.find_by(user_id: student.id)

        expect(result).to have_attributes(
          comment: expected_comment,
          inline_corrections: expected_corrections,
          points_earned: expected_points_earned.to_f
        )
      end

      it 'updates the ai_generated_comment attribute when it has been submitted' do
        do_submit(
          params.merge(
            feedback_item_ai_comments: { ai_generated_comment: true }
          )
        )

        feedback_item = described_class.find_by(user_id: student.id)

        expect(feedback_item.ai_generated_comment?).to be(true)
      end

      it 'does not update the ai_generated_comment attribute when it has not been submitted' do
        do_submit(params)

        feedback_item = described_class.find_by(user_id: student.id)

        expect(feedback_item.ai_generated_comment?).to be(false)
      end

      it 'tells the attempt to process instructor grading' do
        do_submit(params.merge(inline_corrections: '', comment: ''))

        expect(attempt).to have_received(:process_instructor_grading)
      end

      it 'uses the attempt object passed in params if present' do
        do_submit(params.merge(attempt: attempt))

        expect(Attempt).not_to have_received(:find_by_student_section_and_activity)
      end
    end
  end

  describe '#update_recording' do
    let(:instructor) { create(:instructor) }
    let(:recording) do
      create(:recording, user: instructor, recording_path: 'recording_path')
    end
    let(:feedback_item) { create(:feedback_item, attempt: attempt) }

    before do
      allow(activity).to receive(:questions).and_return([question_1, question_2])
      allow(Attempt).to receive(:find_by_student_section_and_activity)
        .and_return(attempt)
      allow(attempt).to receive(:process_instructor_grading)
      allow(feedback_item).to receive(:new_recording)
    end

    it 'creates a new recording when recording is blank' do
      recording_path = 'recording_path'

      feedback_item.update_recording(instructor, recording_path)

      expect(feedback_item).to have_received(:new_recording)
        .with(instructor, recording_path)
    end

    it 'creates a new recording when recording path is different from ' \
       'recording path saved' do
      new_recording_path = 'new_recording_path'
      allow(feedback_item).to receive(:recording).and_return(recording)

      feedback_item.update_recording(instructor, new_recording_path)

      expect(feedback_item).to have_received(:new_recording)
        .with(instructor, new_recording_path)
    end

    it 'does not create a new recording when new_recording_path is an ' \
       'empty string and there is an existing recording' do
      new_recording_path = ''
      allow(feedback_item).to receive(:recording).and_return(recording)

      feedback_item.update_recording(instructor, new_recording_path)

      expect(feedback_item).not_to have_received(:new_recording)
    end

    it 'does not create a new recording when new_recording_path is blank ' \
       'string and there is an existing recording' do
      new_recording_path = nil
      allow(feedback_item).to receive(:recording).and_return(recording)

      feedback_item.update_recording(instructor, new_recording_path)

      expect(feedback_item).not_to have_received(:new_recording)
    end
  end

  describe '#find_number_of_questions_graded_for_students' do
    let(:student_list) { [student_1.id, student_2.id, student_3.id] }
    let(:student_1) { create(:student, id: 1) }
    let(:student_2) { create(:student, id: 2) }
    let(:student_3) { create(:student, id: 3) }
    let(:other_attempt) { create(:attempt, user: student_2) }
    let(:attempt_ids) { [attempt.id, other_attempt.id] }

    let(:grading_set) do
      GradingSet.new(student_id_list: student_list.join(','))
    end

    before do
      described_class.create!(
        user_id: student_1.id,
        section_id: section.id,
        attempt_id: attempt.id,
        question_label: question_1.label,
        points_earned: 10
      )
      described_class.create!(
        user_id: student_1.id,
        section_id: section.id,
        attempt_id: attempt.id,
        question_label: question_2.label,
        points_earned: 10
      )
      described_class.create!(
        user_id: student_2.id,
        section_id: section.id,
        attempt_id: other_attempt.id,
        question_label: question_1.label,
        points_earned: 10
      )
      @result = described_class.find_number_of_questions_graded_for_students(
        student_list, attempt_ids, [question_1, question_2]
      )
    end

    it 'eturns a hash with the number of questions graded for each student' do
      result = described_class.find_number_of_questions_graded_for_students(
        student_list, attempt_ids, [question_1, question_2]
      )
      expect(result).to eq(
        student_1.id.to_s => 2,
        student_2.id.to_s => 1,
        student_3.id.to_s => 0
      )
    end

    it 'returns only data for the questions passed' do
      result = described_class.find_number_of_questions_graded_for_students(
        student_list, attempt_ids, [question_2]
      )
      expect(result).to eq(
        student_1.id.to_s => 1,
        student_2.id.to_s => 0,
        student_3.id.to_s => 0
      )
    end
  end

  describe '#find_number_of_students_graded_for_questions' do
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:questions) { [question_1, question_2, question_3] }
    let(:student_list) { [student_1.id, student_2.id] }
    let(:other_attempt) { create(:attempt, user: student_2) }
    let(:attempt_ids) { [attempt.id, other_attempt.id] }
    let(:grading_set) { GradingSet.new(student_id_list: student_list.join(',')) }

    context 'when there are feedback items for the questions' do
      before do
        create(
          :feedback_item,
          attempt: attempt,
          points_earned: 10,
          question_label: question_1.label,
          section: section,
          user: student_1
        )
        create(
          :feedback_item,
          attempt: attempt,
          points_earned: 10,
          question_label: question_2.label,
          section: section,
          user: student_1
        )
        create(
          :feedback_item,
          attempt: other_attempt,
          points_earned: 7.5,
          question_label: question_1.label,
          section: section,
          user: student_2
        )
      end

      it 'returns the number of students graded for each question' do
        result = described_class.find_number_of_students_graded_for_questions(
          questions, attempt_ids
        )

        expect(result).to eq(
          question_1.label => 2,
          question_2.label => 1,
          question_3.label => 0
        )
      end
    end

    context 'when there are no feedback items for the questions' do
      it 'returns zero students graded for each question' do
        result = described_class.find_number_of_students_graded_for_questions(
          questions, attempt_ids
        )

        expect(result).to eq(
          question_1.label => 0,
          question_2.label => 0,
          question_3.label => 0
        )
      end
    end
  end

  describe '.find_student_points_earned_for_question' do
    it 'returns the points earned for a given question' do
      allow(described_class).to receive_message_chain(
        :by_question_user_and_attempt, :first
      )
      expect(described_class).to receive(:by_question_user_and_attempt)
        .with(question_1, student.id, attempt)

      described_class.find_student_points_earned_for_question(
        question_1, student.id, attempt
      )
    end
  end

  describe '.find_corrections_and_comment_and_points_earned_and_recording_for_question' do
    it 'returns the points earned, and comment, and inline_corrections for ' \
       'a given question' do
      allow(described_class).to receive_message_chain(
        :by_question_user_and_attempt, :first
      )
      expect(described_class).to receive(:by_question_user_and_attempt)
        .with(question_1, student.id, attempt)
      described_class.find_corrections_and_comment_and_points_earned_and_recording_for_question(
        question_1, student.id, attempt
      )
    end
  end

  describe '.find_feedback_for_question' do
    it 'returns the feedback items for a given user and attempt and question' do
      other_attempt = create(:attempt)
      other_student = create(:student)
      users = [student, other_student]
      attempts = [attempt, other_attempt]
      feedback_items = [
        create(
          :feedback_item,
          attempt: attempts.first,
          question_label: question_1.label,
          user: users.first
        ),
        create(
          :feedback_item,
          attempt: attempts.last,
          question_label: question_1.label,
          user: users.last
        )
      ]
      expect(
        described_class.find_feedback_for_question(question_1.label, users, attempts)
      ).to match(feedback_items)
    end
  end

  describe '.find_comment_for_question' do
    it 'returns the comment for a given question' do
      allow(described_class).to receive_message_chain(
        :by_question_user_and_attempt, :first
      )

      expect(described_class).to receive(:by_question_user_and_attempt)
        .with(question_1, student.id, attempt)

      described_class.find_comment_for_question(
        question_1, student.id, attempt
      )
    end
  end
end
