require 'csv'

class VtextDataGenerator
  # This order has been defined by tech prod to make it more efficient
  # and reduce manual steps for tech prod when creating production TOCs.
  # ticket: https://vistahl.atlassian.net/browse/MAE-63979
  # The order of the headers determines the order the columns appear
  # in the CSV defined in the order_data method.
  HEADERS = %w[unit_lesson
               strand_name
               content_category
               activity_type
               mouse_icon
               lesson_rank
               strand_rank
               activity_rank
               rank
               activity_title
               activity_source_code
               cms_activity_id
               license_group
               m3_link
               audio
               image
               video
               assignment_group].freeze

  LICENSE_GROUP = { 1 => '01-Supersite',
                    2 => '02-Supersite_Plus',
                    3 => 'WebSAM',
                    4 => '00-Media_Only',
                    21 => 'VOL',
                    23 => 'Premium' }.freeze

  MAESTRO_URL = 'm3a.vhlcentral.com'.freeze

  attr_accessor :program_id

  def initialize(program_id)
    self.program_id = program_id
  end

  def program
    @program ||= Program.find(program_id)
  end

  def generate
    # Add BOM (Byte Order Mark) to ensure proper UTF-8 encoding recognition in Excel.
    # This way the consumer apps respect special characters like ñ, á, ü, etc.
    # https://stackoverflow.com/questions/30368173/ruby-how-to-generate-csv-files-that-has-excel-friendly-encoding
    CSV.generate("\uFEFF", write_headers: true, headers: HEADERS) do |csv_data|
      generate_information.each do |activity|
        next if skip_activity?(activity)

        csv_data << cleaned_activity_data(activity).values
      end
    end
  end

  def generate_information
    Activity.select('activities.id AS id',
                    'lessons.name AS unit_lesson',
                    'activities.toc_location AS strand_name',
                    'component_name AS content_category',
                    'activity_type',
                    'activities.icon AS icons',
                    'concept_rank AS rank',
                    'lessons.rank AS lesson_rank',
                    'activities.toc_location_rank AS strand_rank',
                    'activities.concept_rank AS activity_rank',
                    'activities.title AS activity_title',
                    'activities.id AS activity_source_code',
                    'cms_activity_id',
                    'activities.license_group_id',
                    "CONCAT('#{MAESTRO_URL}/sections/0/activities/', activities.id) AS m3_link",
                    'activities.has_vhl_image',
                    'lesson_id',
                    'toc_location',
                    'assignment_group')
            .joins(:concept, lesson: [unit: :program])
            .includes(:lesson)
            .where(programs: { id: program_id })
            .where.not(cms_activity_id: nil)
            .where('activities.toc_location is not null' \
                   ' OR (activities.toc_location IS NULL' \
                   " AND activities.component_name = 'Unlisted')")
            .order(Arel.sql(array_position_order_clause),
                   'unit_lesson',
                   'concepts.rank',
                   'activities.concept_rank',
                   'content_category')
            .to_a
  end

  def file_name
    "#{program.prefix_abbreviation}_maestro3_vtext.csv"
  end

  private def skip_activity?(activity)
    activity.strand.nil? && activity.content_category != 'Unlisted'
  end

  private def cleaned_activity_data(activity)
    items = order_data(activity.serializable_hash.except('id', 'lesson_id', 'toc_location'))
    items[:license_group_id] = LICENSE_GROUP[items[:license_group_id].to_i]
    items[:strand_name] = formatted_strand_name(items[:strand_name])
    items[:activity_title] = formatted_title(items[:activity_title])
    items
  end

  private def formatted_strand_name(raw_name)
    strand_lookup[raw_name.to_s]&.title.to_s.gsub(%r{<br\s*/?>}, '|')
  end

  private def formatted_title(raw_title)
    return '' if raw_title.blank?

    decoded_title = CGI.unescapeHTML(raw_title)
    ActionController::Base.helpers.strip_tags(decoded_title).gsub("\n", '')
  end

  private def strand_lookup
    return @strand_lookup if defined? @strand_lookup

    toc_entries = program.lessons.flat_map(&:toc_entries)
    @strand_lookup = (toc_entries + toc_entries.flat_map(&:children)).index_by(&:location)
  end

  # This order has been defined by tech prod to make it more efficient
  # and reduce manual steps for tech prod when creating production TOCs.
  # The order of the headers determines the order the columns appear in the CSV.
  private def order_data(activity_data)
    # activities_items[:icons] includes a space separated list of available items including
    # textbook, audio and video
    {
      unit_lesson: activity_data['unit_lesson'],
      strand_name: activity_data['strand_name'],
      content_category: activity_data['content_category'],
      activity_type: activity_data['activity_type'],
      mouse_icon: activity_data['icons'].include?('textbook'),
      lesson_rank: activity_data['lesson_rank'].to_s,
      strand_rank: activity_data['strand_rank'].to_s,
      activity_rank: activity_data['activity_rank'].to_s,
      rank: activity_data['rank'],
      activity_title: activity_data['activity_title'],
      activity_source_code: activity_data['activity_source_code'],
      cms_activity_id: activity_data['cms_activity_id'],
      license_group_id: activity_data['license_group_id'],
      m3_link: activity_data['m3_link'],
      audio: activity_data['icons'].include?('audio'),
      image: activity_data['has_vhl_image'].to_s,
      video: activity_data['icons'].include?('video'),
      assignment_group: activity_data['assignment_group'] || ''
    }
  end

  # This method generates the SQL clause needed to order activities based on the order
  # of `toc_entries` (strands) within the lessons of the program. It ensures that the
  # strands in the generated CSV follow the same sequence as defined in the lessons.
  private def array_position_order_clause
    # Retrieve all `toc_entries` from lessons associated with the program
    toc_entries = program.lessons.flat_map(&:toc_entries)
    locations = toc_entries.map(&:location)

    # Format locations as an SQL array
    formatted_locations = locations.map { |loc| "'#{loc}'" }.join(', ')

    <<~SQL.squish
      FIELD(activities.toc_location, #{formatted_locations})
    SQL
  end
end
