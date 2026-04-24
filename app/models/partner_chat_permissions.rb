class PartnerChatPermissions
  attr_accessor :current_user, :recording_path

  STATUS_CODES = { ok: :ok, unauthorized: :unauthorized, missing_path: :unprocessable_entity }

  def initialize(recording_path:, dynamodb_wrapper:, user:)
    self.current_user = user
    self.recording_path = recording_path
    @dynamodb_wrapper = dynamodb_wrapper
  end

  def status_code
    return STATUS_CODES[:missing_path] unless self.recording_path.present?

    if allowed_path.present?
      STATUS_CODES[:ok]
    else
      STATUS_CODES[:unauthorized]
    end
  end

  def allowed_path
    if current_user.student?
      student_allowed_path
    elsif current_user.instructor?
      instructor_allowed_path
    end
  end

  private def relative_path
    @relative_path ||= URI(self.recording_path).path[1..-1]
  end

  private def dynamo_response
    return @dynamo_response if defined?(@dynamo_response)
    # api_key/archive_id/archive.mp4
    archive_id = if relative_path.start_with?(SoloVideoRecordingUploader::USER_UPLOADS_PATH)
                   relative_path
                 else
                   relative_path.split('/')[1] # Grab the archive id from the relative path
                 end
    attributes_to_select = %w{archive_id course_id user_1 user_2 users}

    @dynamo_response = @dynamodb_wrapper.find(primary_key: [{ "archive_id" => archive_id }],
                                              selected_attributes: attributes_to_select).first
  end

  private def student_allowed_path
    dynamo_response
    return if @dynamodb_wrapper.errors?

    user_ids = dynamo_users_data('id')

    if user_ids.include? current_user.id.to_s
      relative_path
    end
  end

  private def instructor_allowed_path
    dynamo_response
    return if @dynamodb_wrapper.errors?

    section_ids = dynamo_users_data('section_id')
    user_ids = dynamo_users_data('id')

    if section_ids.any? { |section_id| current_user.section_can_be_graded?(section_id.to_i) } ||
       user_ids.include?(current_user.id.to_s)
      relative_path
    end
  end

  private def dynamo_users_data(key)
    [dynamo_response.dig('user_1', key), dynamo_response.dig('user_2', key)].tap do |user_data_ids|
      group_chat_partners_data = dynamo_response.dig('users')
      if group_chat_partners_data
        user_data_ids.concat(group_chat_partners_data.map { |partner_data| partner_data[key] })
      end
    end.compact
  end
end
