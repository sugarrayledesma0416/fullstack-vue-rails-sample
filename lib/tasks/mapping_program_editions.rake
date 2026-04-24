require 'csv'

namespace :mapping_program_editions do
  desc 'Create program editions records.'
  task create_program_editions: :environment do
    csv_file = ENV['filename']

    unless csv_file
      puts 'Please provide the path to the CSV file.'
      next
    end

    begin
      CSV.foreach(csv_file, headers: true) do |row|
        program_id = row['program_id'].to_i
        next_edition_program_id =
          row['next_edition_program_id'].present? ? row['next_edition_program_id'].to_i : nil
        previous_edition_program_id =
          row['previous_edition_program_id'].present? ? row['previous_edition_program_id'].to_i : nil

        if next_edition_program_id || previous_edition_program_id
          Dangerfield::Gatekeeper.instance.disabled = false
          program_edition = ProgramEdition.new(
            program_id: program_id,
            next_edition_program_id: next_edition_program_id,
            previous_edition_program_id: previous_edition_program_id
          )

          if program_edition.save
            puts "Record successfully created for program_id: #{program_id}, " \
                 "next_edition_id: #{next_edition_program_id}, " \
                 "previous_edition_id: #{previous_edition_program_id}."
          else
            puts "The record could not be created. " \
                 "error(s): #{program_edition.errors.full_messages.join(', ')}."
          end
          Dangerfield::Gatekeeper.instance.disabled = true
        else
          puts "Record could not be created. A valid id is required for " \
               "next_edition_id or previous_edition_id."
        end
      end

      puts 'CSV data imported successfully.'
    rescue StandardError => e
      puts "Error importing data from CSV file: #{e.message}"
    end
  end
end
