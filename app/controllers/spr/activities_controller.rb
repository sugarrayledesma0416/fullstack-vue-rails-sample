module Spr
  class ActivitiesController < ::ActivitiesController
    def re_try(layout = 'layouts/spr_activity')
      super(layout)
    end

    def save(layout = 'layouts/spr_activity')
      super(layout)
    end

    def submit(layout = 'layouts/spr_activity')
      super(layout)
    end

    def practice(layout = 'layouts/spr_activity')
      super(layout)
    end

    def show_activity(params, layout = 'layouts/spr_activity')
      super(params, layout)
    end

    def popup_submit
      @is_popup = true
      set_activity_list_header
      submit('layouts/spr_activity_popup')
    end

    def popup_practice
      @is_popup = true
      practice('layouts/spr_activity_popup')
    end

    private def ensure_correct_family
      return if current_program.spr?

      redirect_to section_activity_path(id: params[:id], section_id: params[:section_id])
    end

    private def render_answer_keys
      if request_from_popup?
        @is_popup = true
        render layout: 'layouts/spr_activity_popup'
      else
        render layout: 'layouts/spr_activity'
      end
    end

    private def render_popup_show
      show_activity(params, 'layouts/spr_activity_popup')
    end
  end
end
