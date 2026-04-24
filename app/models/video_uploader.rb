class VideoUploader < ImageUploader
  include VonageS3Config

  VALID_EXTENSIONS = %w[.mp4 .m4v .mov].freeze
end
