# Magic comment to make strings unmutable.
# frozen_string_literal: true

class VideoChatRecording
  attr_accessor :user_id
  attr_reader :dynamo_object

  POSSIBLE_STATES = { available: 'available', error: 'error', stopped: 'stopped' }.freeze

  def initialize(object:, user_id:)
    @dynamo_object = object
    self.user_id = user_id.to_s
  end

  def primary_key
    [{ archive_id: archive_id }]
  end

  def status
    dynamo_object.dig('status')
  end

  def user_info
    if user_1.dig('id') == user_id
      user_1
    elsif user_2.dig('id') == user_id
      user_2
    end
  end

  def available?
    status == POSSIBLE_STATES[:available]
  end

  def error?
    status == POSSIBLE_STATES[:error]
  end

  def stopped?
    status == POSSIBLE_STATES[:stopped]
  end

  def video_path(format:)
    user_info['video']["video/#{format}"]
  end

  def method_missing(method, *args, &block)
    if dynamo_object.key?(method.to_s)
      dynamo_object[method.to_s]
    else
      super
    end
  end

  def to_json(options = {})
    # Append the 'path' key that is used in the chat client wrapper.
    dynamo_object.merge(path: user_info.dig('video')).to_json(options)
  end
end
