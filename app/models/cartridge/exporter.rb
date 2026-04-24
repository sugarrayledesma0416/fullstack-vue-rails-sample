module Cartridge
  class Exporter
    attr_accessor :errors

    def initialize(program:, cc_version:, creator:)
      @program = program
      @creator = creator
      @cc_version = cc_version
      self.errors = []
    end

    def export
      begin
        write_cartridge
      rescue StandardError => e
        errors << e.message
      end

      if errors.present?
        generated_cartridge.error_message = errors.join(', ')
        generated_cartridge.status = CartridgeBuildStatus::STATUS_FAILURE
        generated_cartridge.file_name = nil
        # Delete all older failed records
      else
        generated_cartridge.status = CartridgeBuildStatus::STATUS_SUCCESS
        # Delete all older success records
      end

      generated_cartridge.save!

      delete_older_records

      errors.blank?
    end

    private def delete_older_records
      if generated_cartridge.success?
        # If this last cartridge was successfully created, delete all previous
        # records.
        CartridgeBuildStatus
          .where(program: @program)
          .where(cc_version: @cc_version)
          .where.not(id: generated_cartridge.id)
          .destroy_all
      else
        # If this cartridge was not successfully created, delete all previous
        # failed cartridges records, and all but the last one successfully
        # exported cartridges
        last_success_record_id = CartridgeBuildStatus.success.where(
          cc_version: @cc_version,
          program_id: @program.id
        ).last&.id

        CartridgeBuildStatus
          .where(program: @program)
          .where(cc_version: @cc_version)
          .where.not(id: [generated_cartridge.id, last_success_record_id])
          .destroy_all
      end
    end

    private def generated_cartridge
      @generated_cartridge ||= CartridgeBuildStatus.new(
        cc_version: @cc_version,
        creator: @creator,
        file_name: file_name,
        program: @program
      )
    end

    private def file_name
      timestamp = Time.now.utc.strftime('%Y%m%d_%H%M%S')
      "#{timestamp}_#{@program.title}_#{@cc_version}".gsub(/\W/, '_') + '.imscc'
    end

    private def write_cartridge
      cartridge_writer.finalize
      cartridge_writer.write_to_zip(temp_local_filename)

      if File.file?(temp_local_filename)
        file = File.new(temp_local_filename, 'r')
        generated_cartridge.upload_file(file)
      end
    end

    private def cartridge
      @cartridge ||= Converters::ProgramConverter.new(@program).convert
    end

    private def cartridge_writer
      @cartridge_writer ||= MultiVersionCommonCartridge::Writers::CartridgeWriter.new(
        cartridge, @cc_version
      )
    end

    def temp_local_filename
      @temp_local_filename ||= File.join('/tmp', "#{SecureRandom.uuid}.imscc")
    end
  end
end
