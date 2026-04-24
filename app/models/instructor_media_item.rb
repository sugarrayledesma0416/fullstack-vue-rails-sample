class InstructorMediaItem < ApplicationRecord
  include MediaItemLocation
  include ImageDimensions
  include InstructorMediaItemStorage

  MAX_IMAGE_WIDTH = 880
  CDN_URL_PREFIX = MediaItem::CDN_URL_PREFIX

  attr_accessor :temp_file_path, :original_filename

  before_save :set_extname, if: :file_changed?
  before_save :resize, if: :oversized_image?
  after_save :store_remote_file, if: :file_changed?
  after_save :set_dimensions, if: :image?
  after_save :set_filesize, if: :file_changed?

  def self.create_from_temp_file(reference)
    InstructorMediaItem.create(
      instructor_id: reference['instructor_id'],
      media_type: 'image',
      original_filename: reference['original_filename'],
      temp_file_path: reference['temp_file_path']
    )
  end

  # Added for compatibility with helpers/views that render MediaItem
  def alt_tag
    ''.freeze
  end

  # Added for compatibility with helpers/views that render MediaItem
  def long_description; end

  # File's final destination. For files stored on s3, this is the
  # s3 object key with no leading slash.
  def file_path
    File.join(file_directory, filename)
  end

  alias full_filename file_path
  alias public_url_for_arc public_filename

  private def file_changed?
    temp_file_path.present? && original_filename.present?
  end

  private def file_directory
    File.join(media_type_dir, dir_chunk)
  end

  private def filename
    "#{id_string}#{extname}"
  end

  private def image?
    media_type == 'image'
  end

  private def image_file_path
    public_filename
  end

  private def media_type_dir
    # We are reusing all the existing media item
    # logic for storing media items.
    # MediaItemLocation has some of it.
    File.join('instructor_created', super)
  end

  private def oversized_image?
    image? && source_file.width > MAX_IMAGE_WIDTH
  end

  # rubocop:disable Rails/UnknownEnv
  private def path_prefix
    if Rails.env.live?
      CDN_URL_PREFIX
    elsif defined? MEDIA_BUCKET_URL
      MEDIA_BUCKET_URL
    else
      'https://media.qa2.vhlcentral.com'
    end
  end
  # rubocop:enable Rails/UnknownEnv

  private def resize
    source_file.resize(MAX_IMAGE_WIDTH)
    s3_bucket.store_file_contents!(temp_file_path, source_file.to_blob)
  end

  private def set_extname
    self.extname = File.extname(original_filename).downcase
  end

  # rubocop:disable Rails/SkipsModelValidations
  private def set_filesize
    update_column(:size, remote_file_size)
  end
  # rubocop:enable Rails/SkipsModelValidations

  private def remote_file_size
    if image?
      source_file.size
    else
      s3_bucket.content_length(file_path)
    end
  end

  private def source_file
    @source_file ||= MiniMagick::Image.read(s3_bucket.fetch(temp_file_path))
  end
end
