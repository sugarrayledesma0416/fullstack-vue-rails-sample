module MostRecentSectionHandling
  def store_most_recent_section
    # TODO: Add request specs for section zero guard clause. Need to find an
    # action that takes a section_id url parameter but doesn't include
    # the before_action require_program_access, otherwise application
    # controller will raise:
    # ActionController::RoutingError: No valid program specified.
    return unless current_user.student? && has_section_id?

    # This case may never be reached, as it can only happen if a URL contains
    # a section_id parameter that doesn't point to a valid section. If this
    # happens, most controllers will already throw some kind of exception,
    # but it's worth having the guard clause to avoid throwing an error here
    # and thus obscure any errors that would normally be thrown later.
    return if current_section.nil?

    # This case will likely never occur in the wild, but the data setup
    # in some controller specs can trigger it.
    return if current_program.nil?

    session[:most_recent_section] ||= {}
    session[:most_recent_section]["program_#{current_program.id}"] = current_section.id
  end

  def most_recent_section_id
    return unless current_user.student?

    session.dig(:most_recent_section, "program_#{current_program.id}")
  end

  private def has_section_id?
    params[:section_id].present? && params[:section_id] != '0'
  end
end
