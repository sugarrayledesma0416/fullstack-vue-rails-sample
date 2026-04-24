module Enterprise::BreadcrumbHelper
  def build_breadcrumb(presenter, action)
    @presenter = presenter
    @breadcrumb = []
    @breadcrumb << link_to('Dashboard', institution_admin_dashboard_path, class: 'u-txt-black')

    case action
    when 'courses'
      add_with_no_link(@presenter.program.title)
    when 'sections'
      add_program(@presenter.program.title)
      add_with_no_link(@presenter.course&.name)
    when 'section_metrics'
      add_program(@presenter.program.title)
      add_with_no_link('Progress')
    end

    @breadcrumb.join(content_tag("music-icon-caret".to_sym, '', size: 'md', class: 'u-mar-bot-6  u-mar-lt-10  u-mar-rt-10').html_safe)
  end

  private def add_with_no_link(content)
    @breadcrumb << content
  end

  private def add_program(program_title)
    @breadcrumb << link_to(program_title, institution_admin_courses_current_path(program_id: @presenter.program.id, school_id: @presenter.school.id), class: 'u-txt-black')
  end
end
