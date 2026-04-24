class VideoRecording < ApplicationRecord
  has_one :activity_note
  belongs_to :user, optional: true

  before_create :set_uuid

  # Returns a file path to be used to save the recording on the media server
  def generate_file_prefix
    uuid_name_prefix = generate_prefix
    "#{base_dir}#{date_dirs}#{uuid_dirs(uuid_name_prefix)}#{uuid_name_prefix}"
  end

  # Includes the current recording volume
  def base_dir
    "/#{Recording::VOLUME_NAME}/instructor_activity"
  end
  private :base_dir

  def date_dirs
    "/#{Time.now.strftime('%Y/%m/%d')}"
  end
  private :date_dirs

  def uuid_dirs(uuid_name_prefix)
    prefix_numbers = uuid_name_prefix.gsub('-', '')
    "/#{prefix_numbers[0, 3]}/#{prefix_numbers[3, 3]}/"\
    "#{prefix_numbers[6, 3]}/#{prefix_numbers[9, 3]}/"\
  end
  private :uuid_dirs

  def generate_prefix
    UUIDTools::UUID.random_create.to_s
  end
  private :generate_prefix

  def set_uuid
    self.uuid = recording_path.scan(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/).first
  end
  private :set_uuid
end
