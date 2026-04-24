require 'builder'

module Vitalsource
  # This is an abstracti base class, not meant to be instantiated directly.
  class BaseConsumer
    private def client
      @client ||= Client.new(@access_token)
    end

    private def new_xml_body
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      xml
    end

    private def config
      Vitalsource.config
    end
  end
end
