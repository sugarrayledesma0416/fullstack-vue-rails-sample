namespace :a11y do
  desc 'generate Excel spreadsheet showing accessibilty issues by program'
  task create_program_spreadsheet: :environment do
    program_ids = ENV['PROGRAM_ID'].to_s.split(',')
    program_ids.each do |program_id|
      spreadsheet = A11ySpreadsheet.new(program_id, ENV['DETAILS'])
      spreadsheet.write
      puts "wrote spreadsheet for program #{program_id} to #{spreadsheet.file_path}"
    end
  end
end
