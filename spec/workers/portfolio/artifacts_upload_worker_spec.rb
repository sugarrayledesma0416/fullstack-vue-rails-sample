require 'rails_helper'

describe Portfolio::ArtifactsUploadWorker, type: :worker do
  include PortfolioBuilder
  include RspecJsContentHelpers

  let(:school_config) { create(:school_config_with_portfolio) }
  let(:program) { create(:program_with_lessons) }
  let(:student) { create(:student) }
  let(:section) {
    create(
      :section,
      school: school_config.school,
      additional_info: 'Sample Description'
    )
  }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson_with_toc_entries) }

  let(:activity) { create(:activity, lesson:, toc_location: lesson.strands[0].location) }
  let(:attempt) do
    create(
      :attempt_submitted,
      activity:,
      section:,
      user: student
    )
  end

  describe '#perform' do
    before do
      allow(lesson).to receive(:strand_for_toc_location).and_return(strand)

      allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return(
        ''
      )

      stub_bulk_upload_artifacts_request(
        'mahara_bulk_upload_files',
        "{\"sucessful\":[{\"index\":\"0\",\"fileid\":\"335\",\"status\":\"Successfully " \
        "uploaded file\"}],\"failed\":[]}\n"
      )

      @response = described_class.new.perform(
        attempt.id, 'sample-text', 'header-html', 'footer-html', section.school_id
      )
      attempt.reload
    end

    it 'returns the upload response that no failed section.' do
      expect(@response['failed']).to be_empty
    end

    it 'returns the upload response with success.' do
      expect(@response['sucessful']).not_to be_empty
    end

    it 'updates the attempt record with artifact_sharing_status with success.' do
      expect(attempt.artifact_sharing_status).to eq('success')
    end
  end
end
