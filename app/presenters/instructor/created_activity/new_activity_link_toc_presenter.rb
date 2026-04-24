module Instructor::CreatedActivity
  class NewActivityLinkTocPresenter < NewActivityLinkPresenter
    def menubar_classes
      "#{super}  new-activity  c-menu--admin"
    end

    def menu_item_classes
      "#{super}  u-pad-0"
    end

    def menu_item_link_classes
      "#{super}  c-menu__title  c-button--border  u-pad-bot-12  create-new-activity"
    end

    def menu_inner_classes
      "#{super}  js-store-selected-template"
    end

    def menu_subitem_classes
      "#{super}  c-menu--admin__subitem"
    end

    def menu_subitem_link_classes(activity_type)
      "#{super}  create-activity-link"
    end

    def button_label
      'Create new'
    end
  end
end
