# encoding: utf-8

class Program < ApplicationRecord
  include StrandsByName

  self.ignored_columns = %w[vista_online_learning]

  has_many  :courses
  has_many  :grading_sets
  has_many  :units, -> { where(use_type: 'Unit').order('units.rank') }
  has_many  :units_and_resource_units, -> { order('units.rank') }, class_name: 'Unit'
  has_one   :current_events_unit, -> { where(use_type: 'CurrentEvents') },
            class_name: 'Unit'
  has_many  :lessons, -> { order('lessons.rank') }, through: :units
  has_many  :program_media_items
  has_many  :media_items, through: :program_media_items
  has_many  :resources
  has_many  :resource_components, -> { order(:name) }
  has_many  :concepts
  has_many  :help_requests
  has_many  :activity_notes
  has_many  :track_groups
  has_many  :school_program_admin_users
  has_many  :study_plan_concepts, dependent: :destroy

  belongs_to :vocab_program_group, autosave: true, optional: true
  has_many  :program_to_program_mappings, foreign_key: 'dest_program_id'

  before_create :build_program_group

  def lessons_covered
    # Needed for StrandsByName module implementation
    browsable_lessons
  end

  def supports_standards?
    supported_standard_sets&.present?
  end

  def build_program_group
    self.build_vocab_program_group unless vocab_program_group
  end
  private :build_program_group

  def logo_media
    item = program_media_items.logo.first
    item && item.media_item
  end

  validate :subtitle_columns_both_nil_or_both_not_nil

  delegate :ai_grading_feature_enabled?, to: :program_settings, allow_nil: true
  delegate :ai_program_level, to: :program_settings, allow_nil: true
  delegate :has_vocab_words?, to: :program_settings, allow_nil: true
  delegate :has_vocab_tools?, to: :program_settings, allow_nil: true
  delegate :vocab_tools_label, to: :program_settings, allow_nil: true
  delegate :ebook_label, to: :program_settings, allow_nil: true
  delegate :standard_grade_levels, to: :program_settings
  delegate :has_study_center?, to: :program_settings, allow_nil: true
  delegate :has_audio_transcripts?, to: :program_settings, allow_nil: true
  delegate :has_speech_rec?, to: :program_settings, allow_nil: true
  delegate :content_menu_additional_entries, to: :program_settings, allow_nil: true
  delegate :allow_assessments_randomization?, to: :program_settings, allow_nil: true
  delegate :question_banks_enabled?, to: :program_settings, allow_nil: true
  delegate :practice_test_analytics_enabled?, to: :program_settings, allow_nil: true
  delegate :pmr_standard_reports_allowed?, to: :program_settings, allow_nil: true
  delegate :share_to_portfolio?, to: :program_settings, allow_nil: true
  delegate :show_skills_and_refinement_filters?, to: :program_settings, allow_nil: true
  delegate :enable_concurrent_enrollment?, to: :program_settings, allow_nil: true
  delegate :supported_standard_set_ids, to: :program_settings, allow_nil: true
  delegate :supported_standard_sets, to: :program_settings, allow_nil: true

  def find_student_resource_for_section(resource_id, section)
    resources.find_student_resource_for_section(resource_id, section)
  end

  def find_student_resource(resource_id)
    resources.find_student_resource(resource_id)
  end

  def open_m3_courses
    courses.collect { |course| course if course.program.maestro3? && course.open? }.compact
  end

  def current_events_lesson
    return unless current_events_unit
    current_events_unit.lessons.first
  end

  def language_name
    Language.names_from_codes(language_code)
  end

  def small_image_path
    "/images/programs/small_50/#{image_filename}"
  end

  def image_path
    "/images/programs/medium_173/#{image_filename}"
  end

  def maestro3?
    maestro_version == 3
  end

  def maestro2?
    maestro_version == 2
  end

  # We need to denormalize so that there is a FK of program_id on
  # activity records.
  def activities(sections: nil, include_instructor_content: false, current_user: nil)
    @activities ||= Activity.where(
      id: Services::TocActivityList.all_for_program(
        self,
        sections:,
        include_instructor_content:,
        current_user:
      )
    )
  end

  def activities_with_toc_location
    @activities_with_toc_location ||= Activity.
      where(lesson_id: lessons).
      where('toc_location is not null')
  end

  def has_ai_virtual_chat_activities?
    activities.where(activity_type: 'ai_virtual_chat').exists?
  end

  def assessments(sections:, current_user:)
    assessments = []
    lessons.each do |lesson|
      lesson.extend(LessonWithAssessmentStrands)
      assessments << lesson.strands.collect do |strand|
        strand.activities_list(sections:, current_user:)
      end
    end
    assessments.flatten
  end

  def strands
    lessons.flat_map { |lesson| lesson.strands(show_assessment_strands = true) }
  end

  def content_types_selection_list
    [
      ['Activities', 'Activities'],
      ['Assessment', 'Assessment'],
      ['Activities and assessment', 'Activities and assessment']
    ]
  end

  def components(include_instructor_content: true, current_user: nil)
    @components ||= activities(
      include_instructor_content:,
      current_user:
    ).distinct.pluck(:component_name).compact
  end

  def maestro2_url
    return '' unless maestro2?
    raise 'invalid vhlcentral_subdomain' if vhlcentral_subdomain.blank?

    # LOCAL_M2_URL_PREFIX constant examples: 'qa2.' 'karl.'
    # if needed, should be defined in unversioned local file /config/initializers/local_config.rb
    local_m2_prefix = ''
    local_m2_prefix = LOCAL_M2_URL_PREFIX if defined? LOCAL_M2_URL_PREFIX

    "http://#{local_m2_prefix}#{vhlcentral_subdomain}.vhlcentral.com/home/?SS=on"
  end

  RE_MAESTRO2_SUBDOMAIN = /http:\/\/(?:[^\.]+\.)?([^\.]+)\.vhlcentral\.com/

  ORDINAL_STRINGS = ['First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth']

  def self.find_from_url(vhlcentral_url = '')
    return if vhlcentral_url.blank?

    match = RE_MAESTRO2_SUBDOMAIN.match(vhlcentral_url)
    subdomain = match[1]
    find_by_vhlcentral_subdomain(subdomain)
  end

  def numeric_edition_title
    edition_title = title.dup
    ORDINAL_STRINGS.each_with_index do |ordinal_string, index|
      edition_title.gsub!(/#{ordinal_string} Edition/, "#{(index+1).ordinalize} Edition")
    end
    edition_title
  end

  def title_for_sort
    regex = '^([¡]|&iexcl;)'
    sort_title = title.gsub(/#{regex}/, '').downcase
    sort_title.gsub!(' uno', ' 1')
    sort_title.gsub!(' dos', ' 2')
    sort_title.gsub!(' tres', ' 3')
    #sort_title << " #{edition}"
    sort_title
  end

  # TODO: move this method to TocPresenterCommon since it's
  # only called there
  def lesson_for_toc_location(location)
    browsable_lessons.each do |lesson|
      toc_entry = lesson.strand_or_substrand_for_toc_location(location)
      return lesson if toc_entry
    end
    nil
  end

  def has_pronto?
    return false unless program_settings

    program_settings.has_pronto?
  end

  def has_reference_links?
    return false unless reference_links

    !reference_links.empty?
  end

  def reference_links
    return [] unless program_settings
    return @reference_links if @reference_links

    @reference_links = program_settings.links
  end

  def dictionary_path
    return @dictionary_path if defined?(@dictionary_path)

    if reference_links
      reference_links.each do |ref|
        @dictionary_path = ref[:link] if ref[:label] == 'Dictionary'
      end
    else
      @dictionary_path = '#0'
    end
    @dictionary_path
  end

  def best_start_unit_rank(start_unit_rank, list_of_units = units)
    best_start_unit(start_unit_rank, list_of_units).rank
  end

  def best_start_unit(start_unit_rank, list_of_units = units, trial_access = false)
    start_unit = browsable_units(list_of_units).detect do |unit|
      unit.rank.to_s == start_unit_rank.to_s
    end

    if start_unit.present?
      start_unit
    elsif trial_access
      best_trial_access_unit(list_of_units)
    else
      list_of_units.first
    end
  end

  def best_display_lesson(lesson_id, start_unit_rank, list_of_units = units, trial_access = false)
    lesson = best_lesson(list_of_units, lesson_id)

    if lesson.present?
      lesson
    else
      start_unit = best_start_unit(start_unit_rank, list_of_units, trial_access)
      start_unit.lessons.present? ? start_unit.lessons.first : list_of_units.first.lessons.first
    end
  end

  def browsable_lessons(lesson_collection = nil)
    browsable_collection(:lesson, lesson_collection)
  end

  def browsable_units(unit_collection = nil)
    browsable_collection(:unit, unit_collection)
  end

  def browsable_collection(type, collection)
    item_collection = (collection || method("#{type}s").call).to_a
    current_events_item = method("current_events_#{type}").call
    if current_events_item && !item_collection.include?(current_events_item)
      item_collection.push(current_events_item)
    end
    item_collection
  end

  def toc_unit_label
    return unit_label.downcase unless unit_label.blank?
    "unit"
  end

  def multi_unit_resource_label
    "Multi-#{unit_label.downcase}"
  end

  def two_tier?
    return @two_tier if defined?(@two_tier)

    @two_tier = units.count < lessons.count
  end

  def visible_units(can_view_unreleased = false)
    if can_view_unreleased
      units
    else
      units.released
    end
  end

  def visible_units_and_resource_units(can_view_unreleased = false)
    if can_view_unreleased
      units_and_resource_units
    else
      units_and_resource_units.released
    end
  end

  def visible_lessons(can_view_unreleased = false)
    unit_ids = visible_units(can_view_unreleased).collect(&:id)
    lessons.by_unit(*unit_ids).includes(:unit).sort_by(&:combined_rank)
  end

  def has_vocab_tutorials?
    activities.exists?(
      activity_type: %w[vocabulary_tutorial vocabulary_tutorial_v2 vocabulary_tutorial_v3]
    )
  end

  def vista_online_learning?
    return @vista_online_learning if defined?(@vista_online_learning)

    @vista_online_learning = family == 'vista_online_learning'
  end

  def supersite_junior?
    family == 'supersites_jr'
  end

  def spr?
    family == 'spr'
  end

  # In the future, this could become a column in the programs table.
  def audience
    if supersite_junior?
      :elementary
    else
      :default
    end
  end

  def full_source_image
    return nil unless image_filename.present?

    if Rails.env.live?
      "#{Rails.application.config.action_controller.asset_host}" \
      "/assets/images/programs/medium_173/#{image_filename}"
    else
      "https://assets.maestro.vhlcentral.com/assets/images/programs/medium_173/" \
      "#{image_filename}"
    end
  end

  alias vista_online_learning vista_online_learning?

  private def program_settings
    return @program_settings if @program_settings
    begin
      @program_settings = ProgramSettings.new(self)
    rescue
       return nil
    end
    @program_settings
  end

  private def best_lesson(list_of_units, lesson_id)
    browsable_units(list_of_units).flat_map(&:lessons).detect do |lesson|
      lesson.id.to_s == lesson_id.to_s
    end
  end

  private def best_trial_access_unit(list_of_units)
    # With trial access we want to display a unit that is not News and Cultural Updates (NCU)
    # nor the first unit.  NCU units are mostly at the end of the units list, but this avoids
    # the few that are first and skips the first unit as many times it is not the best
    # representation of content for a program.
    #
    # Skip NCU and the first normal unit OR go to the third normal unit.
    if list_of_units.count > 2
      list_of_units.third
    # Otherwise, give the last unit (second or first) if that is all that's available.
    # This catches newly released programs that have limited content for trial access.
    else
      list_of_units.last
    end
  end

  private def subtitle_columns_both_nil_or_both_not_nil
    only_language_code_blank = title_part_sub.present? && title_part_sub_language_code.nil?
    only_subtitle_blank = title_part_sub.nil? && title_part_sub_language_code.present?
    return unless only_language_code_blank || only_subtitle_blank

    errors.add('title_part_sub and title_part_sub_language_code must be either both nil or both not nil.')
  end
end
