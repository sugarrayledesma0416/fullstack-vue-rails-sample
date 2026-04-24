require 'support/activity_test/activity_data/multiple_choice.rb'
require 'support/activity_test/activity_data/drop_down'
require 'support/activity_test/activity_data/open_ended'
require 'support/activity_test/activity_data/fill_in_the_blanks'
require 'support/activity_test/activity_data/video_v2'
require 'support/activity_test/activity_data/true_false_enhanced'
require 'support/activity_test/activity_data/recording_v2'

module ActivityTest
  module ActivityData
    class MultiType < BaseActivity
      attr_accessor :sub_activities, :dl, :media_items, :title

      def initialize(activity, media_items)
        super(activity, media_items)
        self.title = activity.title
        self.dl = activity.content_object.dl.text.squish
        self.media_items = media_items
        self.sub_activities = activity.content_object.activities.map do |activity|
          case activity
          when MaestroActivityEngine::ActivityContent::TrueFalseEnhancedContent
            ActivityTest::ActivityData::TrueFalseEnhanced.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::MultipleChoiceContent
            ActivityTest::ActivityData::MultipleChoice.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::DropDownContent
            ActivityTest::ActivityData::DropDown.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::OpenEndedContent
            ActivityTest::ActivityData::OpenEnded.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::FillInTheBlanksContent
            ActivityTest::ActivityData::FillInTheBlanks.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::VocabListV2Content
            ActivityTest::ActivityData::VocabListV2.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::VideoV2Content
            ActivityTest::ActivityData::VideoV2.new(activity, media_items)
          when MaestroActivityEngine::ActivityContent::RecordingV2Content
            ActivityTest::ActivityData::RecordingV2.new(activity, media_items)
          else
            raise ArgumentError, "invalid activity content '#{activity}'"
          end
        end
      end

      def sub_activity(number)
        sub_activities[number - 1]
      end

      def questions
        sub_activities.flat_map(&:questions)
      end

      def question(number)
        questions[number - 1]
      end
    end
  end
end
