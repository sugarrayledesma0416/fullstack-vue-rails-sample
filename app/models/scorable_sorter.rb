module ScorableSorter
  DEFAULT_CONCEPT_RANK = 200
  # DEFAULT_CONCEPT_COMBINED_RANK = 10_201

  def location_value
    10**3 * concept_combined_rank_scorable + concept_rank_for_scorable
  end

  def toc_location_rank_in_lesson
    lesson.toc_location_rank_by_id(toc_location)
  end

  def sort_by_location(item_collection)
    item_collection.sort_by do |sortable_item|
      activity = sortable_item.is_a?(Assignment) ? sortable_item.assignable : sortable_item
      [activity.lesson.combined_rank, activity.location_value]
    end
  end

  def concept_rank_for_scorable
    defined?(concept_rank) ? concept_rank : DEFAULT_CONCEPT_RANK
  end
  private :concept_rank_for_scorable

  def concept_combined_rank_scorable
    defined?(concept_combined_rank) ? concept_combined_rank : (lesson.combined_rank * 100 + DEFAULT_CONCEPT_RANK)
  end
  private :concept_combined_rank_scorable
end
