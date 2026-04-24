#encoding: utf-8

describe ResultsXmlDatastore, :core => true do
  let(:user) { build_stubbed(:user) }
  let(:section) { build_stubbed(:section) }
  let(:attempt) { create(:attempt, :user => user, :section => section) }
  let(:xml_ds) {   ResultsXmlDatastore.new(attempt_submission, attempt) }
  let(:xml_ds) { ResultsXmlDatastore.new(attempt) }
  let(:filepath) { xml_ds.filepath }
  let(:fixture_file) { File.join('spec', 'fixtures', 'xml', 'ruby187_responses_with_accents.xml') }
  let(:s3_bucket) { double(Radner::S3Storage) }
  let(:file_contents) { File.read(fixture_file) }

  before do
    @expected_results =  {"question_01_wol_1"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡",
                          "question_02_wol_2"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡",
                          "question_03_wol_3"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡",
                          "question_04_wol_4"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡",
                          "question_05_wol_5"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡",
                          "question_06_wol_5"=>"áéíñóú¡¿üúóñéá and áéíñóúü¿¡"}
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
  end

  describe 'all read operations ' do
    before do
      allow(s3_bucket).to receive(:fetch).and_return(file_contents)
    end

    describe '#read operations with utf8 characters' do
      it 'correctly reads xml using offset and record lengths created by ruby 1.8.7' do
        # 1st attempt: offset_bytes: 0,    record_length: 810
        # 2nd attempt: offset_bytes: 810,  record_length: 696
        # 3th attempt: offset_bytes: 1506, record_length: 696
        # 4th attempt: offset_bytes: 2202, record_length: 696
        allow(attempt).to receive(:offset_bytes).and_return(1506)
        allow(attempt).to receive(:record_length).and_return(696)

        expect(ResultsXmlDatastore.new(attempt).read(1506, 696)).to eq(@expected_results)
      end
    end

    describe "#stored_responses" do
      it "returns responses stored in the process, but not submitted yet" do
        allow(attempt).to receive(:offset_bytes).and_return(1506)
        allow(attempt).to receive(:record_length).and_return(696)

        expect(ResultsXmlDatastore.new(attempt).stored_responses).to eq(@expected_results)
      end
    end

    describe "#saved_responses" do
      it "returns submitted as final responses" do

        allow(attempt).to receive(:save_offset_bytes).and_return(1506)
        allow(attempt).to receive(:save_record_length).and_return(696)

        expect(ResultsXmlDatastore.new(attempt).saved_responses).to eq(@expected_results)
      end
    end
  end

  describe "#write" do
    let(:results_to_write) { [{ label: 'question_01_wol_1', response: 'response_01' },
                              { label: 'question_02_wol_2', response: 'response_02' },
                              { label: 'question_03_wol_3', response: 'response_03' },
                              { label: 'question_04_wol_4', response: 'response_04' }] }
    let(:expected_xml) do
<<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<activity_responses id="#{attempt.activity_id}">
  <response label="question_01_wol_1">response_01</response>
  <response label="question_02_wol_2">response_02</response>
  <response label="question_03_wol_3">response_03</response>
  <response label="question_04_wol_4">response_04</response>
</activity_responses>
EOT
    end

    before do
      allow(s3_bucket).to receive(:fetch).and_return(file_contents)
      allow(s3_bucket).to receive(:content_length).and_return(0, file_contents.bytesize)
    end

    it "the results into the file s3 bucket" do
      expect(s3_bucket).to receive(:store_file_contents!).with(xml_ds.file_path,
                                                               file_contents + expected_xml,
                                                               content_type: 'application/xml')
      xml_ds.write(results_to_write)
    end
  end

  describe "#transfer_results" do
    let(:student) { build_stubbed(:student) }
    let(:section_from) { create(:section) }
    let(:content_object) { double('ContentObject', :result_labels => ['label_01, label_02']) }
    let(:activity) { build_stubbed(:activity) }
    let(:section_to) { create(:section) }
    let(:attempt) { create(:attempt, :user => student, :section => section_from, :activity => activity) }
    let(:results) { [ {:label => 'label_01', :correctness => 'correct', :response => 'right answer'},
                      {:label => 'label_02', :correctness => 'incorrect', :response => 'wrong answer'} ] }
    let(:rds) { ResultsXmlDatastore.new(attempt) }

    before do
      allow(results).to receive(:keys).and_return(['label_01, label_02'])
      allow(activity).to receive(:content_object).and_return(content_object)
      # write the source file
      allow(results).to receive(:attachment_ids)
    end

    context "when the student's results xml does not exist in the new section" do
      it "moves the student's results from one section to another" do
        allow(s3_bucket).to receive(:file_exist?).and_return(false)
        source_path = "datafiles/test/responses/#{section_from.id}/#{student.id}.xml"
        target_path = "datafiles/test/responses/#{section_to.id}/#{student.id}.xml"
        expect(s3_bucket).to receive(:move_file).with(source_path, target_path)
        rds.transfer_results(section_to)
      end
    end

    context "when the student's results xml exists in the new section" do
      it "notifies the VHLMonitor" do
        allow(s3_bucket).to receive(:file_exist?).and_return(true)
        expect(VHLMonitor).to receive(:notify)
        rds.transfer_results(section_to)
      end
    end
  end
end
