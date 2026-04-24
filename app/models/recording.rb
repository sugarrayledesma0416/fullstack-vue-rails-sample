class Recording < ApplicationRecord
  has_one :feedback_item
  has_one :vocab_word
  has_one :activity_note
  belongs_to :user, optional: true

  VOLUME_NAME = 'volume_2'

  before_create :set_uuid

  # Returns a file path to be used to save the recording in the server
  # Params:
  # +recording_type+::. Recording type Valid values:  :student / :instructor
  def generate_file_prefix(recording_type = :student)
    uuid_name_prefix = generate_prefix
    "/" + File.join(base_dir(recording_type), date_dirs, uuid_dirs(uuid_name_prefix), uuid_name_prefix)
  end

  def base_dir(recording_type)
    File.join(VOLUME_NAME, target_folder(recording_type))
  end
  private :base_dir

  def date_dirs
    Time.now.strftime('%Y/%m/%d')
  end
  private :date_dirs

  def uuid_dirs(uuid_name_prefix)
    prefix_numbers = uuid_name_prefix.gsub('-', '')
    File.join(prefix_numbers[0, 3],
              prefix_numbers[3, 3],
              prefix_numbers[6, 3],
              prefix_numbers[9, 3])
  end
  private :uuid_dirs

  def target_folder(type)
    case type
    when :instructor then 'instructor_comments'
    when :student then 'student_attempts'
    else
      'student_attempts'
    end
  end
  private :target_folder

  def generate_prefix
    UUIDTools::UUID.random_create.to_s
  end
  private :generate_prefix

  def set_uuid
    self.uuid = recording_path.scan(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/).first
  end
end
