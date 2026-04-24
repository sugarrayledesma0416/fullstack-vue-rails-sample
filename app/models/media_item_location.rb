module MediaItemLocation
  # public_filename's a misnomer. It's generally a full file path
  # or a URL. It may be best to name it "src" as that's the attribute
  # it's most often used in, or url.
  def public_filename
    path_prefix + common_path
  end

  private def media_type_dir
    if media_type == 'image'
      'images'
    else
      media_type
    end
  end

  # If running parallel specs, use a separate directory for each
  # parallel build.
  private def local_path_prefix
    "/media_items/#{Rails.env}#{ENV['TEST_ENV_NUMBER']}"
  end

  private def common_path
    "/#{media_type_dir}/#{dir_chunk}/#{filename}"
  end

  # Seems like it should be private
  def dir_chunk
    id_string[0..3]
  end

  # Seems like it should be private
  def subdir_chunk
    id_string[4..8]
  end

  private def id_string
    format('%<id>08d', id: id)
  end

  private def path_prefix
    local_path_prefix
  end
end
