module Instructor::CreatedActivity
  class NewActivityLinkContentPresenter < NewActivityLinkPresenter
    def menu_item_link_classes
      "#{super}  m4-button--primary  u-pad-8  u-pad-lt-16  u-pad-rt-16"
    end

    def menu_inner_classes
      "#{super}  u-bord-radius-16"
    end

    def menu_subitem_link_classes(activity_type)
      "#{super}  menu__link  u-txt-bold"
    end

    def button_label
      'Create'
    end

    private def button_icon_options
      { size: 'sm', invert: true, classes: ['u-mar-rt-6'] }
    end

    private def new_activity_url_params
      { from_my_content: 'true' }
    end
  end
end
