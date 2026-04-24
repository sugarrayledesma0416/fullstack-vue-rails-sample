module StandardsMapping
  class StandardAssetExporter
    include Enumerable
    CMS_URL = 'https://cms.vhlcentral.com'.freeze
    M3_URL = 'https://m3a.vhlcentral.com'.freeze

    def initialize(program_id, asset_type = 'activity')
      @program = Program.find(program_id)
      @asset_type = asset_type
      @rows = fetch_assets.map(&:compact)
    end

    def each(&)
      @rows.each(&)
    end

    private def fetch_assets
      case @asset_type
      when 'activity'
        fetch_standard_assets_for_activities
      when 'assessment-item'
        fetch_standard_assets_for_assessments
      when 'te-content'
        fetch_standard_assets_for_te_content
      else
        []
      end
    end

    private def fetch_standard_assets_for_activities
      activities = filtered_activities
      activities.map do |activity|
        next unless activity.standard_asset

        lesson = activity.lesson
        standard_asset = activity.standard_asset
        standard_alignments = activity.standard_asset.standard_alignments
        {
          'guid' => standard_asset.vendor_guid,
          'client_id' => activity.cms_activity_id.to_s,
          'title' => format_field(activity.activity_title),
          'unit_name' => format_field(lesson&.unit&.name),
          'lesson_name' => format_field(lesson&.name),
          'strand_name' => format_field(activity.concept&.name),
          'component_name' => format_field(activity.component_name),
          'activity_type' => activity.activity_type,
          'domain' => format_field(standard_asset.additional_attrs[:domain]),
          'subdomain' => format_field(standard_asset.additional_attrs[:subdomain]),
          'program_ids' => fetch_program_ids(activity.cms_activity_id),
          'mapped_item_type' => 'Activity',
          'content_url' => "#{CMS_URL}/activities/#{activity.cms_activity_id}",
          'm3_url' => "#{M3_URL}/sections/0/activities/#{activity.activity_id}",
          'standards_id_list' => standard_alignments.map(&:vendor_standard_guid).join(',')
        }
      end.compact
    end

    private def fetch_standard_assets_for_assessments
      assessment_items = AssessmentItem
                         .where(assessment_id: filtered_activities.pluck(:cms_activity_id))
                         .includes(:standard_asset)
      assessment_items.map do |assessment_item|
        next unless assessment_item.standard_asset

        assessment = fetch_assessment_by_program(assessment_item.assessment_id)
        assessment_details = fetch_assessment_details(assessment_item.assessment_id)

        formatted_unit_names = assessment_details.map do |detail|
          "#{detail[:program_id]} - #{format_field(detail[:unit_name])}"
        end.join(', ')

        formatted_lesson_names = assessment_details.map do |detail|
          "#{detail[:program_id]} - #{format_field(detail[:lesson_name])}"
        end.join(', ')

        formatted_strand_names = assessment_details.map do |detail|
          "#{detail[:program_id]} - #{format_field(detail[:concept_name])}"
        end.join(', ')

        standard_asset = assessment_item.standard_asset
        standard_alignments = assessment_item.standard_asset.standard_alignments
        {
          'guid' => standard_asset.vendor_guid,
          'client_id' => assessment_item.guid.to_s,
          'title' => format_field(assessment.title),
          'units' => formatted_unit_names,
          'lessons' => formatted_lesson_names,
          'strands' => formatted_strand_names,
          'component_name' => format_field(assessment.component_name),
          'activity_type' => assessment.activity_type,
          'domain' => format_field(standard_asset.additional_attrs[:domain]),
          'subdomain' => format_field(standard_asset.additional_attrs[:subdomain]),
          'program_ids' => fetch_program_ids(assessment_item.assessment_id),
          'mapped_item_type' => 'AssessmentItem',
          'content_url' => "#{CMS_URL}/activities/#{assessment_item.assessment_id}",
          'm3_url' => "#{M3_URL}/sections/0/activities/" \
                      "#{assessment.id}?activate_guid_viewer=true",
          'standards_id_list' => standard_alignments.map(&:vendor_standard_guid).join(',')
        }
      end.compact
    end

    private def fetch_standard_assets_for_te_content
      ereader_items = EReaderItem
                      .where(concept_id: @program.concepts.pluck(:id))
                      .includes(:standard_asset)

      ereader_items.map do |ereader_item|
        next unless ereader_item.standard_asset

        standard_asset = ereader_item.standard_asset
        standard_alignments = ereader_item.standard_asset.standard_alignments
        {
          'guid' => standard_asset.vendor_guid,
          'client_id' => ereader_item.guid.to_s,
          'title' => format_field(ereader_item.title),
          'page_number' => ereader_item.page_number,
          'descriptor' => format_field(ereader_item.descriptor),
          'concept_name' => ereader_item.concept&.name,
          'unit_name' => format_field(extract_unit_name(ereader_item.lesson&.unit&.id)),
          'domain' => format_field(standard_asset.additional_attrs[:domain]),
          'subdomain' => format_field(standard_asset.additional_attrs[:subdomain]),
          'program_ids' => @program.id.to_s,
          'mapped_item_type' => 'TEContent',
          'content_url' => CMS_URL,
          'standards_id_list' => standard_alignments.map(&:vendor_standard_guid).join(',')
        }
      end.compact
    end

    private def filtered_activities
      base_scope = activity_base.by_program(@program.id).joins(:concept).select(
        'activities.id AS activity_id',
        'activities.title AS activity_title',
        'activities.cms_activity_id AS cms_activity_id',
        'activities.lesson_id AS lesson_id',
        'lessons.unit_id AS unit_id',
        'activities.activity_type AS activity_type',
        'activities.component_name AS component_name',
        'activities.concept_id AS concept_id'
      )
      case @asset_type
      when 'activity'
        base_scope.where(activities: { instructor_id: nil },
                         concepts: { assessment: false }).includes(:standard_asset)
      when 'assessment-item'
        base_scope.where(activities: { instructor_id: nil }, concepts: { assessment: true })
      else
        base_scope
      end
    end

    private def fetch_program_ids(cms_activity_id)
      Activity.where(cms_activity_id:)
              .joins(lesson: :unit)
              .pluck(:program_id)
              .uniq
              .join(',')
    end

    private def activity_base
      @asset_type == 'activity' ? Activity.has_toc_location_plus_unlisted : Activity
    end

    private def format_field(field)
      field.nil? ? '' : field.strip.gsub(/\s+/, ' ')
    end

    private def extract_unit_name(unit_id)
      unit = Unit.find_by(id: unit_id)
      unit.name.presence || unit.label.presence || ''
    end

    private def fetch_assessment_by_program(assessment_id)
      Activity.joins(lesson: [unit: :program])
              .where(cms_activity_id: assessment_id, programs: { id: @program.id })
              .first
    end

    private def fetch_assessment_details(assessment_id)
      Activity.joins(lesson: [unit: :program])
              .where(cms_activity_id: assessment_id)
              .map do |activity|
        {
          concept_name: activity.concept&.name,
          lesson_name: activity.lesson&.name,
          unit_name: activity.lesson&.unit&.name,
          program_id: activity.lesson&.unit&.program_id
        }
      end
    end
  end
end
