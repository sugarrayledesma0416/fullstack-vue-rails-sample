module Instructor::CreatedActivity
  class NewActivityLinkAssessmentPresenter < NewActivityLinkPresenter
    def menubar_classes
      "#{super}  c-menu--admin"
    end

    def menu_item_link_classes
      "#{super}  c-menu__title  c-button--border  #{@view.test_class('create-new-menu')}"
    end

    def menu_inner_classes
      "#{super}  js-store-selected-template"
    end

    def menu_subitem_classes
      "#{super}  c-menu--admin__subitem"
    end

    def menu_subitem_link_classes(activity_type)
      classes = super
      classes += '  assessment_link' if activity_type == :exam

      classes
    end

    def button_label
      'Create new'
    end

    private def displayable_activity_kind
      :assessment
    end

    private def new_created_activity_url(activity_type, activity_params)
      if activity_type == :exam
        Rails.application.routes.url_helpers.instructor_new_assessment_path(
          program_id: @instructor_presenter.program.id,
          lesson_id: @instructor_presenter.display_lesson.id,
          toc_entry_id: @instructor_presenter.current_strand
        )
      else
        super
      end
    end
  end
end
