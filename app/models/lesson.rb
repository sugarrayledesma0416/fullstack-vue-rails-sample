class Lesson < ApplicationRecord
  include LessonXML
  include CurrentEventsContent
  include Etl

  belongs_to :unit
  has_many :vocab_words
  has_many :default_vocab_words
  has_many :default_vocabulary_words
  has_many :concepts
  has_many :activities
  has_many :track_groups

  before_save :to_xml
  after_commit :update_gradebook

  scope :by_unit, ->(*units) { where(unit_id: units) }
  scope :non_resource, -> { where(use_type: 'Lesson') }

  def activities(sections: nil, current_user: nil)
    Activity.where(
      id: Services::TocActivityList.all_for_lesson(self.id, sections:, current_user:)
    )
  end

  def strands(include_assessment_strands = false)
    if include_assessment_strands
      toc_entries
    else
      toc_entries.reject{ |toc_entry| toc_entry.assessment? }
    end
  end

  def <=>(other_lesson)
    rank <=> other_lesson.rank
  end

  def toc_location_rank_by_id(toc_location_id)
    unless @toc_location_ranks
      @toc_location_ranks = populate_toc_location_ranks
    end
    @toc_location_ranks[toc_location_id.to_s] || 0
  end

  def toc_entries=(toc_entries)
    @toc_entries = toc_entries
  end

  def strand(strand_id)
    strand_or_substrand_for_toc_location(strand_id)
  end

  def ensure_activities_have_correct_lesson_id
    # This method is called by the publishing process, so there is no need
    # to filter using sections.
    toc_entries.each do |toc_entry|
      toc_entry.descendant_activities.each do |activity|
        next if activity.lesson_id == id

        activity.update!(lesson_id: id)
      end
    end
  end

  def ordered_non_assessment_concepts
    concepts.where(assessment: false).order(:rank)
  end

  def toc_entries
    unless @toc_entries
      from_xml
    end
    @toc_entries
  end

  def components
    @components ||= activities.select('Distinct component_name').where('activities.component_name IS NOT NULL')
  end

  def each_toc_entry
    unless toc_entries
      return
    end

    toc_entries.each do |top_toc_entry|
      top_toc_entry.each do |toc_entry|
        yield(toc_entry)
      end
    end
  end

  def strand_for_toc_location(location)
    location = location.to_s
    strand = toc_entries.detect{|toc_entry| toc_entry.location.to_s == location}
    return strand if strand

    toc_entries.each do |strand|
      strand.each do |toc_entry|
        return strand if toc_entry.location.to_s == location
      end
    end
    return nil
  end

  def substrand_for_toc_location(location)
    location = location.to_s
    toc_entries.each do |strand|
      strand.each do |toc_entry|
        return toc_entry if toc_entry.location.to_s == location && toc_entry.level > 1
      end
    end
    return nil
  end

  def strand_or_substrand_for_toc_location(location)
    ret_val = substrand_for_toc_location(location)
    unless ret_val
      ret_val = strand_for_toc_location(location)
    end
    ret_val
  end

  def activity_list_header(toc_location)
    strand = strand_for_toc_location(toc_location)
    strand_name = strand.name if strand

    list_header = "#{strand_name}"

    substrand = substrand_for_toc_location(toc_location)
    substrand_name = substrand.name if substrand

    list_header << " | #{substrand_name}" if substrand_name

    list_header
  end

  def self.find_strand_by_lesson_and_strand_id(lesson_id, strand_id)
    lesson = Lesson.find_by_id(lesson_id)
    raise "no lesson found with id #{lesson_id}" unless lesson
    strand = nil
    lesson.each_toc_entry do |toc_entry|
      if (toc_entry.location.to_s == strand_id.to_s)
        strand = toc_entry
        break
      end
    end
    strand
  end

  def program
    return nil unless unit
    @program ||= unit.program
  end

  def program_id
    return nil unless unit
    unit.program_id
  end

  def unit_name
    unit.name
  end

  def unit_rank
    unit.rank
  end

  def in_two_tier_program?
    program.two_tier?
  end

  def display_name
    (label.present? && label) || name
  end

  def combined_rank
    # For tier programs the lesson ranks are within the scope of each unit.
    # By creating a value which include the parent unit's rank, we can sort all the lesson in a program
    # 100 is the max number of possible lessons within a unit
    # add 1 so that if try to sort the units and lessons together we will still get a ordered list
    # The result is: u1(100), l1(101), l2(102), u2(200), l3(201), l4(202) ...
    (unit.rank * 100 + rank + 1)
  end

  private

  def populate_toc_location_ranks
    toc_location_ranks = Hash.new
    @current_rank = 1
    toc_entries.each do |toc_entry|
      toc_entry.each do |child_entry|
        toc_location_ranks[child_entry.location.to_s] = @current_rank
        @current_rank += 1
      end
    end
    toc_location_ranks
  end

  def leaf_strand(strand, find_leaf=true)
    if find_leaf && has_strand_with_children?(strand)
        leaf_strand(strand.children.first, find_leaf)
    else
      strand
    end
  end
  private :leaf_strand

  def has_strand_with_children?(strand)
    strand && strand.children.any?
  end
  private :has_strand_with_children?
end
