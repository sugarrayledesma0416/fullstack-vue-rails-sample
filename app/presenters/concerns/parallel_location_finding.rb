module ParallelLocationFinding
  extend ActiveSupport::Concern

  def current_topic(url_params, saved_location)
    current_topic = parallel_toc_location(url_params[:toc_location]) ||
                    most_relevant_topic(url_params[:toc_location],
                                        url_params[:start_strand],
                                        url_params[:start_topic],
                                        saved_location)
    current_topic = default_toc_location if number_of_activities_for_location(current_topic) == 0
    current_topic
  end

  def parallel_or_default_location(toc_location)
    parallel_toc_location = parallel_toc_location(toc_location)
    if parallel_toc_location && number_of_activities_for_location(parallel_toc_location) > 0
      parallel_toc_location
    else
      default_toc_location
    end
  end

  def current_strand(toc_location, saved_location)
    parallel_toc_location(toc_location) ||
      most_relevant_strand(toc_location, saved_location)&.location&.to_s
  end

  def parallel_location(location)
    return unless location
    old_lesson = program.lesson_for_toc_location(location)
    toc_entry = toc_entry_of_location(old_lesson, location)
    return unless toc_entry
    ret_loc = nil

    if toc_entry.level == 2
      ret_loc = parallel_substrand_or_default_strand(old_lesson, location, toc_entry)
    elsif toc_entry.level == 1
      ret_loc = parallel_strand_or_default_strand(toc_entry.title)
    end

    ret_loc
  end

  def parallel_substrand_or_default_strand(previous_lesson, location, toc_entry)
    orig_strand = previous_lesson.strand_for_toc_location(location)
    sub_strand_index = orig_strand.children.index(toc_entry)
    dest_strand = parallel_location(orig_strand.location)
    substrand_location = nil

    if dest_strand
      if dest_strand.children[sub_strand_index]
        substrand_location = dest_strand.children[sub_strand_index]
      elsif dest_strand.children.size > 0
        substrand_location = dest_strand.children.last
      else
        substrand_location = dest_strand
      end
    else
      substrand_location = strands[0]
    end
    substrand_location
  end
  protected :parallel_substrand_or_default_strand

  def parallel_strand_or_default_strand(strand_title)
    strand = strands.detect { |strand| strand.title == strand_title }
    strand = strands[0] unless strand
    strand
  end
  protected :parallel_strand_or_default_strand

  def toc_entry_of_location(lesson, location)
    if lesson
      lesson.strand_or_substrand_for_toc_location(location)
    end
  end
  protected :toc_entry_of_location

  def parallel_toc_location(location)
    toc_entry = parallel_location(location)
    toc_entry.location if toc_entry
  end

  def most_relevant_strand(start_strand, saved_location, find_substrand = true)
    current_strand = nil
    desired_location = nil
    all_strands = strands
    desired_location = parallel_toc_location(saved_location) if saved_location

    if desired_location
      current_strand = all_strands.find { |strand| strand.location.to_s == strand_for_toc_location(desired_location).location }
    elsif start_strand
      current_strand = all_strands.find{|strand| strand.location.to_s == start_strand}
    end
    current_strand ||= leaf_strand(all_strands.first, find_substrand)
  end

  def most_relevant_topic(toc_location, start_strand, start_topic, saved_location)
   return start_topic if start_topic && most_relevant_strand(start_strand, saved_location, false).children.any?{ |entry| entry.location.to_s == start_topic}
   get_toc_location(saved_location,toc_location,start_strand)
  end

  def get_toc_location(saved_location, toc_location_param, start_strand)
    toc_location = nil
    if saved_location
      toc_location = parallel_toc_location(saved_location)
    elsif toc_location_param
      toc_location = toc_location_param
    elsif start_strand
      toc_location = start_strand
    else
      if strands.count >= 1
        default_topic = strands.first
        if default_topic.children.count >= 1
          toc_location = default_topic.children.first.location
        else
          toc_location = default_topic.location
        end
      end
    end
    toc_location
  end
  protected :get_toc_location

  def default_toc_location
    toc_location = ''
    if strands.count >= 1
      if strands.first.children.count >= 1
        toc_location = strands.first.children.first.location
      else
        toc_location = strands.first.location
      end
    end
    toc_location
  end
  protected :default_toc_location

  def number_of_activities_for_location(toc_location)
    Services::TocActivityList.all_for_toc_location(toc_location).count
  end
  protected :number_of_activities_for_location
end
