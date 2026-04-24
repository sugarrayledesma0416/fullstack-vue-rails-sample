ZIP_FILE_LIST = %w[phonetics.doc sociolinguistic.pdf spanish.mp3].freeze

RSpec.shared_context 'when files were already uploaded to S3' do
  # s3_bucket def: radner_repository lib/radner/s3_bucket.rb
  let(:s3_bucket) { instance_double(Radner::S3Storage) }
  let(:program_with_units) { create(:program_with_lessons) }
  let(:program_no_units) { create(:program) }
  let(:no_errors_zip_path) { create_zipfile('Activity', ZIP_FILE_LIST) }

  let(:correct_csv_content) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/phonetics.doc,2,,Spanish,Syntax,Phonetics,0,1,Dialectal,,,,,,
      Activity/sociolinguistic.pdf,2,,Spanish,Grammar,Sociolinguistic,0,1,Evolution and expansion
      spanish.mp3,3,,Spanish,Semantic,Semantic relationships,0,1,Methaphor
    CSV
  end

  let(:csv_file_path) do
    file = Tempfile.new(['test', '.csv'])
    file.write(correct_csv_content)
    file.rewind
    file.path
  end

  let(:multiple_errors_csv_path) do
    file = Tempfile.new(['test_errors', '.csv'])
    file.write(multiple_errors_csv)
    file.rewind
    file.path
  end

  let(:multiple_errors_csv) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/phone?tics.doc,no numeric start unit,,Spanish,Syntax,Phonetics,,,Dialectal
      ,,,,,,,
      ,,,Spanish,Grammar,,0,1,Evolution and expansion
      Activity/missing_file.doc,5,hello,Spanish,Syntax,Phonetics,0,1,Dialectal
      Activity/sociolinguistic.pdf,2,3,,Grammar,Sociolinguistic,0,1,Empty component name
    CSV
  end
end
