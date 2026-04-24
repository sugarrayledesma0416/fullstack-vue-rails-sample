describe UploadFileDocUploader do
  let(:user) { build_stubbed(:student) }
  let(:upload_file_doc_uploader) { described_class.new(user) }
  let(:uploader) do
    instance_double(FileUploader, result: uploader_results, uuid: file_uuid)
  end
  let(:file_name) { 'dummy_file.pdf' }
  let(:file_path) { '/instructor-uploads/dummy_file.pdf' }
  let(:uploader_results) do
    {
      success: true,
      original_filename: file_name,
      temp_file_path: "temp/#{file_name}"
    }
  end
  let(:file_uuid) { SecureRandom.uuid }
  let(:school_ids) { [rand(30..39)] }
  let(:upload_params) do
    {
      user_id: rand(0..9),
      section_id: rand(10..19),
      course_id: rand(20..29),
      school_ids: school_ids.to_json,
      activity_id: rand(40..49)
    }
  end
  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      delete_file: OpenStruct.new(delete_marker: true),
      move_file: nil
    )
  end
  let(:expected_file_path) do
    File.join(described_class::USER_UPLOADS_PATH, user.id.to_s, file_uuid, file_name)
  end

  before do
    allow(upload_file_doc_uploader).to receive(:s3_bucket).and_return(s3_bucket)
    allow(uploader).to receive(:upload).and_return(uploader)
    allow(FileUploader).to receive(:new).and_return(uploader)
  end

  describe '#upload' do
    let(:expected_signed_url) { 'signed_url' }

    before do
      allow(FileUploadUrl).to receive(:new).and_return(
        instance_double(FileUploadUrl, signed_url: expected_signed_url)
      )
    end

    context 'when the file upload was successful' do
      it 'moves the file to its final destination when the file upload was successful' do
        upload_file_doc_uploader.upload(upload_params)
        expect(s3_bucket).to have_received(:move_file).with(
          uploader_results[:temp_file_path],
          expected_file_path
        )
      end

      it 'returns information about the file and location when the upload was successful' do
        expected_results = {
          final_file_path: expected_file_path,
          original_filename: file_name,
          signed_url: expected_signed_url,
          success: true,
        }
        results = upload_file_doc_uploader.upload(upload_params)
        expect(results).to eq expected_results
      end
    end

    context 'when the file upload failed' do
      let(:uploader_results) do
        {
          success: false,
          original_filename: file_name
        }
      end

      it 'does not try to move the file to its final destination' do
        upload_file_doc_uploader.upload(upload_params)
        expect(s3_bucket).not_to have_received(:move_file)
      end

      it 'returns the file uploader results' do
        results = upload_file_doc_uploader.upload(upload_params)
        expect(results).to eq uploader_results
      end
    end
  end

  describe '#delete_file' do
    context 'when the user is the owner of the file' do
      it 'deletes the file from the s3 bucket' do
        upload_file_doc_uploader.delete_file(file_path)
        expect(s3_bucket).to have_received(:delete_file).with(file_path)
      end
    end

    it 'returns true when the deletion was successful' do
      allow(s3_bucket).to receive(:delete_file).and_return(true)
      expect(upload_file_doc_uploader.delete_file(file_path)).to eq true
    end

    it 'returns false when the file deletion failed' do
      allow(s3_bucket).to receive(:delete_file).and_return(false)
      expect(upload_file_doc_uploader.delete_file(file_path)).to eq false
    end
  end
end
