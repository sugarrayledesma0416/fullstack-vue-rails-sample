describe CompositionAttacher do
  let(:user) { build_stubbed(:user) }
  let(:section) { build_stubbed(:section) }
  let(:composition_attachment) { build_stubbed(:composition_attachment) }
  let(:uploaded_file) do
    double('UploadedFile', original_filename: 'valid_file.txt')
  end

  describe '#response' do
    before do
      allow(CompositionAttachment).to receive(:create)
        .and_return(composition_attachment)
    end

    context 'when no file is specified' do
      before do
        @attacher = described_class.new(user, section, nil)
        @attacher.upload
      end

      it 'is unsuccessful' do
        expect(@attacher.response[:success]).to be_falsey
      end

      it 'includes an error message that a file is required' do
        expect(@attacher.response[:reason]).to eq(['You should select a file to upload.'])
      end
    end

    context 'when a virus is detected' do
      let(:virus_name) { 'very_bad_virus' }
      let(:infected_file_params) do
        { 'infected' => 'true', 'virus_name' => virus_name }
      end

      before do
        @attacher = described_class.new(
          user,
          section,
          ActionController::Parameters.new(infected_file_params)
        )
        @attacher.upload
      end

      it 'is unsuccessful' do
        expect(@attacher.response[:success]).to be_falsey
      end

      it 'includes an error message with the name of the virus' do
        virus_error = 'Your file could not be uploaded because it seems ' \
                      "to be infected with the virus 'very_bad_virus'"
        expect(@attacher.response[:reason]).to eq([virus_error])
      end
    end

    context 'when the upload is virus free' do
      it "creates a new CompositionAttachment record" do
        expect(CompositionAttachment).to receive(:create).with(
          { user: user, file: uploaded_file }
        ).and_return(composition_attachment)
        attacher = described_class.new(user, section, uploaded_file)
        attacher.upload
      end

      context 'when creating the attachment fails due to validation errors' do
        let(:error_1) { 'some validation error' }
        let(:error_2) { 'another validation error' }

        before do
          composition_attachment.errors.add(:base, error_1)
          composition_attachment.errors.add(:base, error_2)
          @attacher = described_class.new(user, section, uploaded_file)
          @attacher.upload
        end

        it 'is unsuccessful' do
          expect(@attacher.response[:success]).to be_falsey
        end

        it 'includes an error message with an array containing the validation errors' do
          expect(@attacher.response[:reason]).to match_array([error_1, error_2])
        end
      end

      context 'when the attachment is created successfully' do
        before do
          @attacher = described_class.new(user, section, uploaded_file)
          @attacher.upload
        end

        it 'is successful' do
          expect(@attacher.response[:success]).to be_truthy
        end

        it 'does not include an error message' do
          expect(@attacher.response).not_to have_key :reason
        end

        it 'includes the id of the created attachment' do
          expect(@attacher.response[:attachment_id]).to eq(composition_attachment.id)
        end

        it 'includes the the download url for the new attachment' do
          expect(@attacher.response[:download_url]).to eq("/sections/#{section.id}/composition_attachments/#{composition_attachment.id}")
        end

        context 'when a previous attachment id was specified' do
          let(:previous_attachment) { build_stubbed(:composition_attachment) }
          let(:original_attachment) { build_stubbed(:composition_attachment) }

          before do
            allow(CompositionAttachment).to receive(:find_by_id).with(previous_attachment.id).and_return(previous_attachment)
            allow(CompositionAttachment).to receive(:find_by_id).with(original_attachment.id).and_return(original_attachment)
            allow(previous_attachment).to receive(:destroy_by_user)
            allow(composition_attachment).to receive(:update!)
            @attacher = described_class.new(user, section, uploaded_file, previous_attachment.id)
          end

          it 'finds the attachment specified by the previous attachment id' do
            expect(CompositionAttachment).to receive(:find_by_id).with(previous_attachment.id).and_return(previous_attachment)
            @attacher.upload
          end

          context 'when the previous attachment has a non-nil replaces_attachment_id value' do
            let(:previous_attachment) { build_stubbed(:composition_attachment, :replaces_attachment_id => original_attachment.id) }

            it 'stores the replacement_attachment_id value from the previous attachment in the newly created record' do
              expect(composition_attachment).to receive(:update!).with(:replaces_attachment_id => original_attachment.id)

              @attacher.upload
            end

            it 'deletes the previous attachment' do
              expect(previous_attachment).to receive(:destroy_by_user).with(user)

              @attacher.upload
            end
          end

          context 'when the previous attachment has a nil value for replaces_attachment_id' do
            let(:previous_attachment) { build_stubbed(:composition_attachment, :replaces_attachment_id => nil) }

            it 'stores the previous attachment id in the newly created record' do
              expect(composition_attachment).to receive(:update!).with(:replaces_attachment_id => previous_attachment.id)

              @attacher.upload
            end

            it 'does not delete the previous attachment' do
              expect(previous_attachment).not_to receive(:destroy_by_user)

              @attacher.upload
            end
          end

        end

      end
    end
  end
end
