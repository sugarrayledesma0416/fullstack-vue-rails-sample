module Cartridge
  class ResourceLink < ApplicationRecord
    include Rails.application.routes.url_helpers
    RESOURCE_TYPES = %w[activity resource instructor_vtext student_vtext].freeze
    READER_CND_REGEXP = %r{/reader\.vhlcentral\.com/}
    READER2_REGEXP = %r{/reader2\.vhlcentral\.com/}
    READER3_REGEXP = %r{/reader3\.vhlcentral\.com/}

    self.table_name = 'cartridge_resource_links'
    validates :resource_type, inclusion: {
      in: RESOURCE_TYPES,
      message: '%{value} is not valid resource type'
    }

    validates :resource_id, uniqueness: { scope: :resource_type, case_sensitive: true }

    belongs_to :program

    # Provides a unique identifier named "resource_link_id"
    # for an activity/resource/vtext and stores that relationship in the database.
    # The identifier is then used as part of the link to this "resource" in the
    # Common Cartridge. This resource_link_id is then passed back to vhlcentral when
    # the link is accessed from an LMS.
    def self.find_or_create(resource_id, resource_type, program)
      ResourceLink.find_or_create_by!(resource_id:, resource_type:, program:) do |rl|
        rl.resource_link_id = SecureRandom.uuid
      end
    end

    # when a resource_link_id is passed to vhlcentral in an LMS
    # launch, the information about what is accessed from the link
    # is retrieved using this method. Calling the url method will return
    # the link that can be used in a redirect to open the activity,
    # download the resource, or open a vtext.
    def self.find_by_resource_link_id(resource_link_id)
      ResourceLink.find_by(resource_link_id:)
    end

    # returns the link to use in the redirect to open the activity,
    # download the resource, or open a vtext.
    # returns e.g. cartridge/activities/:id
    # or signed_url to download a resource
    # or link to dls reader - e.g. //reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2"
    # or //reader.vhlcentral.com/portales1e/teacher-edition/vol1_ecompanion-v2"
    def url(user, section)
      case resource_type
      when  'activity' then activity_url(user, section)
      # url built based on type:
      when  'resource' then resource_url(user, section)

      when  'instructor_vtext', 'student_vtext' then vtext_url(section)
      end
    end

    # if plain old activity we get this: "cartridge/activities/:activity_id"
    # if activity of type "link_vtext" we get the url to the vtext
    # that includes the page number to open:
    # e.g. //reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2?rid=977211&page=12"
    private def activity_url(user, section)
      activity = Activity.find(resource_id)
      if activity.activity_type == 'link_vtext'
        vtext_linker = VtextLinker.new(section.course.program, user, activity, section:)
        vtext_linker.link
      else
        cartridge_section_activity_path(section.id, resource_id)
      end
    end

    private def resource_url(user, section)
      # produces a signed url for downloading the resource
      dl_resource = user.downloadable_resource(resource_id, section.course.program, section)
      dl_resource.signed_url
    end

    # gets the reader link from the program settings
    # e.g.//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2"
    private def vtext_url(section)
      settings = ProgramSettings.new(section.course.program)
      if resource_type == 'instructor_vtext'
        teacher_vtext_url(settings.teacher_vtext_link)
      else
        student_vtext_url(settings.vtext_link)
      end
    end

    private def student_vtext_url(vtext_link)
      if vtext_link =~ READER_CND_REGEXP || vtext_link =~ READER3_REGEXP
        vtext_link.gsub('/student-edition/', '/ecompanion/').gsub('_vtext', '_ecompanion')
      elsif vtext_link =~ READER2_REGEXP
        vtext_link.gsub('/student-edition/', '/ecompanionv2/')
      else
        vtext_link
      end
    end

    private def teacher_vtext_url(teacher_vtext_link)
      teacher_vtext_link.gsub('reader2', 'reader3')
    end
  end
end
