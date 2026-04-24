class UpdateActivities
  attr_accessor :program, :program_id

  def initialize(attrs)
    self.program = attrs[:program]
    self.program_id = program.id
  end

  def run
    puts "Processing program: #{program.title} (ID: #{program.id})"

    process_program(program)

    puts "  Completed processing program: #{program.title}"
  end

  private def process_program(program)
    concepts = Concept.where(program_id: program.id, assessment: false)

    concepts.each do |concept|
      process_concept(concept)
    end
  end

  private def process_concept(concept)
    activities = concept.activities.where(instructor_id: nil)

    return if activities.empty?

    activities_by_toc_location = activities.group_by(&:toc_location)
    # Group activities by component_names
    activities_by_toc_location.each_value do |toc_location_activities|
      toc_location_activities.group_by(&:component_name).each do |component_name, component_activities|
        next if component_name.nil? || component_name == 'Unlisted'

        component_activities.each.with_index(1) do |activity, number|
          update_activity_title(activity, number)
        end
      end
    end
  end

  def update_activity_title(activity, number)
    current_title = activity.title.strip

    # Check if title already has the number format
    if current_title.match?(/^\d+\s+-\s+(.+)/)
      # Extract the title part without the existing number
      title_without_number = current_title.gsub(/^\d+\s+-\s+/, '').strip
      new_title = "#{number} - #{title_without_number}"

      # Skip if the number is already correct
      if current_title.match?(/^#{number}\s+-\s+/)
        puts "    Skipping activity ID #{activity.id}: '#{current_title}' (number already correct)"
        return
      else
        puts "    Updating number for activity ID #{activity.id}: '#{current_title}' -> '#{new_title}'"
      end
    else
      # No existing number, add one
      new_title = "#{number} - #{current_title}"
    end

    begin
      activity.update!(title: new_title)
      puts "    Updated activity ID #{activity.id}: '#{current_title}' -> '#{new_title}'"
    rescue StandardError => e
      puts "    ERROR updating activity ID #{activity.id}: #{e.message}"
    end
  end
end
