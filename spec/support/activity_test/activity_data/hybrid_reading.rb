require 'support/activity_test/activity_data/base_activity'

module ActivityTest
  module ActivityData
    class HybridReading < BaseActivity
      attr_accessor :media_items, :video_filename, :descriptive_audio_filename,
                    :foreign_subtitles_filename, :english_subtitles_filename,
                    :floating_image_filename

      def initialize(activity, media_items)
        super(activity, nil)
        content_object = activity.content_object
        @media_items = media_items
        @video_filename = media_link_filename(content_object.references.first.video)
        @descriptive_audio_filename = media_link_filename(content_object
                                                            .references.first.descriptive_video)
        @foreign_subtitles_filename = media_link_filename(content_object
                                                            .references.first.foreign_subtitles)
        @english_subtitles_filename = media_link_filename(content_object
                                                            .references.first.english_subtitles)
        @floating_image_filename = media_link_filename(content_object
                                                         .floating_image.first.image)
      end

      private def media_link_filename(media_link)
        id = media_link.media_item_id.to_i

        media_item = media_items.find { |item| item.id == id }
        if media_item.nil?
          raise ArgumentError, "Unable to find media_item_video(id: #{id})"
        end
        
        media_item.filename
      end
    end
  end
end
