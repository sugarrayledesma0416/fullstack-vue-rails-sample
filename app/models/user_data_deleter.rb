class UserDataDeleter
  attr_reader :user_id, :school_id

  def initialize(user_id, school_id: nil)
    @user_id = user_id
    @school_id = school_id
  end

  def delete_user_data
    if school_id
      delete_assessment_student_time_limits
      delete_enrollments
      delete_forum_posts
      delete_help_requests
      delete_school_users
      delete_student_spotcheck_counts
      delete_worksets
      delete_attempts
    else
      delete_assessment_student_time_limits
      delete_composition_attachments
      delete_enrollments
      delete_forum_posts
      delete_help_requests
      delete_group_chat_recordings
      delete_partner_chat_recordings
      delete_solo_video_recordings
      delete_recordings
      delete_school_users
      delete_server_error_reports
      delete_sessions
      delete_settings
      delete_student_spotcheck_counts
      delete_user_defined_words
      delete_user_readings
      delete_vocab_words
      delete_worksets
      delete_lossless_recordings
      delete_attempts
      delete_grades
      delete_user
    end
  end

  def section_ids_for_school
    @section_ids_for_school ||= Enrollment.joins(section: :course)
                                  .where(courses: { school_id: school_id })
                                  .pluck(:section_id)
  end

  def delete_assessment_student_time_limits
    if school_id
      AssessmentStudentTimeLimit.by_student(user_id)
        .by_section(section_ids_for_school).destroy_all
    else
      AssessmentStudentTimeLimit.by_student(user_id).destroy_all
    end
  end

  def delete_composition_attachments
    # The S3 object associated with the attachment is deleted when the
    # before_destroy hook runs.
    CompositionAttachment.where(user_id: user_id).destroy_all
  end

  def delete_enrollments
    # delete_all is used instead of destroy_all in order to skip the
    # hook that syncs data with Dangerfield.
    if school_id
      Enrollment.by_student(user_id).by_section(section_ids_for_school).delete_all
    else
      Enrollment.by_student(user_id).delete_all
    end
  end

  def delete_forum_posts
    # FIXME: This duplicates ForumPost#delete! but for a batch of posts.
    posts = if school_id
              forum_ids = Forum.where(section_id: section_ids_for_school).pluck(:id)
              ForumPost.where(user_id: user_id, forum_id: forum_ids)
            else
              ForumPost.where(user_id: user_id)
            end
    posts.update_all(deleted: true, text: 'Deleted post')
  end

  def delete_help_requests
    if school_id
      HelpRequest.by_user(user_id).by_section(section_ids_for_school).destroy_all
    else
      HelpRequest.by_user(user_id).destroy_all
    end
  end

  def delete_group_chat_recordings
    recordings = GroupChatRecording.where(user_id: user_id)
    delete_video_recordings(recordings)
  end

  def delete_partner_chat_recordings
    recordings = PartnerChatRecording.where(user_id: user_id)
    delete_video_recordings(recordings)
  end

  def delete_solo_video_recordings
    recordings = SoloVideoRecording.where(user_id: user_id)
    delete_video_recordings(recordings)
  end

  def delete_recordings
    recordings = Recording.where(user_id: user_id)
    recordings.destroy_all
  end

  def delete_school_users
    # delete_all is used instead of destroy_all in order to skip the
    # hook that syncs data with Dangerfield.
    if school_id
      SchoolUser.where(user_id: user_id, school_id: school_id).delete_all
    else
      SchoolUser.where(user_id: user_id).delete_all
    end
  end

  def delete_server_error_reports
    ServerErrorReport.where(user_id: user_id).destroy_all
  end

  def delete_sessions
    Session.where(user_id: user_id).destroy_all
  end

  def delete_settings
    Setting.where(user_id: user_id).destroy_all
  end

  def delete_student_spotcheck_counts
    if school_id
      StudentSpotcheckCount
        .where(user_id: user_id, section_id: section_ids_for_school)
        .destroy_all
    else
      StudentSpotcheckCount.where(user_id: user_id).destroy_all
    end
  end

  def delete_user_defined_words
    UserDefinedWord.where(user_id: user_id).destroy_all
  end

  def delete_user_readings
    UserReading.where(user_id: user_id).destroy_all
  end

  def delete_vocab_words
    VocabWord.where(user_id: user_id).destroy_all
  end

  def delete_worksets
    Workset.where(user_id: user_id).destroy_all
  end

  def delete_lossless_recordings
    unless Lossless::Client.new.delete_user_data(user_id)
      raise "failed to delete lossless recordings for user #{user_id}"
    end
  end

  def delete_xapi_statements(attempts)
    attempts.each do |attempt|
      Xapi::Statement.delete_statements_by_attempt(attempt)
    end
  end

  def delete_xapi_state(attempts)
    attempts.each do |attempt|
      Xapi::StateDeleter.new(attempt).delete
    end
  end

  def delete_attempts
    attempts = if school_id
                 Attempt.by_student(user_id).by_section(section_ids_for_school)
               else
                 Attempt.by_student(user_id)
               end
    submissions = attempts.map do |a|
      partition_key = a.submission_partition_key
      [
        a.saved_submission_id && {
          id: a.saved_submission_id,
          partition_key: partition_key
        },
        a.submission_id && {
          id: a.submission_id,
          partition_key: partition_key
        }
      ]
    end.flatten.compact
    SubmissionClient::Submission.delete(submissions)
    delete_xapi_statements(attempts)
    delete_xapi_state(attempts)
    attempts.destroy_all
  end

  def delete_grades
    GradebookEngine::GradebookAPI.delete_user_data(user_id)
  end

  def delete_user
    # delete is used instead of destroy in order to skip the hook that
    # syncs data with Dangerfield.
    User.find(user_id).delete
  end

  private def delete_video_recordings(recordings)
    # It's invalid to make a call to S3's object deletion endpoint
    # when there are 0 objects to be deleted so we protect against
    # that case here.
    unless recordings.empty?
      # The partner_chat_cdn config value is, unfortunately, a URL.  So,
      # we need to parse out the domain name which corresponds to the
      # bucket name.  A little brittle, but better than adding a
      # somewhat redundant configuration value with the bucket name.
      bucket_name = URI.parse(M3::Application.config.partner_chat_cdn).hostname
      bucket = Aws::S3::Resource.new(region: 'us-east-1').bucket(bucket_name)
      s3_objects = recordings.pluck(:recording_path).map do |name|
        { key: name }
      end
      bucket.delete_objects(delete: { objects: s3_objects })
      recordings.destroy_all
    end
  end
end
