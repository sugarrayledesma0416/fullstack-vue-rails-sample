module FlashcardsActivities
  def render_flashcards_deck(activity, params)
    render :template => "maestro_activity_engine/activities/previews/flashcards_partials/_deck", 
      :locals => {
        :activity => activity,
        :deck_number => params[:flashcards_deck_id],
        :deck_type => params[:flashcards_deck_type],
        :target_language => activity.content_object.language_name
      }
  end
end
