module RecordingPath
  def recording_path=(path)
    update_associated_recording('recording', path)
  end

  def recording_path
    get_recording_path_for('recording')
  end

  private def get_recording_path_for(type)
    record_item = get_associated_recording(type)
    record_item&.recording_path
  end

  private def update_associated_recording(type, path)
    if (record_item = get_associated_recording(type))
      if path.blank?
        record_item.destroy
        update_column("#{type}_id".to_sym, nil)
      elsif record_item.recording_path != path
        record_item.update!(recording_path: path)
      end
    else
      path.present? && public_send("create_#{type}!".to_sym, recording_path: path)
    end
  end

  private def get_associated_recording(type)
    public_send(type.to_sym)
  end
end
