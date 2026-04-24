module MediaItemsHelper
  NEWLINE_REGEX = /\n/
  def format_popup_play_link(media_item, link_text = 'Play')
    if media_item.media_type == 'audio'
      height = 20
      width = 160
    else
      height = media_item.height
      width  = media_item.width
      if height.blank? || height == 0 || width.blank? || width == 0
        height = 700
        width  = 700
      end
    end
    popup_options = { window_name: "play_#{media_item.id}",
                      height: height + 40,
                      width: width + 20 }
    link_to(
      link_text.html_safe,
      media_item_path(media_item),
      onclick: format_popup_onclick(popup_options),
      'aria-label': "#{strip_tags(link_text)}. The link will open in a new window"
    )
  end

  def display_media_item(media_item, opts = {})
    raise 'given nil media_item' unless media_item

    opts.symbolize_keys

    case media_item.media_type
    when 'image'
      opts[:width], opts[:height] = resolve_dimensions(opts[:width], opts[:height], media_item)
      # allow opts[:alt] hash value to override alt_tag on media_item
      opts[:alt] ||= media_item.alt_tag

      if media_item&.long_description&.present?
        opts['aria-details'] ||= "longdesc-for-#{media_item.id}"
        rendered_tag = render(partial: 'media_items/images',
                              locals: { media_item:, image_options: opts })
        rendered_tag.gsub(NEWLINE_REGEX, '').html_safe
      elsif opts[:reference_in_artifact]
        image_tag(embed_remote_image(media_item.public_filename), opts)
      else
        image_tag(media_item.public_filename, opts)
      end
    when 'audio'
      render(
        'media_items/audio_player',
        auto_play: 0,
        media_item:,
        reference: opts[:reference],
        submission_status: opts[:submission_status],
        reference_in_artifact: opts[:reference_in_artifact]
      )
    when 'video'
      render(partial: 'media_items/video_player',
             locals: { media_item:,
                       record_button_for_question: opts[:record_button_for_question],
                       reference: opts[:reference] })
    else
      raise "unsupported media type: '#{media_item.media_type}'"
    end
  end

  def next_audio_player_id
    if @current_audio_player_id
      @current_audio_player_id += 1
    else
      @current_audio_player_id = 0
    end
    "audio#{@current_audio_player_id}"
  end

  private

  def resolve_dimensions(width, height, media_item)
    dimensions = [width, height].compact
    if dimensions.length == 1 && dimensions.first =~ /%/
      width = dimensions.first
      height = dimensions.first
    end

    if height
      if height =~ /(\d+)%/ && media_item.height
        height = media_item.height.to_i * ::Regexp.last_match(1).to_i / 100
      end
    elsif media_item.height
      height = media_item.height.to_i
    end

    if width
      if width =~ /(\d+)%/ && media_item.width
        width = media_item.width.to_i * ::Regexp.last_match(1).to_i / 100
      end
    elsif media_item.width
      width = media_item.width.to_i
    end

    [width, height]
  end
end
