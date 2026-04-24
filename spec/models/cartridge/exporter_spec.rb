describe Cartridge::Exporter do
  let(:creator) { create(:user) }
  let(:program) { create(:program) }
  let(:cc_version) { '1.3.0' }
  let(:exporter) do
    described_class.new(program: program, creator: creator, cc_version: cc_version)
  end
  let(:s3_bucket) do
    instance_double(Radner::S3Storage, store_file_contents!: true, delete_file: true)
  end

  describe '#export' do
    let(:program_converter) do
      instance_double(Cartridge::Converters::ProgramConverter)
    end
    let(:cartridge) do
      instance_double(MultiVersionCommonCartridge::Cartridge)
    end
    let(:cartridge_writer) do
      instance_double(MultiVersionCommonCartridge::Writers::CartridgeWriter)
    end

    shared_examples 'does not delete cartridges for a different cc version' do
      it 'does not delete cartridges for a different cc version' do
        cartridge_1 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_2 = create(
          :cartridge_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_3 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )
        cartridge_4 = create(
          :cartridge_failed_build_status,
          cc_version: MultiVersionCommonCartridge::CartridgeVersions::CC_1_1_0,
          program: program
        )

        [cartridge_1, cartridge_2, cartridge_3, cartridge_4].each do |cartridge|
          expect(
            Cartridge::CartridgeBuildStatus.where(id: cartridge.id)
          ).to exist
        end

        [cartridge_1, cartridge_2].each do |cartridge|
          expect(s3_bucket).not_to have_received(:delete_file).with(
            cartridge.file_path
          )
        end
      end
    end

    shared_examples 'does not delete cartridges for a different program' do
      it 'does not delete cartridges for a different program' do
        other_program = create(:program)

        cartridge_1 = create(
          :cartridge_build_status,
          cc_version: cc_version,
          program: other_program
        )
        cartridge_2 = create(
          :cartridge_build_status,
          cc_version: cc_version,
          program: other_program
        )
        cartridge_3 = create(
          :cartridge_failed_build_status,
          cc_version: cc_version,
          program: other_program
        )
        cartridge_4 = create(
          :cartridge_failed_build_status,
          cc_version: cc_version,
          program: other_program
        )

        [cartridge_1, cartridge_2, cartridge_3, cartridge_4].each do |cartridge|
          expect(
            Cartridge::CartridgeBuildStatus.where(id: cartridge.id)
          ).to exist
        end

        [cartridge_1, cartridge_2].each do |cartridge|
          expect(s3_bucket).not_to have_received(:delete_file).with(
            cartridge.file_path
          )
        end
      end
    end

    before do
      allow(Cartridge::Converters::ProgramConverter)
        .to receive(:new).with(program).and_return(program_converter)
      allow(program_converter).to receive(:convert).and_return(cartridge)
      allow(MultiVersionCommonCartridge::Writers::CartridgeWriter)
        .to receive(:new).with(cartridge, cc_version).and_return(cartridge_writer)
      allow(cartridge_writer).to receive(:finalize)
      allow(cartridge_writer).to receive(:write_to_zip)
      allow_any_instance_of(
        Cartridge::CartridgeBuildStatus
      ).to receive(:s3_bucket).and_return(s3_bucket)
    end

    it 'create a common cartridge from the program' do
      exporter.export
      expect(program_converter).to have_received(:convert)
    end

    it 'creates a cartridge writer and calls #finalize on it' do
      exporter.export
      expect(cartridge_writer).to have_received(:finalize)
    end

    it 'writes the cartridge to a zip file' do
      exporter.export
      expect(cartridge_writer).to have_received(:write_to_zip)
    end

    it 'uploads the file to S3' do
      file_contents = 'some file contents'
      file = instance_double(File, read: file_contents)
      allow(File).to receive(:file?).and_return(true)
      allow(File).to receive(:new).and_return(file)

      exporter.export

      s3_path = File.join(
        'datafiles',
        M3::Application.config.current_deployed_env_name,
        'common_cartridges',
        Cartridge::CartridgeBuildStatus.last.file_name
      )

      expect(s3_bucket).to have_received(:store_file_contents!).with(
        s3_path,
        file_contents,
        content_disposition: 'attachment',
        content_type: ''
      )
    end

    it 'creates a cartridge build status record' do
      Timecop.freeze do
        expect do
          exporter.export
        end.to change(Cartridge::CartridgeBuildStatus, :count).by(1)

        expect(Cartridge::CartridgeBuildStatus.last).to have_attributes(
          cc_version: cc_version,
          creator: creator,
          error_message: nil,
          file_name: "#{Time.now.utc.strftime('%Y%m%d_%H%M%S')}_" \
                     "#{program.title}_#{cc_version}".gsub(/\W/, '_') + '.imscc',
          program: program
        )
      end
    end

    it 'returns no errors' do
      exporter.export

      expect(exporter.errors).to be_blank
    end

    it 'deletes older valid cartridges for this program and cc version' do
      cartridge_1 = create(
        :cartridge_build_status,
        cc_version: cc_version,
        program: program
      )
      cartridge_2 = create(
        :cartridge_build_status,
        cc_version: cc_version,
        program: program
      )

      exporter.export

      expect(
        Cartridge::CartridgeBuildStatus.where(id: cartridge_1.id)
      ).not_to exist
      expect(s3_bucket).to have_received(:delete_file).with(
        cartridge_1.file_path
      )

      expect(
        Cartridge::CartridgeBuildStatus.where(id: cartridge_2.id)
      ).not_to exist
      expect(s3_bucket).to have_received(:delete_file).with(
        cartridge_2.file_path
      )
    end

    it 'deletes all failed cartridges for this program and cc version' do
      cartridge_1 = create(
        :cartridge_failed_build_status,
        cc_version: cc_version,
        program: program
      )
      cartridge_2 = create(
        :cartridge_failed_build_status,
        cc_version: cc_version,
        program: program
      )

      exporter.export

      [cartridge_1, cartridge_2].each do |cartridge|
        expect(
          Cartridge::CartridgeBuildStatus.where(id: cartridge.id)
        ).not_to exist
      end
    end

    include_examples 'does not delete cartridges for a different cc version'
    include_examples 'does not delete cartridges for a different program'

    it 'returns true' do
      expect(exporter.export).to be(true)
    end

    context 'when the cartridge writer raises an error,' do
      let(:error) { StandardError.new('some error') }

      before do
        allow(MultiVersionCommonCartridge::Writers::CartridgeWriter)
          .to receive(:new).with(cartridge, cc_version).and_raise(error)
      end

      it 'adds the exception message to the error list' do
        exporter.export
        expect(exporter.errors).to eq([error.message])
      end

      it 'creates a record with the error message' do
        expect do
          exporter.export
        end.to change(Cartridge::CartridgeBuildStatus, :count).by(1)

        expect(Cartridge::CartridgeBuildStatus.last).to have_attributes(
          cc_version: cc_version,
          creator: creator,
          error_message: error.message,
          file_name: nil,
          program: program
        )
      end

      it 'deletes older failed cartridges' do
        cartridge_1 = create(
          :cartridge_failed_build_status,
          cc_version: cc_version,
          program: program
        )
        cartridge_2 = create(
          :cartridge_failed_build_status,
          cc_version: cc_version,
          program: program
        )

        exporter.export

        [cartridge_1, cartridge_2].each do |cartridge|
          expect(
            Cartridge::CartridgeBuildStatus.where(id: cartridge.id)
          ).not_to exist
        end
      end

      it 'deletes all but the last valid cartridges for this program and cc version' do
        cartridge_1 = create(
          :cartridge_build_status,
          cc_version: cc_version,
          program: program
        )
        cartridge_2 = create(
          :cartridge_build_status,
          cc_version: cc_version,
          program: program
        )

        exporter.export

        expect(
          Cartridge::CartridgeBuildStatus.where(id: cartridge_1.id)
        ).not_to exist
        expect(s3_bucket).to have_received(:delete_file).with(
          cartridge_1.file_path
        )

        expect(
          Cartridge::CartridgeBuildStatus.where(id: cartridge_2.id)
        ).to exist
        expect(s3_bucket).not_to have_received(:delete_file).with(
          cartridge_2.file_path
        )
      end

      include_examples 'does not delete cartridges for a different cc version'
      include_examples 'does not delete cartridges for a different program'

      it 'returns false' do
        expect(exporter.export).to be(false)
      end
    end
  end
end
