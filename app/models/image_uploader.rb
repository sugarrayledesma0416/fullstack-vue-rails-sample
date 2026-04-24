class ImageUploader < MediaItemUploader

  LIMIT_FILE_SIZE = 52428800 # 50mb
  VALID_EXTENSIONS = %w(.gif .jpeg .jpg .png)

  def validate
    errors << "File is too large, maximum file size is #{human_file_size}." if invalid_size?
    errors << "File has invalid extension. Valid extensions are #{self.class::VALID_EXTENSIONS.join(' ')}." if invalid_extension?
    super
  end

  def human_file_size
    ActionController::Base.helpers.number_to_human_size(LIMIT_FILE_SIZE)
  end
  private :human_file_size

  def invalid_extension?
    self.class::VALID_EXTENSIONS.exclude?(File.extname(uploaded_file.original_filename).downcase)
  end
  private :invalid_extension?

  def invalid_size?
    uploaded_file.size > LIMIT_FILE_SIZE
  end
  private :invalid_size?

end
