class InstitutionAdminTocPresenter < InstructorTocPresenter
  def base_url(options = {})
    Rails.application
         .routes
         .url_helpers
         .institution_admin_show_toc_template_path(program.id,
                                                   current_focus.course.id,
                                                   @req_params[:section_id],
                                                   options)
  end

  def toc_path(*args)
    Rails.application
         .routes
         .url_helpers
         .institution_admin_show_toc_template_path(program.id,
                                                   current_focus.course.id,
                                                   @req_params[:section_id],
                                                   *args)
  end
end
