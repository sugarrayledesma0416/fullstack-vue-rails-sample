class CompositionAttachment < ApplicationRecord
  include Radner::FilesS3Bucket

  belongs_to :user
  has_one :feedback_item,
          foreign_key: :attachment_id,
          inverse_of: :composition_attachment

  attr_accessor :file

  FILE_SIZE_LIMIT = 10_485_760

  validates :file_name, :user_id, presence: true

  validate :allowed_file_extension, on: :create
  validate :file_size_within_limit, on: :create

  before_validation :set_filename_from_tempfile
  before_save :sanitize_file_name
  after_save :perform_upload, unless: :has_file?
  after_save :change_attachment_location, if: :saved_change_to_user_id?
  # after_save  :change_attachment_location, if: :user_id_changed?

  before_destroy :delete_file

  scope :expired_drafts, -> { where(draft: true).where(['created_at < ?', 1.day.ago]) }

  def self.remove_draft_flags_from(ids_array)
    where(id: ids_array).each do |attachment|
      new_attributes = { draft: false }
      if attachment.replaces_attachment_id?
        previous_attachment = find_by_id(attachment.replaces_attachment_id)
        previous_attachment && previous_attachment.destroy_by_user(attachment.user)
        new_attributes[:replaces_attachment_id] = nil
      end
      attachment.update!(new_attributes)
    end
  end

  def file_path
    file_path_for_user_id(user_id)
  end

  def destroy_by_user(current_user)
    return false unless owned_by?(current_user)

    FeedbackItem.remove_attachment(attachment_id = id)
    destroy
  end

  def owned_by?(user)
    user_id == user.id
  end

  def downloadable_by?(user, section)
    owned_by?(user) || section.has_instructor?(user) || is_feedback_from_instructor?(user, section)
  end

  private def file_path_for_user_id(attachment_user_id)
    File.join(
      'composition_attachments',
      M3::Application.config.current_deployed_env_name,
      attachment_user_id.to_s,
      id.to_s,
      file_name
    )
  end

  private def change_attachment_location
    old_user_id = user_id_before_last_save
    return unless old_user_id && file_exists?(file_path_for_user_id(old_user_id))

    move_file(file_path_for_user_id(old_user_id).to_s)
  end

  private def set_filename_from_tempfile
    self.file_name = @file.original_filename if @file
  end

  private def perform_upload
    upload_file(@file) if @file
  rescue StandardError => e
    errors.add(:base, e.message)
    raise ActiveRecord::Rollback
  end

  private def file_size_within_limit
    return unless uploaded_file_present?
    return if File.size(@file.path) <= FILE_SIZE_LIMIT

    errors.add(:base, 'File size must be 10 MB or smaller.')
  end

  private def allowed_file_extension
    return unless uploaded_file_present?

    allowed_file_types = FileType.allowed.collect(&:extension_name).map(&:downcase)
    file_extension = File.extname(file_name).gsub('.', '').downcase
    return if allowed_file_types.include?(file_extension)

    errors.add(
      :base,
      "You tried to upload a file with extension '#{file_extension}', " \
      'which is not allowed.'
    )
  end

  private def uploaded_file_present?
    @file && File.exist?(@file.path)
  end

  private def is_feedback_from_instructor?(downloading_user, section)
    # Attachment is instructor's feedback and one of his students wants to download it
    downloading_user.student? &&
    user.instructor? &&
    section.has_instructor?(user) &&
    downloading_user.active_section?(section)
  end
end
