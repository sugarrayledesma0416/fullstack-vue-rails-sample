require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class ActivityConverter
      include TitleSanitizer
      include Exportable
      def initialize(activity)
        @activity = activity
      end

      def convert
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = sanitize_title(@activity.title)
          item.identifier = '_' + SecureRandom.uuid
          item.resource = MultiVersionCommonCartridge::Resources::BasicLtiLink::BasicLtiLink.new.tap do |lti|
            lti.title = item.title
            lti.identifier = item.identifier + '_r'
            lti.description = ''
            lti.secure_launch_url = secure_launch_url

            lti.vendor.code = VENDOR_CODE
            lti.vendor.name = VENDOR_NAME
            lti.vendor.url = VENDOR_URL
            lti.vendor.contact_email = VENDOR_EMAIL

            lti.extensions << canvas_extension
          end
        end
      end

      def resource_link
        @resource_link ||= Cartridge::ResourceLink.find_or_create(
          @activity.id, :activity, @activity.program
        )
      end
    end
  end
end
