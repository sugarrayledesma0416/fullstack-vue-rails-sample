#encoding: utf-8

require 'toc_entry' unless Object.constants.include?("TocEntry")

class TocEntry
  attr_accessor :id

  def save!; end

  def self.next_factory_location
    @@next_location ||= rand(100..1000)
    (@@next_location += 1).to_s
  end
end

FactoryBot.define do
  factory :toc_entry do
    level { 1 }
    sequence(:title) do |n|
      titles = %w{Contextos Flash\ Cultura Fotonovela Pronunciación Cultura Estructura Adelante}
      titles[n % titles.length]
    end

    sequence(:background_color) do |n|
      background_colors = %w{#ED1C24 #007DC6 #17A46A #5B57A6}
      background_colors[n % background_colors.length]
    end

    sequence(:location) { |n| TocEntry.next_factory_location }
    children { [] }
  end

  factory :assessment_toc_entry, parent: :toc_entry, class: TocEntry do
    assessment { true }
  end

  factory :two_layers_of_toc_entry, parent: :toc_entry, class: TocEntry do
    level { 1 }
    children do |proxy|
      [].fill(0..2) {proxy.association(:toc_entry, :level => 2)}
    end
  end

  factory :toc_entry_with_activities, parent: :toc_entry, class: TocEntry do
    sequence(:location) { |n| TocEntry.next_factory_location }
    after_build do |toc_entry|
      activity_1 = factory(:activity, :toc_location => toc_entry.location, :toc_location_rank => 1)
      activity_2 = factory(:activity, :toc_location => toc_entry.location, :toc_location_rank => 2,
                                            :lesson => activity_1.lesson, :concept => activity_1.concept )
      # TODO: Check that.
      activities = [activity_1, activity_2]
      activities_list = activities
      descendant_activities = activities
    end
  end

  factory :two_layers_of_toc_entries_with_activities, parent: :toc_entry, class: TocEntry do
    level { 1 }
    children do |proxy|
      [].fill(0..1) do
        proxy.association(:toc_entry_with_activities, :level => 2)
      end
    end
  end
end
