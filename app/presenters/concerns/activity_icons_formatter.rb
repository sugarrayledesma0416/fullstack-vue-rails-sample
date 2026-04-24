module ActivityIconsFormatter
  # Adds an apple icon if instructor graded.
  # Prefixes 'textbook' icon with 'vol_' when @current_program is vista_online_learning family
  def format_activity_icons(icons_str, is_program_vol, is_instructor_graded)
    icons = icons_str.to_s.split(',')
    add_instructor_graded_icon(format_vol_icons(icons, is_program_vol), is_instructor_graded)
  end

  # This performs the same check as #icon on the Activity class with less db calls.
  private def format_vol_icons(icons, is_program_vol)
    return icons unless is_program_vol

    icons.map do |icon|
      icon == 'textbook' ? 'vol_textbook' : icon
    end
  end

  private def add_instructor_graded_icon(icons, is_instructor_graded)
    return icons unless is_instructor_graded

    icons.push('apple')
  end
end
