
class TocEntry
  attr_accessor :title, :children, :level, :location, :page, :short_title, :background_color, :singular_label, :id
  attr_writer :assessment

  def initialize
    @children = []
  end

  def each &block
    block.call(self)
    children.each do |child|
      child.each(&block)
    end
  end

  def each_leaf &block
    if children.length == 0
      block.call(self)
    end
    children.each do |child|
      child.each_leaf(&block)
    end
  end

  def topic_location_in_children?(topic_location)
    children.map(&:location).include?(topic_location)
  end
  def display_name
    return title if short_title.blank?
    short_title
  end

  def activities_list(sections:, current_user:)
    Activity.where(
      id: Services::TocActivityList.all_for_toc_location([location], sections:, current_user:)
    ).order('toc_location_rank ASC')
  end

  def name
    short_title.present? && short_title || title
  end

  def descendant_activities(sections: nil, current_user: nil)
    locations = []
    each do |toc_entry|
      locations << toc_entry.location if toc_entry.location.present?
    end
    activities = Activity.where(
      id: Services::TocActivityList.all_for_toc_location(locations, sections:, current_user:)
    ).order('toc_location_rank ASC')

    sorted_activities = []
    locations.each do |location|
      location_activities = activities.select{|activity| activity.toc_location.to_s == location.to_s}
      sorted_activities.concat(location_activities.sort_by(&:toc_location_rank))
    end
    sorted_activities
  end

  def assessment?
    !!@assessment
  end

  private



end
