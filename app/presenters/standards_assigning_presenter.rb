class StandardsAssigningPresenter
  attr_accessor :activity, :assignments_by_activity, :current_program, :sections
  attr_reader :current_course, :standard_guids_for_init, :error_msg

  include Rails.application.routes.url_helpers
  include TimeHandler
  include ActivityStandardHashable
  include ActivityStandardsLookup

  def initialize(
    current_program,
    sections = nil,
    current_course,
    selected_standards: nil,
    standard_set_vendor_guid: nil,
    search_term: nil,
    standard_ids_for_init: nil,
    selected_units: [],
    selected_skills: [],
    selected_refinements: [],
    selected_content_type: [],
    next_key: nil
  )
    @assignments_by_activity = {}
    @current_program = current_program
    @sections = sections
    @current_course = current_course
    @selected_standards = selected_standards
    @standard_set_vendor_guid = standard_set_vendor_guid
    @search_term = search_term
    guid_finder = StandardGuidsFinder.new(standard_ids_for_init)
    @standard_guids_for_init = guid_finder.vendor_guids
    @error_msg = guid_finder.error if guid_finder.error
    @selected_units = selected_units
    @selected_skills = selected_skills
    @selected_refinements = selected_refinements
    @selected_content_type = selected_content_type
    @standard_ids_for_init = standard_ids_for_init
    @next_key = next_key
  end

  def matching_standards
    standard_set_guids = StandardSet.where(vendor_guid: @standard_set_vendor_guid)
                                    .pluck(:vendor_guid)

    if standard_set_guids.empty?
      raise(StandardError, 'No valid standard_set vendor_guid(s) provided')
    end

    results = searcher.search_standards(
      standard_set_guids,
      @search_term,
      current_program.standard_grade_levels,
      current_program.id
    )

    # StandardsSearch returns a string explaining the problem on non 200 status.
    # Otherwise, retuns an Array.
    raise(StandardError, results) unless results.is_a?(Array)

    results.to_json
  end

  def browse_standards
    standard_set_guids = StandardSet.where(vendor_guid: @standard_set_vendor_guid)
                                    .pluck(:vendor_guid)

    if standard_set_guids.empty?
      raise(StandardError, 'No valid standard_set vendor_guid(s) provided')
    end

    searcher.browse_standards(
      standard_set_guids,
      current_program.standard_grade_levels,
      current_program.id
    )
  end

  def preload_standards_filter
    return {} unless @standard_ids_for_init && Standard.where(id: @standard_ids_for_init).present?

    preload_standard_set = Standard.find(@standard_ids_for_init).standard_set.vendor_guid

    results = searcher.search_standards(
      [preload_standard_set],
      '*',
      current_program.standard_grade_levels,
      current_program.id
    )

    # StandardsSearch returns a string explaining the problem on non 200 status.
    # Otherwise, retuns an Array.
    raise(StandardError, results) unless results.is_a?(Array)

    results.to_json
  end

  def toc
    # TODO: versions of this for Lesson and Unit/Lesson type programs. MVP unit books only.
    { units: current_program.units.map { |unit| { id: unit.id, name: unit.name } },
      concepts: current_program.concepts.each_with_object({}) do |con, hash|
        hash[con.id] = con.name
      end }.to_json
  end

  def program_toc_type
    # TODO: don't hard code this.
    'unit'
  end

  def available_sets
    @current_course.standard_sets.pluck(:display_name).sort.uniq
  end

  def available_browse_std_sets
    set_objs = @current_course.standard_sets.pluck(
      :display_name, :name, :vendor_guid, :adopt_year
    ).map do |display_name, name, vendor_guid, adopt_year|
      {
        vendor_guid:,
        display_name:,
        name:,
        adopt_year:
      }
    end
    set_objs.uniq.sort_by { |set_obj| set_obj[:display_name] }
  end

  def available_grades_for_browse
    current_program.standard_grade_levels.map do |grade|
      display_grade = case grade
                      when 'PK'
                        'Pre-Kindergarten'
                      when 'K'
                        'Kindergarten'
                      else
                        "Grade #{grade}"
                      end
      { display_grade:, grade: }
    end
  end

  # this method is needed here in order
  def due_dates_for_sections
    return [] unless sections

    AssignmentSet.dates_for_sections(sections)
  end

  def assets_and_standards_payload
    items = aligned_items
    return { aligned_items: {}.to_json, standards_info: {}.to_json } unless items

    {
      aligned_items: items.to_json,
      standards_info: aligned_standards.to_json,
      next_key: matching_assets.last.to_json
    }
  end

  private def matching_assets
    @matching_assets ||= fetch_matching_assets
  end

  private def fetch_matching_assets
    # assets_searcher returns results from OpenSearch structure like this:
    # [{:standard_asset_id=>3, :reference_type=>"Activity", :reference_id=>225601}]

    results = searcher.search_standard_assets(
      @selected_standards,
      current_program.id,
      {
        unit_id: selected_units,
        next_key: @next_key,
        selected_skills: @selected_skills,
        selected_refinements: @selected_refinements,
        selected_content_type: @selected_content_type
      }
    )

    # StandardsSearch returns a string explaining the problem on non 200 status.
    # Otherwise, retuns an Array.
    raise(StandardError, results) unless results.is_a?(Array)

    results
  end

  private def searcher
    @searcher ||= StandardsMapping::StandardsSearch.new
  end

  private def selected_units
    return [current_program.units.first.id] if @selected_units.empty?

    @selected_units
  end

  private def aligned_standards
    # {
    #   standards: { # hash of standard ids to standard name, description
    #     123: {
    #       name: 'standard name',
    #       description: 'description'
    #     },
    #     124: {
    #       name: 'standard name',
    #       description: 'description'
    #     }
    #   },
    #   standard_sets: { # hash of standard set ids to standard name, description
    #     456: {
    #       name: 'standard set name',
    #       description: 'descriptions'
    #     },
    #     457: {
    #       name: 'standard set name',
    #       description: 'description'
    #     }
    #   }
    # }
    return {} unless grouped_standard_alignments

    standard_guids = grouped_standard_alignments.keys.flat_map do |key|
      grouped_standard_alignments[key].pluck(:standardGuid)
    end.uniq

    standards = Standard.where(vendor_guid: standard_guids).includes(:standard_set)

    {
      standards: standards_hash(standards),
      standard_sets: standard_sets_hash(standards)
    }
  end

  private def standards_hash(standards)
    standards
      .as_json(only: %i[vendor_guid name description label number], methods: :display_number)
      .index_by { |s| s['vendor_guid'] }
      .deep_symbolize_keys
  end

  private def standard_sets_hash(standards)
    standards
      .map(&:standard_set)
      .as_json(only: %i[vendor_guid name description issuer display_name])
      .index_by { |standard_set| standard_set['vendor_guid'] }
      .deep_symbolize_keys
  end

  private def aligned_items
    # payload structure:
    #
    # Group by Unit, Lesson, Concept, Activity
    # Assign a default value for each hash to avoid
    # overwriting values on duplicate keys (unit_lesson_concept_hash)
    # Example:
    # {
    #   '123': # unit id
    #    {
    #      '345': # lesson id
    #       {
    #         '765': # concept id
    #          [{}, {}, {}] # Array of activity alignment data hashes
    #       }
    #    }
    # }

    @aligned_items ||= AlignmentItemSorter.new(
      cms_activity_ids,
      grouped_standard_alignments,
      matching_assets,
      current_program,
      sections,
      te_item_ids,
      @vtext_linker,
      @assignment_validator
    ).process(unit_lesson_concept_hash)
  end

  private def cms_activity_ids
    # list of cms_activity_ids from Open Search results
    @cms_activity_ids ||= matching_assets.map do |item|
      cms_activity_id(item)
    end.compact
  end

  def grouped_standard_alignments
    @grouped_standard_alignments ||= grouped_alignments(standard_alignments)
  end

  private def vista_online_learning?
    @vista_online_learning ||= current_program.vista_online_learning
  end

  private def standard_alignments
    @standard_alignments ||= fetch_alignments(standard_asset_ids, course_standard_set_guids)
  end

  private def course_standard_set_guids
    @course_standard_set_guids ||= @current_course.standard_sets.pluck(:vendor_guid)
  end

  private def standard_asset_ids
    @standard_asset_ids ||= matching_assets.pluck(:standard_asset_id)
  end

  private def te_item_ids
    # list of teacher edition item ids from Open Search results
    @te_item_ids ||= matching_assets.map do |item|
      te_item_id(item)
    end.compact
  end

  private def unit_lesson_concept_hash
    @unit_lesson_concept_hash ||= Hash.new do |unit_hash, unit_key|
      unit_hash[unit_key] = Hash.new do |lesson_hash, lesson_key|
        lesson_hash[lesson_key] = Hash.new do |concept_hash, concept_key|
          concept_hash[concept_key] = []
        end
      end
    end
  end

  class StandardGuidsFinder
    attr_reader :error

    def initialize(ids)
      @ids = ids
      @error = nil
    end

    def vendor_guids
      return standard_vendor_guids(@ids.split(',')) if @ids

      []
    end

    private def standard_vendor_guids(ids_array)
      Standard.find(ids_array).map(&:vendor_guid)
    rescue ActiveRecord::RecordNotFound
      @error = 'No matching standards found.'
      ['error']
    end
  end

  class AlignmentItemSorter
    attr_reader :cms_activity_ids, :grouped_standard_alignments, :program,
                :sections, :te_item_ids, :matching_assets

    include Rails.application.routes.url_helpers
    include ActivityStandardHashable

    def initialize(
      cms_activity_ids,
      grouped_standard_alignments,
      matching_assets,
      program,
      sections,
      te_item_ids,
      vtext_linker,
      assignment_validator
    )
      @cms_activity_ids = cms_activity_ids
      @grouped_standard_alignments = grouped_standard_alignments
      @matching_assets = matching_assets
      @program = program
      @sections = sections
      @te_item_ids = te_item_ids
      @assignments_by_activity = {}
      @vtext_linker = vtext_linker
      @assignment_validator = assignment_validator
    end

    def process(unit_lesson_concept_hash)
      activities_and_alignments.each_with_object(unit_lesson_concept_hash) do |act_and_aligns, _obj|
        act = act_and_aligns[:activity]
        unit_id = act.lesson.unit.id
        lesson_id = act.lesson_id
        concept_id = act.concept_id

        aligned_item = item(act,
                            act_and_aligns[:reference_type],
                            act_and_aligns[:alignments]).tap do |memo|
                              memo[:standardAssetIds] = act_and_aligns[:standard_asset_ids]
                            end
        unit_lesson_concept_hash[unit_id][lesson_id][concept_id] << aligned_item
      end
      unit_lesson_concept_hash
    end

    def activities_and_alignments
      # Loop over matching_assets (results from Open Search).
      # matching_assets looks like this: (example has an Activity and an AssessmentItem type result)
      # [
      #   {
      #     :standard_asset_id =>3,
      #     :reference_type=>"Activity",
      #     :reference_id=>225601 (cms_activity_id of an activity)
      #   },
      #   {
      #     :standard_asset_id => 4,
      #     :reference_type=>"AssessmentItem",
      #     :reference_id=> 1234 (id of an AssessmentItem)
      #   }
      # ]
      #
      # Return an array of aligned asset data,
      # which looks like this:
      # [
      #   {
      #     activity: #<Activity>,
      #     alignments: [
      #       {
      #         :standardSetGuid=> "a standard set guid",
      #         :standardGuid=> "a standard guid",
      #         :standardSetDisplayName=> "a display name"
      #       }
      #     ],
      #     reference_type: 'Activity',
      #   },
      #   {
      #     activity: #<Activity>,
      #     alignments: [
      #       {
      #         :standardSetGuid=> "a standard set guid",
      #         :standardGuid=>"a standard guid",
      #         :standardSetDisplayName=> "a display name"
      #       }
      #     ],
      #     reference_type: 'AssessmentItem',
      #   }
      # ]
      @activities_and_alignments ||= ordered_activities.each_with_object([]) do |item, arr|
        # grouped_activities will not contain a key for cms_activity_ids that
        # have a nil toc location upon lookup. Skip if cms_activity_id key is not found.
        item_id = (cms_activity_id(item).presence || "te_#{te_item_id(item)}").to_s
        next unless grouped_activities[item_id]

        activity = grouped_activities[item_id]

        # Multiple StandardAssets may point to a single activity
        # via the 'AssessmentItem' reference_type. If an item with
        # this activity id already exists, merge the alignment data into
        # the existing item.

        # note: This code could use a refactor to take advantage of a data structure
        # where duplicates are not allowed, instead of doing this check as the array
        # is constructed.
        is_duplicate_activity = arr.any? do |elm|
          activity.id == elm[:activity].id && activity.is_a?(elm[:activity].class)
        end

        if is_duplicate_activity
          arr.each do |elm|
            if activity.id == elm[:activity].id
              merged = elm[:alignments] + grouped_standard_alignments[item[:standard_asset_id].to_s]
              # Set will expel duplicate alignment hashes.
              set = Set.new(merged)
              # overwrite this activity's alignment key with the merged alignment data.
              elm[:alignments] = set.to_a
              elm[:standard_asset_ids] << item[:standard_asset_id]
            end
          end
        else
        arr.push(
          {
            activity: grouped_activities[item_id],
            alignments: grouped_standard_alignments[item[:standard_asset_id].to_s],
            reference_type: item[:reference_type],
            standard_asset_ids: [item[:standard_asset_id]]
          }
        )
        end
      end.compact
    end

    private def ordered_activities
      matching_assets.sort_by do |asset|
        item_asset_id = (cms_activity_id(asset).presence || "te_#{te_item_id(asset)}").to_s
        activity_asset = grouped_activities[item_asset_id]
        if activity_asset.nil?
          0
        elsif activity_asset.is_a?(EReaderItem)
          2
        elsif activity_asset.assignments.where(section_id: sections.pluck(:id)).any?
          activity_asset.instance_eval { @assigned = true }
          1
        else
          -1
        end
      end
    end

    private def grouped_activities
      return @grouped_activities if defined?(@grouped_activities)

      # Query for activities & associated lesson, unit & concept data.
      # Filter out any activities with a nil toc location.
      # Select by current program.
      # Bucket into hash with cms_activity_id as keys.
      # (making assumption that there will not be duplicated reference_ids)
      # example:
      # {
      #   "1" => #<Activity id: 132, cms_activity_id: 1 ...>,
      #   "2" => #<Activity id: 345, cms_activity_id: 2 ...>
      # }
      te_items ||=
        EReaderItem
        .where(id: te_item_ids)
        .index_by { |te| "te_#{te.id}" }

      activities_and_assessments ||=
        Activity
        .has_toc_location
        .where(cms_activity_id: cms_activity_ids)
        .by_program(program.id)
        .includes(lesson: :unit)
        .includes(:concept)
        .index_by { |act| act.cms_activity_id.to_s }

      @grouped_activities = activities_and_assessments.merge(te_items)
    end

    private def vista_online_learning?
      @vista_online_learning ||= program.vista_online_learning
    end
  end
end
