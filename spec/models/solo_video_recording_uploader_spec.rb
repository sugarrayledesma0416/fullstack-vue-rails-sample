describe SoloVideoRecordingUploader do
  let(:user) { build_stubbed(:student) }
  let(:solo_video_uploader) { described_class.new(user) }
  let(:uploader) do
    instance_double(VideoUploader, result: uploader_results, uuid: file_uuid)
  end
  let(:original_filename) { 'my_video.mp4' }
  let(:uploader_results) do
    {
      success: true,
      original_filename: original_filename,
      temp_file_path: "temp/#{original_filename}"
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
    instance_double(Radner::S3Storage,
                    delete_file: OpenStruct.new(delete_marker: true),
                    move_file: nil)
  end
  let(:dynamodb_wrapper) do
    instance_double(DynamoWrapper, delete_item: nil, put: nil)
  end
  let(:file_name) { 'archive.mp4' }
  let(:expected_file_path) do
    File.join(described_class::USER_UPLOADS_PATH, file_uuid, file_name)
  end

  before do
    allow(solo_video_uploader).to receive(:s3_bucket).and_return(s3_bucket)
    logstash_logger = instance_double(DynamoWrapper::LogStashLogger)
    allow(DynamoWrapper::LogStashLogger).to receive(:new).with(
      stats_index: described_class::DYNAMODB_STATS_INDEX,
      dynamo_table: described_class::DYNAMODB_TABLE
    ).and_return(logstash_logger)
    datadog_logger = instance_double(DynamoWrapper::DatadogLogger)
    allow(DynamoWrapper::DatadogLogger).to receive(:new).and_return(datadog_logger)
    allow(DynamoWrapper).to receive(:new).with(
      table: described_class::DYNAMODB_TABLE,
      loggers: [logstash_logger, datadog_logger]
    ).and_return(dynamodb_wrapper)
    allow(uploader).to receive(:upload).and_return(uploader)
    allow(VideoUploader).to receive(:new).and_return(uploader)
  end

  describe '#upload' do
    let(:expected_signed_url) { 'signed_url' }

    before do
      allow(PartnerChatUrl).to receive(:new).and_return(
        instance_double(PartnerChatUrl, signed_url: expected_signed_url)
      )
    end

    context 'if the video upload was successful' do
      it 'moves the file to its final destination if the video upload was successful' do
        solo_video_uploader.upload(upload_params)
        expect(s3_bucket).to have_received(:move_file).with(
          uploader_results[:temp_file_path],
          expected_file_path
        )
      end

      it 'creates a dynamodb record' do
        expected_params = {
          activity_id: upload_params[:activity_id],
          archive_id: expected_file_path,
          course_id: upload_params[:course_id],
          school_id: school_ids.first,
          status: 'stopped',
          user_1: { id: upload_params[:user_id].to_s, section_id: upload_params[:section_id].to_s },
          user_1_id: upload_params[:user_id]
        }
        solo_video_uploader.upload(upload_params)
        expect(dynamodb_wrapper).to have_received(:put).with(new_item: expected_params)
      end

      it 'returns information about the file and location if the upload was successful' do
        expected_results = {
          final_file_path: expected_file_path,
          new_file_name: file_name,
          original_filename: original_filename,
          s3_signed_url: expected_signed_url,
          success: true,
          uuid: file_uuid
        }
        results = solo_video_uploader.upload(upload_params)
        expect(results).to eq expected_results
      end
    end

    context 'if the video upload failed' do
      let(:uploader_results) do
        {
          success: false,
          original_filename: original_filename
        }
      end

      it 'does not try to move the file to its final destination' do
        solo_video_uploader.upload(upload_params)
        expect(s3_bucket).not_to have_received(:move_file)
      end

      it 'does not try to create a dynamodb' do
        solo_video_uploader.upload(upload_params)
        expect(dynamodb_wrapper).not_to have_received(:put)
      end

      it 'returns the video uploader results' do
        results = solo_video_uploader.upload(upload_params)
        expect(results).to eq uploader_results
      end
    end
  end

  describe '#delete_video' do
    before do
      allow(dynamodb_wrapper).to receive(:find).with(
        primary_key: [archive_id: expected_file_path],
        selected_attributes: ['user_1_id']
      ).and_return(['user_1_id' => user.id])
    end

    it 'returns true if the deletion was successful' do
      expect(solo_video_uploader.delete_video(file_uuid, file_name)).to eq true
    end

    it 'returns false if the file deletion failed' do
      allow(s3_bucket).to receive(:delete_file).and_return(OpenStruct.new(delete_marker: false))
      expect(dynamodb_wrapper).not_to have_received(:delete_item)
      expect(solo_video_uploader.delete_video(file_uuid, file_name)).to eq false
    end

    context 'if the user is the owner of the recording' do
      it 'deletes the file from the s3 bucket' do
        solo_video_uploader.delete_video(file_uuid, file_name)
        expect(s3_bucket).to have_received(:delete_file).with(expected_file_path)
      end

      it 'deletes the associated dynamodb record' do
        solo_video_uploader.delete_video(file_uuid, file_name)
        expected_params = { primary_key: { archive_id: expected_file_path } }
        expect(dynamodb_wrapper).to have_received(:delete_item).with(expected_params)
      end
    end

    context 'if the user is not the owner of the recording' do
      before do
        allow(dynamodb_wrapper).to receive(:find).and_return([])
      end

      it 'does not delete the file from the s3 bucket' do
        solo_video_uploader.delete_video(file_uuid, file_name)
        expect(s3_bucket).not_to have_received(:delete_file)
      end

      it 'does not delete the associated dynamodb record' do
        solo_video_uploader.delete_video(file_uuid, file_name)
        expect(dynamodb_wrapper).not_to have_received(:delete_item)
      end

      it 'returns false' do
        expect(solo_video_uploader.delete_video(file_uuid, file_name)).to eq false
      end
    end
  end
end
