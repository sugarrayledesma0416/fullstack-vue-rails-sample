describe CompositionAttachment do
  def test_file(filename = 'file.txt', already_uploaded = false)
    file_path = Rails.root.join('tmp', filename)
    # this line is required to get things loaded properly
    # https://github.com/chefspec/chefspec/issues/766#issuecomment-396631456
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(file_path).and_return(true)
    allow(File).to receive(:size).with(file_path).and_return(1)
    return unless already_uploaded

    allow(FileUtils).to receive(:copy_file).with(file_path, kind_of(String))
    # Can't use an instance_double because UploadedFile uses method_missing
    # to forward `#read` to its TempFile.
    object_double(
      Rack::Multipart::UploadedFile.new(file_path),
      original_filename: filename,
      path: file_path,
      read: 'contents'
    )
  end

  let(:user) { create(:student) }
  let(:other_user) { create(:student) }
  let(:composition_attachment) do
    create(:composition_attachment, user: user, file_name: 'upload.txt')
  end
  let(:test_file_name) { 'some_file.txt' }
  let(:file_to_upload) { test_file(test_file_name, true) }
  let(:receiver) { composition_attachment }
  let(:s3_bucket) do
    instance_double(
      Radner::S3Storage,
      delete_file: true,
      file_exist?: true,
      move_file: true,
      store_file_contents!: true
    )
  end

  before do
    allow(Radner::S3Storage).to receive(:new).and_return(s3_bucket)
    allow(FileType).to receive(:allowed).and_return(
      [
        instance_double(FileType, extension_name: 'txt'),
        instance_double(FileType, extension_name: 'jpg')
      ]
    )
  end

  it_behaves_like 'an object that sanitizes uploaded file names'
  it_behaves_like 'an object that has file presence validation methods'
  it_behaves_like 'an object that can read its related file data from an S3 bucket'

  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:file_name) }

  describe 'validations' do
    it 'validates the attached file size before saving it' do
      allow(File).to receive(:size)
        .with(file_to_upload.path)
        .and_return(11_485_760)
      composition_attachment = described_class.new(
        user_id: user.id, file: file_to_upload
      )
      composition_attachment.valid?
      expect(composition_attachment.errors.full_messages).to include(
        'File size must be 10 MB or smaller.'
      )
    end

    it 'validates file type before saving it' do
      invalid_file = test_file('some_file.foo', true)
      composition_attachment = described_class.new(
        user_id: user.id, file: invalid_file
      )
      composition_attachment.valid?
      expect(composition_attachment.errors.full_messages).to include(
        "You tried to upload a file with extension 'foo', which is not allowed."
      )
    end
  end

  describe 'callbacks' do
    describe '#change_attachment_location' do
      it 'does not raise an error with a newly created composition attachment' do
        expect do
          described_class.create!(user_id: user.id, file: file_to_upload)
        end.not_to raise_error
      end

      context 'with an existing attachment,' do
        let(:composition_attachment) do
          described_class.create!(user_id: user.id, file: file_to_upload)
        end

        context 'when the user id changes,' do
          it 'moves the attachment file location to the new user id directory' do
            new_path = File.join(
              'composition_attachments',
              Rails.env,
              other_user.id.to_s,
              composition_attachment.id.to_s,
              test_file_name
            ).to_s
            expect(s3_bucket).to receive(:move_file)
              .with(composition_attachment.file_path, new_path)
            composition_attachment.update!(user_id: other_user.id)
          end

          it 'does not raise an error when the attachment file does not exist' do
            allow(s3_bucket).to receive(:file_exist?).and_return(false)
            expect do
              composition_attachment.update!(user_id: other_user.id)
            end.not_to raise_error
          end
        end

        it 'does not move the attachment file from its location when the ' \
           'user id does not change' do
          expect(s3_bucket).not_to receive(:move_file)
          composition_attachment.update!(draft: true)
        end
      end
    end
  end

  it 'stores the specified file on s3 when it is a new attachment' do
    allow(s3_bucket).to receive(:file_exist?).and_return(false)
    described_class.create!(user_id: user.id, file: file_to_upload)
    expect(s3_bucket).to have_received(:store_file_contents!)
      .with(
        /^composition_attachments/,
        kind_of(String),
        hash_including(content_disposition: 'attachment')
      )
  end

  it 'does not upload to s3 when updating non-file attributes' do
    replacement_id = 3
    composition_attachment = described_class.create!(
      user_id: user.id, file: file_to_upload
    )
    expect(composition_attachment).not_to receive(:upload_file)
    composition_attachment.update!(
      replaces_attachment_id: replacement_id
    )
  end

  describe '.expired_drafts' do
    it 'returns draft attachments created more than a day ago only' do
      expected_draft_1 = create(:expired_draft_attachment)
      create(:no_draft_attachment, created_at: 2.days.ago)
      create(:composition_attachment)
      expect(described_class.expired_drafts).to eq([expected_draft_1])
    end
  end

  describe '.remove_draft_flags_from' do
    it 'sets the value of draft attribute of the given attachments to false' do
      attachment_ids = [
        create(:composition_attachment, draft: true).id,
        create(:composition_attachment, draft: true).id
      ]
      described_class.remove_draft_flags_from(attachment_ids)
      attachment_results = described_class.find(attachment_ids)
      expect(attachment_results.map(&:draft?)).to eq([false, false])
    end

    context 'when the specified attachment has a non-nil value for ' \
            'replaces_attachment_id,' do
      it 'deletes the attachment identified by replaces_attachment_id and ' \
         'clears that field' do
        user = create(:user)
        old_attachment = create(:composition_attachment, user: user)
        new_attachment = create(
          :composition_attachment,
          draft: true,
          replaces_attachment_id: old_attachment.id,
          user: user
        )
        described_class.remove_draft_flags_from([new_attachment.id])
        expect(s3_bucket).to have_received(:delete_file)
          .with(old_attachment.file_path)
        new_attachment = described_class.find_by_id(new_attachment.id)
        expect(new_attachment.replaces_attachment_id).to be_nil
        expect(new_attachment).not_to be_draft
      end
    end
  end

  describe '#file_path' do
    it 'returns the path to attachment file folder' do
      expect(composition_attachment.file_path).to eq(
        File.join(
          'composition_attachments',
          Rails.env,
          composition_attachment.user_id.to_s,
          composition_attachment.id.to_s,
          composition_attachment.file_name
        )
      )
    end
  end

  describe '#destroy_by_user' do
    before do
      allow(FeedbackItem).to receive(:remove_attachment)
    end

    it 'returns false if specified user is not the owner' do
      expect(composition_attachment.destroy_by_user(other_user)).to be_falsey
    end

    context 'when specified user is the owner' do
      it "updates instructor's feedback item" do
        composition_attachment.destroy_by_user(user)
        expect(FeedbackItem).to have_received(:remove_attachment)
          .with(composition_attachment.id)
      end

      it 'deletes the composition_attachment record' do
        composition_attachment.destroy_by_user(user)
        expect(described_class.find_by_id(composition_attachment.id)).to be_nil
      end

      it 'deletes the composition_attachment file' do
        file_path = composition_attachment.file_path
        composition_attachment.destroy_by_user(user)
        expect(s3_bucket).to have_received(:delete_file).with(file_path)
      end

      it 'returns true' do
        expect(composition_attachment.destroy_by_user(user)).to be_truthy
      end
    end
  end

  describe '#owned_by?' do
    it 'returns true when the current user is the owner of the attachment' do
      expect(composition_attachment).to be_owned_by(user)
    end

    it 'returns false when the current user is not the owner of the attachment' do
      expect(composition_attachment).not_to be_owned_by(other_user)
    end
  end

  describe '#downloadable_by?' do
    let(:student) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }
    let(:instructor) { build_stubbed(:instructor) }
    let(:student_response) { build(:composition_attachment, user: student) }
    let(:instructor_feedback) { build(:composition_attachment, user: instructor) }

    it 'is true when user owns the attachment' do
      expect(student_response).to be_downloadable_by(student, section)
    end

    context 'when a user is not the owner of an attachment' do
      it 'is false when downloading user is another student in the section' do
        other_student = build_stubbed(:student)
        allow(student).to receive(:active_section?).with(section)
                                                   .and_return(true)
        allow(other_student).to receive(:active_section?).with(section)
                                                         .and_return(true)
        expect(student_response).not_to be_downloadable_by(
          other_student, section
        )
      end

      it 'is true when downloading user is an instructor of the section' do
        another_instructor = build_stubbed(:instructor)
        allow(section).to receive(:instructors)
          .and_return([instructor, another_instructor])
        expect(instructor_feedback).to be_downloadable_by(
          another_instructor, section
        )
      end

      it 'is true when a student downloads a feedback file from his instructor' do
        allow(section).to receive(:instructors).and_return([instructor])
        allow(student).to receive(:active_section?).with(section).and_return(true)
        expect(instructor_feedback).to be_downloadable_by(student, section)
      end

      it 'is false when downloading user is not an instructor of the section' do
        another_instructor = build_stubbed(:instructor)
        allow(section).to receive(:instructors).and_return([instructor])
        expect(instructor_feedback).not_to be_downloadable_by(
          another_instructor, section
        )
      end

      it 'is false when a student tries to download a feedback file owned ' \
         'by an instructor of a section in which they are not enrolled' do
        allow(section).to receive(:instructors).and_return([instructor])
        allow(student).to receive(:active_section?).with(section)
                                                   .and_return(false)
        expect(instructor_feedback).not_to be_downloadable_by(student, section)
      end
    end
  end
end
