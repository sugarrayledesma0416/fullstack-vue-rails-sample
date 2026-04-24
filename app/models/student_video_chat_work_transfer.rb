class StudentVideoChatWorkTransfer
  DYNAMODB_TABLE = 'tokbox-recordings'.freeze
  POSSIBLE_USER_KEYS = %w[user_1 user_2].freeze

  attr_accessor :attempt, :new_section_id

  delegate :errors?, :error_messages, to: :dynamodb_wrapper

  def initialize(attempt:, new_section_id:)
    self.attempt = attempt
    self.new_section_id = new_section_id
  end

  def process
    return unless existing_record
    return if user_key.nil? && activity_type != 'group_chat'

    case activity_type
    when 'partner_chat', 'solo_video_recording'
      update_user_section
    when 'group_chat'
      if user_key
        update_user_section
      else
        update_group_chat_partner_section
      end
    end
  end

  private def update_user_section
    dynamodb_wrapper.update(
      primary_key: primary_key,
      item_updates: {
        user_key => existing_record[user_key].merge(
          'section_id' => new_section_id.to_s
        )
      }
    )
  end

  private def update_group_chat_partner_section
    group_chat_partners_data = existing_record['users']
    other_partners_data = group_chat_partners_data.reject do |partner_data|
      partner_data['id'] == attempt.user_id.to_s
    end
    user_data_to_update = (group_chat_partners_data - other_partners_data).first
    if user_data_to_update
      dynamodb_wrapper.update(
        primary_key: primary_key,
        item_updates: {
          'users' => other_partners_data + [
            user_data_to_update.merge('section_id' => new_section_id.to_s)
          ]
        }
      )
    end
  end

  private def user_key
    return @user_key if defined? @user_key

    @user_key = POSSIBLE_USER_KEYS.detect do |key|
      existing_record.dig(key, 'id') == attempt.user_id.to_s
    end
  end

  private def primary_key
    { archive_id: archive_id }
  end

  private def dynamodb_wrapper
    @dynamodb_wrapper ||= DynamoWrapper.new(table: DYNAMODB_TABLE)
  end

  private def existing_record
    return @existing_record if defined? @existing_record

    @existing_record = dynamodb_wrapper.find(
      primary_key: [primary_key],
      selected_attributes: POSSIBLE_USER_KEYS + ['users']
    ).first
  end

  private def archive_id
    recording_path = attempt_result[:response].recording_path
    relative_path = URI(recording_path).path[1..-1]
    # relative_path = api_key/archive_id/archive.mp4
    archive_id = relative_path.split('/')[1]
  end

  private def attempt_result
    # attempt.results is always a single value array for PartnerChats because
    # there is always only 1 question for a PartnerChat
    attempt.results.first
  end

  private def activity_type
    @activity_type ||= attempt.activity.activity_type
  end
end
