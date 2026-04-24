class FlashcardsController < ActivitiesController
  layout 'activity_popup'
  include FlashcardsActivities

  skip_before_action :ensure_correct_section

  def show
    @activity = Activity.find(params[:id]).extend(ActivityViewDecorator)
    @section_id = params[:section_id]
    @hide_flashcards_terms_index = true
    unless params[:flashcards_deck_id].blank?
      return render_flashcards_deck(@activity, params)
    end
  end
end
