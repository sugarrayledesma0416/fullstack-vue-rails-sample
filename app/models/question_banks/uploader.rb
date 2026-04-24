module QuestionBanks
  class Uploader
    include Uploadable::Controller

    attr_accessor :topic, :file_upload, :user, :existing_question_bank

    def initialize(topic, file_upload, user)
      self.topic = topic
      self.file_upload = file_upload
      self.user = user
    end

    def question_bank
      if existing_question_bank.present?
        existing_question_bank
      else
        @question_bank ||= QuestionBank.new(
          question_bank_topic: topic
        )
      end
    end

    def upload
      if file_upload.blank?
        add_error('No CSV file was provided')
      elsif virus_detected?
        add_error(virus_message)
      else
        importer = QuestionBanks::Importer.new(**importer_data)
        importer.import
      end

      question_bank.errors.empty?
    end

    private def importer_data
      {
        filename: file_upload.original_filename,
        lines: lines,
        question_bank: question_bank,
        raw_csv: raw_content,
        user: user
      }
    end

    private def add_error(message)
      question_bank.errors.add(:base, message)
    end

    private def virus_detected?
      process_uploaded_file(file_upload, false) && !upload_is_virus_free?
    end

    private def raw_content
      file_upload.rewind
      file_upload.read
    end

    private def virus_message
      set_detected_virus_error_if_detected(:local_error)
    end

    private def lines
      file_upload.rewind
      file_upload.to_io.readlines
    end
  end
end
