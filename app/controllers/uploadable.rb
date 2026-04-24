module Uploadable
  module Controller
    def process_uploaded_file(uploaded_file, needs_filetype = true)
      return {} if uploaded_file.blank?
      retval = {}
      if uploaded_file.is_a?(ActionController::Parameters) && uploaded_file.has_key?('infected')
        @detected_virus_name = uploaded_file['virus_name']
        retval
      else
        file_name = uploaded_file.original_filename
        retval = { :file_name => file_name }
        retval.merge!({:file_type => file_type(File.extname(file_name))}) if needs_filetype
        retval
      end
    end

    def upload_is_virus_free?
      @detected_virus_name.nil?
    end

    def set_detected_virus_error_if_detected(error_type = :flash)
      unless upload_is_virus_free?
        virus_error = "Your file could not be uploaded because it seems to be infected with the virus '#{@detected_virus_name}'"
        if error_type == :flash
          flash.now[:error] = virus_error
        else
          virus_error
        end
      end
    end

    def assign_allowed_file_types
      @allowed_file_types = FileType.allowed.collect(&:extension_name).map(&:downcase).join(',')
    end
  end
end
