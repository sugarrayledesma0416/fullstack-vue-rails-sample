module SectionSelector
  extend ActiveSupport::Concern

  private def assign_session_selector_attrs
    @show_section_selector = @sections&.count > 1 && !@selected_section
  
    if @show_section_selector
      @return_to = params[:return_to] || request.fullpath
    end
  end
end
