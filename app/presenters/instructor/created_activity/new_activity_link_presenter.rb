module Instructor::CreatedActivity
  class NewActivityLinkPresenter < ActivityTypePresenter
    attr_reader :instructor_presenter

    delegate :allowed_to_create_content?, to: :instructor_presenter

    def initialize(view, instructor_presenter)
      super(view)
      @instructor_presenter = instructor_presenter
    end

    def menubar_classes
      'c-menubar  js-nav-system'
    end

    def menu_item_classes
      'c-menu__item  js-nav-system__item'
    end

    def menu_item_link_classes
      'c-button  js-nav-system__link'
    end

    def button_icon
      Music::Components.icon(variant: 'add', **button_icon_options)
    end

    def menu_inner_classes
      'c-menu__inner  js-nav-system__subnav'
    end

    def menu_subitem_classes
      'c-menu__subitem  js-nav-system__subnav__item'
    end

    def menu_subitem_link_classes(activity_type)
      'js-nav-system__subnav__link'
    end

    def new_created_activity_link(activity_type, activity_params = {})
      @view.link_to(
        activity_label(activity_type, activity_params),
        new_created_activity_url(activity_type, activity_params),
        class: menu_subitem_link_classes(activity_type),
        role: 'menuitem'
      )
    end

    def menu_subitem_element(activity_type, activity_params = {})
      @view.content_tag :li, class: menu_subitem_classes, role: 'none' do
        new_created_activity_link(activity_type, activity_params)
      end
    end

    private def button_icon_options
      {}
    end

    private def displayable_activity_kind
      :activity
    end

    private def new_created_activity_url(activity_type, activity_params)
      Rails.application.routes.url_helpers.new_instructor_created_activity_path(
        program_id: @instructor_presenter.program.id,
        lesson_id: @instructor_presenter.display_lesson.id,
        toc_entry_id: @instructor_presenter.current_topic,
        activity_type:,
        **activity_params,
        **new_activity_url_params
      )
    end

    private def new_activity_url_params
      {}
    end
  end
end
