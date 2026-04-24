require 'support/activity_test/activity_data/prompt'

module ActivityTest
  module ActivityData
    class BaseActivity
      include PromptParser
      attr_accessor :activity, :dl, :media_items, :title

      def initialize(activity, media_items)
        self.activity = activity
        self.media_items = media_items
        self.title = activity.title.strip
        # When embedding in a multi type activity, the content_object does not exist.
        content_object = activity.respond_to?(:content_object) ? activity.content_object : activity
        self.dl = content_object.dl ? content_object.dl.text.squish : ''
      end
    end
  end
end
