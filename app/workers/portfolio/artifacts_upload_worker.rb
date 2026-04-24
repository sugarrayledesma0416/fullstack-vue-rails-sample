require 'fileutils'
require 'tempfile'
require 'streamio-ffmpeg'

module Portfolio
  class ArtifactsUploadWorker
    include Sidekiq::Worker
    include Portfolio::SyncService
    include WorkerInstrumentation

    sidekiq_options queue: :medium_priority, retry: 3, failures: :exhausted

    sidekiq_retry_in do |count|
      [8, 13, 21, 34][count]
    end

    sidekiq_retries_exhausted do |msg|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(attempt_id, html, header_html, footer_html, school_id)
      logger_data_merge(attempt_id:, artifact_html: html)

      attempt = Attempt.find(attempt_id)
      section = Section.find(attempt.section_id) if attempt.section_id != 0
      activity = Activity.find(attempt.activity_id)
      user = User.find(attempt.user_id)
      school = School.find(school_id)

      artifacts = generate_activity_type_artifacts(
        attempt, activity, user, section
      )
      artifacts.push(
        generate_pdf_artifact(activity, html, header_html, footer_html)
      )
      upload_bulk_artifacts(attempt, section, activity, user, artifacts, school)
    end

    private def generate_pdf_artifact(activity, html, header_html, footer_html)
      sanitized_filename = activity.title.downcase
      sanitized_filename.squish!
      sanitized_filename.gsub!(/[<>|\/\\:()&;#?*–]/, '-')
      sanitized_filename.gsub!(/\s/, '_')

      pdf = WickedPdf.new.pdf_from_string(
        html,
        encoding: 'UTF-8',
        header: { content: header_html },
        footer: { content: footer_html },
        margin: {
          top: 30,
          bottom: 15
        }
      )
      {
        file_content: pdf,
        name: "#{sanitized_filename}.pdf",
        type: 'pdf'
      }
    end

    private def generate_activity_type_artifacts(attempt, activity, user, section)
      case activity.activity_type
      when 'solo_video_recording'
        generate_svr_artifacts(attempt, activity, user)
      when 'composition'
        generate_composition_artifacts(attempt, activity, user, section)
      when 'info_gap_partner_chat', 'partner_chat', 'group_chat'
        generate_partner_chat_artifacts(attempt, activity, user)
      when 'video_virtual_chat'
        generate_video_virtual_chat_artifacts(attempt, activity)
      else
        []
      end
    end

    private def generate_svr_artifacts(attempt, activity, user)
      recording_path = file_path_for_svr_artifact(attempt, activity)
      file_extension = File.extname(recording_path).delete_prefix('.')
      svr_url = SoloVideoRecordingUrl.new(user)
      signed_url = svr_url.video_signed_url(recording_path)[:signed_url]
      file_content = file_content_from_url(signed_url)
      if file_content.blank?
        []
      else
        [{ file_content:, name: "svr_video.#{file_extension}", type: file_extension }]
      end
    end

    private def generate_composition_artifacts(attempt, activity, user, section)
      file_info = file_path_for_composition_artifact(attempt, activity, user, section)
      return [] unless file_info && file_info[:signed_url]

      file_extension = file_info[:file_extension]
      file_name = file_info[:file_name]
      file_content = file_content_from_url(file_info[:signed_url])
      if file_content.blank?
        []
      else
        [{ file_content:, name: file_name, type: file_extension }]
      end
    end

    private def generate_partner_chat_artifacts(attempt, activity, user)
      recording_path = file_path_for_partner_chat_artifact(attempt, activity)
      file_extension = File.extname(recording_path).delete_prefix('.')
      video_recording_url = SoloVideoRecordingUrl.new(user)
      signed_url = video_recording_url.video_signed_url(recording_path)[:signed_url]
      file_content = file_content_from_url(signed_url)
      if file_content.blank?
        []
      else
        [{
          file_content:,
          name: "#{activity.activity_type}_video.#{file_extension}",
          type: file_extension
        }]
      end
    end

    private def generate_video_virtual_chat_artifacts(attempt, activity)
      downloaded_data = download_audio_contents(attempt, activity)
      return [] if downloaded_data.empty?

      temp_files, combined_file_extension, audio_properties = prepare_temp_files(downloaded_data)
      return [] if temp_files.empty?

      if audio_properties.uniq.length > 1
        log_audio_inconsistency(audio_properties)
        return prepare_individual_artifacts(activity, downloaded_data)
      end

      begin
        prepare_combined_artifacts(activity, temp_files, combined_file_extension)
      rescue StandardError => e
        Sidekiq.logger.error "Error when combining vvchat audio files: #{e.message}"
        prepare_individual_artifacts(activity, downloaded_data)
      end
    end

    private def download_audio_contents(attempt, activity)
      activity.content_object.turns.map.with_index do |turn, index|
        recording_path = file_path_for_video_virtual_chat_artifact(attempt, activity, turn)
        next if recording_path.blank?

        file_extension = File.extname(recording_path).delete_prefix('.')
        file_content = file_content_from_url(recording_path)
        next if file_content.blank?

        { index:, content: file_content, extension: file_extension }
      end.compact
    end

    private def prepare_individual_artifacts(activity, downloaded_data)
      individual_artifacts = []
      downloaded_data.each do |data|
        individual_artifacts << individual_artifact(
          activity, data[:content], data[:index], data[:extension]
        )
      end
      individual_artifacts
    end

    private def prepare_combined_artifacts(activity, temp_files, combined_file_extension)
      combined_audio = combine_vvchat_audios(temp_files, combined_file_extension)
      [{
        file_content: combined_audio,
        name: "#{activity.activity_type}_audio_turns_combined.#{combined_file_extension}",
        type: combined_file_extension
      }]
    end

    private def prepare_temp_files(downloaded_data)
      temp_files = []
      audio_properties = []

      downloaded_data.each do |data|
        temp_file = create_temp_file(data[:index], data[:content], data[:extension])
        temp_files << temp_file
        audio_properties << vvchat_audio_file_properties(temp_file, data[:extension], data[:index])
      end

      combined_file_extension = downloaded_data.first[:extension]
      [temp_files, combined_file_extension, audio_properties]
    end

    private def individual_artifact(activity, file_content, index, file_extension)
      file_name = "#{activity.activity_type}_audio_turn_#{index + 1}.#{file_extension}"
      { file_content:, name: file_name, type: file_extension }
    end

    private def log_audio_inconsistency(audio_properties)
      Sidekiq.logger.warn(
        '[vvchat warning] Detected inconsistent audio properties among turns. ' \
        'This could break audio concatenation, so uploading individual turn files. ' \
        "audio_properties: #{audio_properties.to_json}"
      )
    end

    private def create_temp_file(index, file_content, file_extension)
      temp = Tempfile.new(["audio_part_#{index}", ".#{file_extension}"])
      temp.binmode
      temp.write(file_content)
      temp.rewind
      temp
    end

    private def combine_vvchat_audios(temp_files, extension)
      list_file = Tempfile.new('ffmpeg_list.txt')
      temp_files.each { |f| list_file.puts("file '#{f.path}'") }
      list_file.close

      output = Tempfile.new(['combined_audio', ".#{extension}"])
      output_path = output.path
      output.close!
      begin
        success = system("ffmpeg -f concat -safe 0 -i #{list_file.path} -c copy #{output_path}")
        raise 'ffmpeg failed to combine vvchat turn files!' unless success

        File.binread(output_path)
      ensure
        cleanup_after_combine(list_file, output_path, temp_files)
      end
    end

    private def cleanup_after_combine(list_file, output_path, temp_files)
      list_file.unlink
      FileUtils.rm_f(output_path)
      cleanup_tempfiles(temp_files)
    end

    private def cleanup_tempfiles(files)
      files.each(&:close!)
    end

    private def vvchat_audio_file_properties(file, file_extension, index)
      movie = FFMPEG::Movie.new(file.path)
      file_properties = {
        extension: file_extension,
        container_format: movie.container,
        audio_codec: movie.audio_codec,
        sample_rate: movie.audio_sample_rate,
        channels: movie.audio_channels
      }
      Sidekiq.logger.info "vvchat file #{index + 1}: #{file_properties.to_json}"
      file_properties
    end

    private def file_path_for_svr_artifact(attempt, activity)
      question_label = activity.content_object.questions.first.label
      results_response = attempt.results&.response(question_label)
      solo_video_recording_url(results_response)
    end

    private def partner_chat_recording_url(response)
      if response[:recording_path].blank?
        ''
      else
        "#{M3::Application.config.partner_chat_cdn}/#{response[:recording_path]}"
      end
    end

    def solo_video_recording_url(response)
      partner_chat_recording_url(response)
    end

    private def file_path_for_composition_artifact(attempt, activity, user, section)
      item = activity.questions.first
      attachment = attempt.results.attachment_for(item.label)
      composition_attachment = CompositionAttachment.find(attachment&.id) if attachment.present?
      return unless downloadable_by?(composition_attachment, user, section)

      file_name = composition_attachment.file_name
      file_extension = File.extname(composition_attachment.file_path).delete_prefix('.')
      { file_extension:, file_name:, signed_url: composition_attachment.signed_url }
    end

    def downloadable_by?(composition_attachment, user, section)
      if section
        composition_attachment&.downloadable_by?(user, section)
      else
        composition_attachment&.owned_by?(user)
      end
    end

    private def file_path_for_partner_chat_artifact(attempt, activity)
      question = activity.questions.first
      results_response = attempt.results.response(question.label)
      partner_chat_recording_url(results_response)
    end

    private def file_path_for_video_virtual_chat_artifact(attempt, activity, turn)
      recording_path = activity.content_object.recorded_response_path_for_turn(
        attempt.results, turn.label
      )
      video_virtual_chat_config = {
        baseDir: 'virtual_chat/',
        endpoint: Rails.application.config.multimedia.virtual_chat.recording_endpoint,
        cdn: Rails.application.config.multimedia.virtual_chat.cdn_prefix
      }
      decode_from_submission(video_virtual_chat_config, recording_path)
    end

    private def decode_from_submission(config, path)
      # File extension is removed before storing the submission so we can
      # eventually use multiple codecs, but on disk it is a .wav.
      path += '.wav' unless path.end_with?('.wav')

      # Legacy recordings all have top-level directories in the format volume_n
      if path.start_with?('/volume')
        # Legacy submissions have an initial slash
        legacy_base_dir = 'old_arc'
        file_url = config[:cdn] + legacy_base_dir + path
      else
        file_url = config[:cdn] + path
      end
      file_url
    end

    private def file_content_from_url(file_url)
      return if file_url.empty?

      URI.parse(file_url).open(encoding: 'UTF-8').read
    end

    private def generate_partner_chat_signed_url(relative_path)
      PartnerChatUrl.new(relative_url: relative_path).signed_url
    end
  end
end
