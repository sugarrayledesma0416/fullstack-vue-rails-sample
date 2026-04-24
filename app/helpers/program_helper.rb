module ProgramHelper

  def format_selectable_reference_links(program, lesson_id = nil)
    links = program.reference_links.map do |value|
      [value.label, value.link]
    end.insert(0, 'Select reference tools.')

    if program.has_vocab_tools? && lesson_id
      add_vocab_tools_words_link(program, lesson_id, links)
    else
      links
    end
  end

  def add_vocab_tools_words_link(program, lesson_id, links)
    lesson = Lesson.find(lesson_id)
    units_path = "/#{program.id}/vocab_tools/units"
    words_link = vocab_tools_words_path(program.id, current_section, unit_id: lesson.unit_id)

    links.map do |link|
      name, uri = link

      if uri == units_path
        [name, words_link]
      else
        link
      end
    end
  end

  def format_toc_entry_title(toc_entry)
    title_style = nil
    title_style = "background-color: #{toc_entry.background_color}; color: white;" unless toc_entry.background_color.blank?
    content_tag(:div, toc_entry.title, :class => 'toc_entry_title', :style => title_style)
  end

  def process_lesson(lesson)
    if @controller.class == Instructor::AssessmentsController
      lesson.extend(LessonWithAssessmentStrands)
    end
    lesson
  end

  def assign_strand_html_options(toc_entry, is_parent)
    strand_html_options = { class: "c-button  c-button--strand  test-strand" }
    if is_parent
      strand_html_options[:class] << '  parent'
      strand_html_options[:style] = "--stripe-color: #{toc_entry.background_color}"
    end
    strand_html_options
  end

  def total_question_count(activity_question_summary)
    activity_question_summary.inject(0){|sum,x| sum + x[1] } if activity_question_summary
  end

  def assign_first_child_with_location(toc_entry)
    toc_entry.children.find{|child| child.location  =~ /^\d+$/ }
  end

  def choose_first_child_with_activities(toc_entry, first_child, sections, current_user)
    (toc_entry.activities_list(sections:, current_user:).empty? ? first_child.location : toc_entry.location)
  end

  def format_prev_unit_link(first_unit, presenter)
    options = { :class => "prev",
                :id => 'carousel_previous'}
    link_to(content_tag('span', 'Previous'),
            presenter.base_url(:start_unit => presenter.start_unit - 1),
            options)
  end

  def format_next_unit_link(last_unit, presenter)
    options = {:class => "next", :id => 'carousel_next'}
    link_to(content_tag('span', 'Next'),
            presenter.base_url(:start_unit => presenter.start_unit + 1),
            options )
  end

  def two_line_unit_name(unit)
    unit_name_parts = unit.name.split(' - ')
    if unit_name_parts.size == 2
      unit_name_spans(unit_name_parts, '<br />')
    else
      unit.name
    end
  end

  def two_part_unit_name(unit)
    unit_name_parts = unit.name.split(' - ')
    if unit_name_parts.size == 2
      unit_name_spans(unit_name_parts)
    else
      unit.name
    end
  end

  def unit_name_spans(unit_name_parts, br = '')
    ('<span class="unit_number">' +  unit_name_parts[0] + '</span>' + br +
     '<span class="unit_title">' + unit_name_parts[1] + '</span>').html_safe
  end
  private :unit_name_spans

  def unit_carousel_member_for(unit_rank, current_rank, visible_unit_ranks, &block)
    unit_rank = unit_rank.to_i
    contents = capture(&block) if block_given?
    unit_display_style = unit_rank_in_bound?(unit_rank, current_rank) ? 'block' : 'none'
    classes = build_classes_for_carousel(unit_rank, current_rank, visible_unit_ranks)
    concat(content_tag(:div,
                       contents,
                       :id => "unit_rank_#{unit_rank}",
                       :class => classes,
                       :style => "display: #{unit_display_style};"))
  end

  def unit_rank_in_bound?(unit_rank, current_rank)
    ((current_rank - 2)..(current_rank + 2)).include?(unit_rank)
  end
  private :unit_rank_in_bound?

  def build_classes_for_carousel(unit_rank, current_rank, visible_unit_ranks)
    [].tap do |s|
      s << "item"
      s << "course_units_link" if visible_unit_ranks.include? unit_rank
      s << "current_unit" if current_rank == unit_rank
    end.join(' ')
  end
  private :build_classes_for_carousel
end
