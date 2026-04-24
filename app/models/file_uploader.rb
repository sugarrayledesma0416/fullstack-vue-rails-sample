class FileUploader < MediaItemUploader
  include UploadFileActivityS3Config

  FILE_SIZE_LIMIT = 52_428_800 # 50mb
  VALID_EXTENSIONS = %w[
    .csv
    .doc
    .docx
    .odp
    .ods
    .odt
    .pages
    .pdf
    .pps
    .ppt
    .pptx
    .rtf
    .txt
    .xls
    .xlsx
  ].freeze

  def validate
    errors << "File is too large, maximum file size is #{human_file_size}." if invalid_size?
    if invalid_extension?
      errors << 'File has invalid extension. Valid extensions are' \
      "#{self.class::VALID_EXTENSIONS.join(' ')}."
    end
    super
  end

  private def human_file_size
    ActionController::Base.helpers.number_to_human_size(FILE_SIZE_LIMIT)
  end

  private def invalid_extension?
    self.class::VALID_EXTENSIONS.exclude?(File.extname(uploaded_file.original_filename).downcase)
  end

  private def invalid_size?
    uploaded_file.size > FILE_SIZE_LIMIT
  end
end
