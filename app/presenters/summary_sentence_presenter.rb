class SummarySentencePresenter

include ActionView::Helpers::TagHelper
include ActionView::Helpers::SanitizeHelper

  def initialize(presenter_type, options={})
    @presenter_type = presenter_type
    @filter = options[:filter]
    @strands = options[:strands] || []
  end

  def sentence
    return location_sentence if @presenter_type == 'location'
    return previously_assigned_sentence if @presenter_type == 'previously assigned'
    return properties_sentence if @presenter_type == 'properties'
  end

  private

  def properties_sentence
    content_label = @filter.selected_content_type

    if @filter.activity_type.present? && @filter.grading_method.present?
      make_dropdown(@filter.displayable_selected_activity_type, :class => 'activity_type') + " #{content_label.downcase}" + " that are " +
      make_dropdown(@filter.grading_method.capitalize ,:class => 'grading_method') + " Graded"
    elsif  @filter.activity_type.present?
      return "#{content_label}" + " that have " + make_dropdown(@filter.displayable_selected_activity_type, :class => 'activity_type') if @filter.activity_type == "Audio hotspots"
      make_dropdown(@filter.displayable_selected_activity_type.singularize, :class => 'activity_type') + " #{content_label}"
    elsif @filter.grading_method.present?
      "#{content_label} that are " + make_dropdown(@filter.grading_method.capitalize, :class => 'grading_method') + " Graded"
    else
      "All #{content_label}"
    end
  end

  def previously_assigned_sentence
    section = @filter.previous_section
    category = @filter.category
    if section.present? && @filter.week.present?
      if category.present?
        "Activities that were assigned for " + make_dropdown("#{section.course.name} #{section.name}", :class=>'previous_section') +
        " in "+ make_dropdown("Week #{week_number}", :class => 'week') + " as " +
        make_dropdown(category.name, :class => 'previous_category')
      else
        "Activities that were assigned for " + make_dropdown("#{section.course.name} #{section.name}", :class => 'previous_section') + " in " +
        make_dropdown("Week #{week_number}", :class => 'week')
      end
    elsif section.present? && @filter.day.present?
      common_sentence = "Activities that were assigned for " + make_dropdown("#{section.course.name} #{section.name}", :class=>'previous_section') +
                        " on "+ make_dropdown(@filter.day.strftime('%a %b %e, %Y'), :class => 'day')
      if category.present?
        common_sentence + " as " + make_dropdown(category.name, :class => 'previous_category')
      else
        common_sentence
      end
    elsif section.present? && category.present?
      "Activities that were assigned for " + make_dropdown("#{section.course.name} #{section.name}", :class=>'previous_section') +
      " as " + make_dropdown(category.name, :class => 'category')
    else
      return "Activities that were assigned for " + make_dropdown("#{section.course.name} #{section.name}", :class => 'previous_section') if section.present?
      "All Activities even if we haven't previously assigned them"
    end
  end

  def location_sentence
    if @filter.lesson.present?
      strand = @strands.detect{ |s| s.location == @filter.toc_entry_location.to_s }
      if @filter.toc_entry_location.present? && strand.present?
        return make_dropdown(@filter.component.singularize, :class => 'component') +
               " Activities from " + make_dropdown(@filter.lesson.name, :class => 'lesson') + " in " +
                make_dropdown(strand.title, :class => 'strand') if @filter.component.present?

        return "Activities from " +
                make_dropdown(@filter.lesson.name, :class => 'lesson') + " in " +
                make_dropdown(strand.title, :class => 'strand')
      else
        return make_dropdown(@filter.component.singularize, :class => 'component') +
               " Activities from " + make_dropdown(@filter.lesson.name, :class => 'lesson') if @filter.component.present?
        return "Activities from " + make_dropdown(@filter.lesson.name, :class => 'lesson')
      end
    else
      'Activities from all lessons'
    end
  end

  def make_dropdown(content, class_hash = {})
    "<span class='#{class_hash}'>#{sanitize(content, tags: %w[span], attributes: %w[lang])}</span>" + \
    "<a href='##{class_hash[:class]}_dropdown' class='menu_icon' rel='##{class_hash[:class]}_dropdown'><img src='/images/bkgd-blue-arrow.png' /></a>".html_safe
  end

  def week_number
    ( Week.week_containing(@filter.week) - Week.week_containing(@filter.previous_section.course.start_date) ).to_i / 7 + 1
  end
  private :week_number

end
