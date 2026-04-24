class CustomRubricLoader
  attr_accessor :activity, :current_user, :current_section, :current_focus
  attr_writer :course

  def initialize(activity, current_user, current_section, current_focus = nil)
    self.activity = activity
    self.current_user = current_user
    self.current_section = current_section

    if current_user.instructor? && current_focus.nil?
      load_current_focus
    elsif current_user.instructor? && !current_focus.nil?
      self.current_focus = current_focus
    end
  end

  def load_xml_from_custom_rubric
    # We will load only custom rubrics for activities that are copies of
    # vhl-authored activities and for vhl-authored activities that have inline
    # or external rubrics.
    if course.blank? || !(activity.instructor_created? ||
        activity.has_inline_rubric? || activity.has_external_rubric?)
      return nil
    end

    custom_rubric = custom_rubric_query

    if custom_rubric
      xml = custom_rubric[:stored_rubric]
      if xml
        doc = Nokogiri::XML.parse(xml).children[0]
        parser = MaestroActivityEngine::TagParser::Rubric.new(doc, '.')
        rubric_object = parser.parse([])&.first
        update_rubric(rubric_object)
      end
    end
  end

  def course
    @course ||= current_user.instructor? ? current_focus&.course : current_section.course
  end

  private def update_rubric(new_rubric)
    if activity.has_external_rubric?
      activity.content_object.external_rubric.update_rubric(new_rubric)
    elsif activity.has_inline_rubric?
      activity.content_object.inline_rubric&.first.update_rubric(new_rubric)
    else
      activity.content_object.update_rubric(new_rubric)
    end
  end

  private def custom_rubric_query
    CustomRubric.where(
      course_id: course.id,
      draft: false,
      source_rubric_id: rubric_content&.rubric&.cms_rubric_id
    ).last
  end

  private def rubric_content
    @rubric_content = if activity.has_inline_rubric?
                        activity.content_object.inline_rubric&.first
                      elsif activity.has_external_rubric?
                        activity.content_object.external_rubric
                      else
                        activity.content_object
                      end
  end

  private def load_current_focus
    unless current_user.cartridge?
      options = {
        activity.program.id.to_s => { section_id: current_section.id }
      }
      self.current_focus = Focus.new(current_user, activity.program, options)
    end
  end
end
