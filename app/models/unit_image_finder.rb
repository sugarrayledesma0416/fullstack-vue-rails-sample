module UnitImageFinder
  class << self
    # This is used by the Gradebook to retrieve the media item associated with
    # a Unit record. Even in single-tier (Lesson) programs, the media item
    # is always associated with the parent unit record for the lesson. The
    # Gradebook knows the unit_id for each lesson, but does not have a Unit
    # model. This method takes that unit id, and returns the corresponding
    # media item if one exists.
    def unit_image(unit_id)
      unit = Unit.find_by(id: unit_id)
      unit&.media_item
    end
  end
end
