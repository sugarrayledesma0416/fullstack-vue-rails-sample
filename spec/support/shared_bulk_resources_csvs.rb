RSpec.shared_context 'with a bulk csv file' do
  let(:empty_line_csv) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/phonetics.doc,2,,Spanish,Syntax,Phonetics,0,1,Dialectal
      Activity/sociolinguistic.pdf,2,,Spanish,Grammar,Sociolinguistic,0,1,Evolution and expansion
      ,,,,,,,
      Activity/spanish.mp3,3,,Spanish,Semantic,Semantic relationships,0,1,Methaphor
    CSV
  end

  let(:duplicated_path_csv) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/phonetics.doc,2,,Spanish,Syntax,Phonetics,0,1,Dialectal
      Activity/sociolinguistic.pdf,2,,Spanish,Grammar,Sociolinguistic,0,1,Evolution and expansion
      Activity/phonetics.doc,2,,Spanish,Syntax,Phonetics,0,1,Dialectal
    CSV
  end

  let(:csv_file_not_used) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/phonetics.doc,2,,Spanish,Syntax,Phonetics,0,1,Dialectal
      Activity/sociolinguistic.pdf,2,,Spanish,Grammar,Sociolinguistic,0,1,Evolution and expansion
    CSV
  end

  let(:semicolons_separated_csv) do
    <<~CSV
      source_file_path;start_unit;end_unit;component_name;subcomponent_name;clean_title;is_student_resource;is_protected;description
      Activity/phonetics.doc;2;;Spanish;Syntax;Phonetics;0;1;Dialectal
      Activity/sociolinguistic.pdf;2;;Spanish,Grammar;Sociolinguistic;0;1;Evolution and expansion
      spanish.mp3;3;;Spanish;Semantic;Semantic relationships;0;1;Methaphor
    CSV
  end

  let(:csv_with_valid_integer) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/test.doc,2,,Spanish,Syntax,Test,0,1,Test description
    CSV
  end

  let(:csv_with_valid_decimal) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/test.doc,2.1,,Spanish,Syntax,Test,0,1,Test description
    CSV
  end

  let(:csv_with_invalid_format) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/test.doc,2.1.3,,Spanish,Syntax,Test,0,1,Test description
    CSV
  end

  let(:csv_with_invalid_characters) do
    <<~CSV
      source_file_path,start_unit,end_unit,component_name,subcomponent_name,clean_title,is_student_resource,is_protected,description
      Activity/test.doc,abc,,Spanish,Syntax,Test,0,1,Test description
    CSV
  end
end
