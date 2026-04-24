class AnnouncementSection < ApplicationRecord
  belongs_to :announcement
  belongs_to :section

  class AnnouncementSectionsAttributesBuilder
    attr_reader :focus, :author, :announcement

    def initialize(current_focus, current_user, announcement)
      @focus = current_focus
      @user =  current_user
      @announcement = announcement
    end

    def build
      attributes = []
      focus.sections.map do |section|
        attributes << { section_id: section.id }
      end

      if announcement && announcement.announcement_sections.any?
        announcement.announcement_sections.map do |announcement_section|
          attributes << { :id => announcement_section.id, '_destroy' => true }
        end
      end
      attributes
    end

    def self.build(current_focus, current_user, announcement)
      new(current_focus, current_user, announcement).build
    end
  end
end
