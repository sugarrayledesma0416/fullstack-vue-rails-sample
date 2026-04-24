describe UserDataDeleter do
  describe '#delete_user_data' do
    let(:user) { create(:student) }

    before do
      allow(GradebookEngine::GradebookAPI).to receive(:delete_user_data)
      allow(SubmissionClient::Submission).to receive(:delete)
      allow(Xapi::Statement).to receive(:delete_statements_by_attempt)
      allow_any_instance_of(Xapi::StateDeleter).to receive(:delete)
      allow_any_instance_of(Lossless::Client).to(
        receive(:delete_user_data).and_return(true)
      )
    end

    context 'when no school id is specified' do
      let(:deleter) { described_class.new(user.id) }

      it 'deletes assessment student time limits' do
        # factory for this wasn't allowing me to specify user id.
        AssessmentStudentTimeLimit.create!(user_id: user.id)
        deleter.delete_user_data
        expect(AssessmentStudentTimeLimit.by_student(user)).to be_empty
      end

      it 'deletes composition attachments' do
        create(:composition_attachment, user: user)
        deleter.delete_user_data
        expect(CompositionAttachment.where(user_id: user)).to be_empty
      end

      it 'deletes enrollments' do
        create(:enrollment, user: user)
        deleter.delete_user_data
        expect(Enrollment.by_student(user)).to be_empty
      end

      it 'deletes forum posts' do
        create(:forum_post, user: user)
        deleter.delete_user_data
        expect(ForumPost.where(user_id: user).first).to be_deleted
      end

      it 'deletes help requests' do
        create(:help_request, user: user)
        deleter.delete_user_data
        expect(HelpRequest.by_user(user)).to be_empty
      end

      it 'deletes group chat recordings' do
        recording_path = '/foo.mp4'
        create(:group_chat_recording, user: user, recording_path: recording_path)
        expect_any_instance_of(Aws::S3::Bucket).to(
          receive(:delete_objects).with(
            delete: {
              objects: [
                { key: recording_path }
              ]
            }
          )
        )
        deleter.delete_user_data
        expect(GroupChatRecording.where(user_id: user)).to be_empty
      end

      it 'deletes partner chat recordings' do
        recording_path = '/foo.mp4'
        create(:partner_chat_recording, user: user, recording_path: recording_path)
        expect_any_instance_of(Aws::S3::Bucket).to(
          receive(:delete_objects).with(
            delete: {
              objects: [
                { key: recording_path }
              ]
            }
          )
        )
        deleter.delete_user_data
        expect(PartnerChatRecording.where(user_id: user)).to be_empty
      end

      it 'deletes solo video recordings' do
        recording_path = '/foo.mp4'
        create(:solo_video_recording, user: user, recording_path: recording_path)
        expect_any_instance_of(Aws::S3::Bucket).to(
          receive(:delete_objects).with(
            delete: {
              objects: [
                { key: recording_path }
              ]
            }
          )
        )
        deleter.delete_user_data
        expect(SoloVideoRecording.where(user_id: user)).to be_empty
      end

      context 'when there are no partner chat, group chat or solo video recordings' do
        it 'does not call the S3 API' do
          expect_any_instance_of(Aws::S3::Bucket).not_to receive(:delete_objects)
          deleter.delete_user_data
        end
      end

      it 'deletes audio recordings' do
        create(:recording, user: user)
        deleter.delete_user_data
        expect(Recording.where(user_id: user)).to be_empty
      end

      it 'deletes school user records' do
        create(:school_user, user: user)
        deleter.delete_user_data
        expect(SchoolUser.where(user_id: user)).to be_empty
      end

      it 'deletes server error reports' do
        create(:server_error_report, user: user)
        deleter.delete_user_data
        expect(ServerErrorReport.where(user_id: user)).to be_empty
      end

      it 'deletes sessions' do
        create(:persistent_session, user: user)
        deleter.delete_user_data
        expect(Session.where(user_id: user)).to be_empty
      end

      it 'deletes user settings' do
        create(:setting, user: user)
        deleter.delete_user_data
        expect(Setting.where(user_id: user)).to be_empty
      end

      it 'deletes student spotcheck counts' do
        create(:student_spotcheck_count, user: user)
        deleter.delete_user_data
        expect(StudentSpotcheckCount.where(user_id: user)).to be_empty
      end

      it 'deletes user defined vocab words' do
        create(:user_defined_word, user: user)
        deleter.delete_user_data
        expect(UserDefinedWord.where(user_id: user)).to be_empty
      end

      it 'deletes user readings' do
        create(:user_reading, user: user)
        deleter.delete_user_data
        expect(UserReading.where(user_id: user)).to be_empty
      end

      it 'deletes vocab words' do
        create(:vocab_word, user_id: user.id)
        deleter.delete_user_data
        expect(VocabWord.where(user_id: user)).to be_empty
      end

      it 'deletes worksets' do
        create(:workset, user: user)
        deleter.delete_user_data
        expect(Workset.where(user_id: user)).to be_empty
      end

      it 'deletes audio recordings from the lossless service' do
        expect_any_instance_of(Lossless::Client).to(
          receive(:delete_user_data).with(user.id)
        )
        deleter.delete_user_data
      end

      it 'deletes attempts' do
        create(:attempt, user: user)
        deleter.delete_user_data
        expect(Attempt.by_student(user)).to be_empty
      end

      it 'deletes user work from the submissions service' do
        attempt_a = create(:attempt,
                           user: user,
                           submission_id: 111,
                           saved_submission_id: 222)
        attempt_b = create(:attempt,
                           user: user,
                           submission_id: 333)
        attempt_c = create(:attempt,
                           user: user,
                           saved_submission_id: 444)
        partition_key = attempt_a.submission_partition_key
        args = [
          {
            id: attempt_a.saved_submission_id,
            partition_key: attempt_a.submission_partition_key
          }, {
            id: attempt_a.submission_id,
            partition_key: attempt_a.submission_partition_key
          }, {
            id: attempt_b.submission_id,
            partition_key: attempt_b.submission_partition_key
          }, {
            id: attempt_c.saved_submission_id,
            partition_key: attempt_c.submission_partition_key
          }
        ]
        expect(SubmissionClient::Submission).to receive(:delete).with(args)
        deleter.delete_user_data
      end

      it 'deletes grades' do
        expect(GradebookEngine::GradebookAPI).to receive(:delete_user_data).with(user.id)
        deleter.delete_user_data
      end

      it 'deletes xapi statements' do
        attempt = create(:attempt, user: user)
        expect(Xapi::Statement).to receive(:delete_statements_by_attempt).with(attempt)
        deleter.delete_user_data
      end

      it 'deletes xapi states' do
        attempt = create(:attempt, user: user)
        expect(Xapi::StateDeleter).to receive(:new).with(attempt).and_call_original
        expect_any_instance_of(Xapi::StateDeleter).to receive(:delete)
        deleter.delete_user_data
      end

      it 'deletes the user record' do
        deleter.delete_user_data
        expect(User.find_by(id: user.id)).to be_nil
      end
    end

    context 'when a school id is specified' do
      let(:school) { create(:school) }
      let(:other_school) { create(:school) }
      let(:course) { create(:course, school: school) }
      let(:other_course) { create(:course, school: other_school) }
      let(:section) { create(:section, course: course) }
      let(:other_section) { create(:section, course: other_course) }
      let(:deleter) { described_class.new(user.id, school_id: school.id) }

      before do
        create(:enrollment, user: user, section: section)
        create(:enrollment, user: user, section: other_section)
      end

      it 'deletes assessment student time limits associated with that school' do
        # factory for this wasn't allowing me to specify user id.
        AssessmentStudentTimeLimit.create!(user_id: user.id, section_id: section.id)
        AssessmentStudentTimeLimit.create!(user_id: user.id, section_id: other_section.id)
        deleter.delete_user_data
        expect(
          AssessmentStudentTimeLimit.where(user_id: user, section_id: section)
        ).to be_empty
        expect(
          AssessmentStudentTimeLimit.where(user_id: user, section_id: other_section)
        ).to_not be_empty
      end

      it 'deletes enrollments associated with the school' do
        deleter.delete_user_data
        expect(Enrollment.where(user_id: user, section_id: section)).to be_empty
        expect(
          Enrollment.where(user_id: user, section_id: other_section)
        ).to_not be_empty
      end

      it 'deletes forum posts associated with the school' do
        forum = create(:forum, section: section)
        other_forum = create(:forum, section: other_section)
        create(:forum_post, user: user, forum: forum)
        create(:forum_post, user: user, forum: other_forum)
        deleter.delete_user_data
        expect(ForumPost.where(user_id: user, forum_id: forum).first).to be_deleted
        expect(
          ForumPost.where(user_id: user, forum_id: other_forum).first
        ).to_not be_deleted
      end

      it 'deletes help requests associated with the school' do
        create(:help_request, user: user, section: section)
        create(:help_request, user: user, section: other_section)
        deleter.delete_user_data
        expect(HelpRequest.where(user_id: user, section_id: section)).to be_empty
        expect(
          HelpRequest.where(user_id: user, section_id: other_section)
        ).to_not be_empty
      end

      it 'deletes the associated school user record' do
        create(:school_user, user: user, school: school)
        create(:school_user, user: user, school: other_school)
        deleter.delete_user_data
        expect(SchoolUser.where(user_id: user, school_id: school)).to be_empty
        expect(
          SchoolUser.where(user_id: user, school_id: other_school)
        ).to_not be_empty
      end

      it 'deletes student spotcheck counts associated with the school' do
        create(:student_spotcheck_count, user: user, section: section)
        create(:student_spotcheck_count, user: user, section: other_section)
        deleter.delete_user_data
        expect(
          StudentSpotcheckCount.where(user_id: user, section_id: section)
        ).to be_empty
        expect(
          StudentSpotcheckCount.where(user_id: user, section_id: other_section)
        ).to_not be_empty
      end

      it 'deletes worksets associated with the school' do
        create(:workset, user: user, section: section)
        create(:workset, user: user, section: other_section)
        deleter.delete_user_data
        expect(Workset.where(user_id: user, section_id: section)).to be_empty
        expect(Workset.where(user_id: user, section_id: other_section)).to be_empty
      end

      it 'deletes attempts associated with the school' do
        create(:attempt, user: user, section: section)
        create(:attempt, user: user, section: other_section)
        deleter.delete_user_data
        expect(Attempt.where(user_id: user, section_id: section)).to be_empty
        expect(Attempt.where(user_id: user, section_id: other_section)).to_not be_empty
      end

      it 'deletes user work associated with the school from the submissions service' do
        attempt_a = create(:attempt,
                           user: user,
                           section: section,
                           submission_id: 111,
                           saved_submission_id: 222)
        attempt_b = create(:attempt,
                           user: user,
                           section: section,
                           submission_id: 333)
        create(:attempt,
               user: user,
               section: other_section,
               saved_submission_id: 444)
        partition_key = attempt_a.submission_partition_key
        args = [
          {
            id: attempt_a.saved_submission_id,
            partition_key: attempt_a.submission_partition_key
          }, {
            id: attempt_a.submission_id,
            partition_key: attempt_a.submission_partition_key
          }, {
            id: attempt_b.submission_id,
            partition_key: attempt_b.submission_partition_key
          }
        ]
        expect(SubmissionClient::Submission).to receive(:delete).with(args)
        deleter.delete_user_data
      end

      it 'deletes xapi statements associated with the school' do
        attempt = create(:attempt, user: user, section: section)
        other_attempt = create(:attempt, user: user, section: other_section)
        expect(Xapi::Statement).to receive(:delete_statements_by_attempt).with(attempt)
        expect(Xapi::Statement).to_not(
          receive(:delete_statements_by_attempt).with(other_attempt)
        )
        deleter.delete_user_data
      end

      it 'deletes xapi states associated with the school' do
        attempt = create(:attempt, user: user, section: section)
        other_attempt = create(:attempt, user: user, section: other_section)
        expect(Xapi::StateDeleter).to receive(:new).with(attempt).and_call_original
        expect(Xapi::StateDeleter).to_not(
          receive(:new).with(other_attempt).and_call_original
        )
        expect_any_instance_of(Xapi::StateDeleter).to receive(:delete)
        deleter.delete_user_data
      end
    end
  end
end
