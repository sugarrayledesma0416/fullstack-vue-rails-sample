module RubricLinkable
  include PopupHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Context
  delegate :rubric_section_activity_path, to: :rails_url_helpers

  def rails_url_helpers
    Rails.application.routes.url_helpers
  end

  def format_rubric_link(link_text, icon = nil)
    link_to(
      format_rubric_path,
      role: 'button',
      onclick: format_rubric_popup_onclick,
      target: '_blank',
      rel: 'noopener'
    ) do
      format_rubric_icon(link_text, icon)
    end
  end

  private def format_rubric_popup_onclick
    format_popup_onclick(
      window_name: 'preview_rubric',
      width: 985,
      height: 600
    )
  end

  private def format_rubric_icon(link_text, icon)
    return link_text if icon == 'none'
    icon ? rubric_activity_icon(icon, link_text) : rubric_grading_icon(link_text)
  end

  private def rubric_grading_icon(link_text)
    Music::Components.icon(
      variant: 'reference',
      classes: 'u-txt-plain'
    ).insert(0, content_tag(:span, link_text, class: 'rubric-link-text  u-pad-rt-8'))
  end

  private def rubric_activity_icon(icon, link_text)
    icon << content_tag(:span, link_text, class: 'rubric-link-text  u-pad-rt-8  u-pad-lt-8')
  end

  private def format_rubric_path
    raise NotImplementedError, 'format_rubric_path must be defined'
  end
end
