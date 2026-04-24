class MediaLink
  BULK_ASSIGNABLE_ATTRS = %i[
    desired_media_item_id desired_media_type instructor_uploaded
    line spec preview_attrs media_resize_height transcript_mode
  ].freeze

  PREVIEW_ATTRS = %i[
    public_filename width height alt_tag
  ].freeze

  attr_accessor :desired_media_type, :line, :spec, :activity_id,
                :media_item_id, :instructor_uploaded, :preview_attrs,
                :media_resize_height, :transcript_mode
  attr_reader :desired_media_item_id

  def initialize(params)
    BULK_ASSIGNABLE_ATTRS.each do |key|
      public_send("#{key}=", params[key])
    end

    return unless preview_attrs && preview_attrs[:transcript_mode]

    self.transcript_mode = preview_attrs[:transcript_mode]
  end

  def open?
    media_item_id.blank? || media_item.nil?
  end

  def desired_media_item_id=(media_id)
    self.media_item_id = media_id
  end

  def media_item
    if instructor_uploaded
      InstructorMediaItem.find_by_id(media_item_id)
    else
      if preview_attrs.present?
        PreviewMediaItem.new(
          desired_media_type: desired_media_type,
          preview_attrs: preview_attrs
        )
      else
        MediaItem.find_by_id(media_item_id)
      end
    end
  end

  include MaestroActivityEngine::ActivityContent::SerializeContent

  def attributes
    BULK_ASSIGNABLE_ATTRS + %i[activity_id media_item_id]
  end

  def to_hash
    { self.class.name => attributes.each_with_object({}) { |attr, memo| memo[attr.to_s] = self.send(attr) } }
  end
end
