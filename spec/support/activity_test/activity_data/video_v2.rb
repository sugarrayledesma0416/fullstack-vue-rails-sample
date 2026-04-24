require 'support/activity_test/activity_data/base_activity'

module ActivityTest
  module ActivityData
    class VideoV2 < BaseActivity
      attr_accessor :video_media_items
      attr_accessor :video_media_item_high_res, :video_media_item_low_res

      def initialize(activity, video_media_items)
        super(activity, nil)
        self.video_media_items = video_media_items
        content_object = activity.content_object
        self.video_media_item_high_res = media_link_filename(content_object.high_res_video)
        self.video_media_item_low_res = media_link_filename(content_object.low_res_video)
      end

      private def media_link_filename(media_link)
        id = media_link.media_item_id.to_i
        media_item = video_media_items.find { |item| item.id == id }
        if media_item.nil?
          raise ArgumentError, "Unable to find media_item_video(id: #{id})"
        end
        media_item
      end
    end
  end
end
