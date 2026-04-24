class PreviewMediaItem < MediaItem
  after_initialize :readonly!

  attr_accessor :preview_attrs, :media_type

  alias_attribute :desired_media_type, :media_type

  def server_url(_server_host_to_be_ignored)
    ''
  end

  def public_filename
    preview_attrs[:public_filename]
  end

  # This alias is for virtual chat turns, which combine
  # server_url and public_filename_for_arc to generate
  # the complete URL.
  alias public_filename_for_arc public_filename

  # This alias is for recording_v2. The base method that this
  # overrides always prepends the CDN url, resulting in paths like:
  # https://media.maestro.vhlcentral.comhttps//cms.vhlcentral.com/...
  alias public_url_for_arc public_filename

  def width
    preview_attrs[:width].presence && preview_attrs[:width].to_i
  end

  def height
    preview_attrs[:height].presence && preview_attrs[:height].to_i
  end

  def alt_tag
    preview_attrs[:alt_tag]
  end

  def transcript
    preview_attrs[:transcript]
  end
end
