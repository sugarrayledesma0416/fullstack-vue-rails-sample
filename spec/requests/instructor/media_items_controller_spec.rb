require 'requests/login_helper_methods'
require 'requests/shared_require_instructor_examples'

describe Instructor::MediaItemsController do
  let(:instructor) { create(:instructor) }

  describe 'PUT /update' do
    let(:media_item) do
      create(
        :instructor_media_item,
        original_filename: 'file.wav',
        media_type: 'audio',
        transcript: nil
      )
    end

    let(:target_path) do
      instructor_media_item_path(media_item.id)
    end

    let(:new_transcript) { 'new transcript contents' }

    let(:update_params) do
      { transcript: new_transcript }
    end

    def do_request
      put(target_path, params: update_params, as: :json)
    end

    include_examples 'require logged in user', :json

    it 'renders a 401 error when logged-in user is not an instructor' do
      student = create(:student)
      log_in_user(student)

      do_request

      expect(response).to be_unauthorized
    end

    context 'with a valid user,' do
      before do
        log_in_user(instructor)
      end

      it 'updates the specified media item to have the specified transcript' do
        do_request

        expect(response).to be_ok

        expect(media_item.reload.transcript).to eq(new_transcript)
      end
    end
  end

  describe 'POST /create' do
    let(:s3_bucket) do
      instance_double(
        Radner::S3Storage,
        content_length: audio_file_size,
        move_file: nil,
        store_file_contents!: nil
      )
    end

    let(:audio_file_size) { 456 }

    let(:target_path) do
      instructor_media_items_path
    end

    let(:create_params) do
      { filename: 'uuid.wav' }
    end

    def do_request
      post(target_path, params: create_params, as: :json)
    end

    before do
      allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    end

    include_examples 'require logged in user', :json

    it 'renders a 401 error when logged-in user is not an instructor' do
      student = create(:student)
      log_in_user(student)

      do_request

      expect(response).to be_unauthorized
    end

    context 'with a valid user,' do
      before do
        log_in_user(instructor)
      end

      it 'creates a new media item record when valid params are specified' do
        do_request

        expect(response).to be_ok

        media_item = InstructorMediaItem.last

        expect(media_item).to have_attributes(
          extname: '.wav',
          instructor_id: instructor.id,
          media_type: 'audio',
          size: audio_file_size
        )

        expect(JSON.parse(response.body, symbolize_names: true)).to eq(
          id: media_item.id,
          url: media_item.public_filename
        )
      end
    end
  end
end
