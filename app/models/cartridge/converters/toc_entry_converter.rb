require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class TocEntryConverter
      include TitleSanitizer

      # List of activity types that are not exported
      REJECTED_ACTIVITY_TYPES = %w[
        group_chat
        partner_chat
        smart_book
      ].freeze

      def initialize(toc_entry)
        @toc_entry = toc_entry
      end

      def convert
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = sanitize_title(@toc_entry.name)
          item.identifier = '_' + SecureRandom.uuid
          item.children = convert_sub_strands + convert_activities
        end
      end

      private def convert_activities
        activities.map do |activity|
          ActivityConverter.new(activity).convert
        end
      end

      private def activities
        @toc_entry.descendant_activities.reject do |activity|
          REJECTED_ACTIVITY_TYPES.include?(activity.activity_type)
        end
      end

      private def convert_sub_strands
        @toc_entry.children.map do |sub_strand|
          TocEntryConverter.new(sub_strand).convert
        end
      end
    end
  end
end
