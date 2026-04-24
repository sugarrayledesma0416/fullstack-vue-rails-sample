describe StandardsMappingTemplates do
  let(:program) { create(:program) }

  it '#activities_mapping_csv' do
    generator = instance_double(StandardsMapping::CsvGenerator)
    allow(generator).to receive(:generate_csv_string).and_return('foo,bar')
    allow(StandardsMapping::CsvGenerator).to(
      receive(:new).with(program.id, 'Activity').and_return(generator)
    )
    test_obj = Class.new.extend(described_class)
    test_obj.instance_variable_set(:@program, program)
    expect(test_obj.activities_mapping_csv).to eq('foo,bar')
  end

  it '#assessments_mapping_csv' do
    generator = instance_double(StandardsMapping::CsvGenerator)
    allow(generator).to receive(:generate_csv_string).and_return('foo,bar')
    allow(StandardsMapping::CsvGenerator).to(
      receive(:new).with(program.id, 'Assessment').and_return(generator)
    )
    test_obj = Class.new.extend(described_class)
    test_obj.instance_variable_set(:@program, program)
    expect(test_obj.assessments_mapping_csv).to eq('foo,bar')
  end
end
