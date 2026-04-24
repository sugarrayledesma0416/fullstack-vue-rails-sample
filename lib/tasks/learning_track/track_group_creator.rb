module LearningTrack
  class TrackGroupCreator
    attr_reader :activities, :book_id

    def initialize(book_id, activities)
      @activities = activities
      @book_id = book_id
    end

    def create
      lesson_id_concept_id_combos = activities.group_by { |a| [a.lesson_id, a.concept_id] }.keys
      lesson_id_concept_id_combos.each do |lesson_id, concept_id|
        ["Learn", "Practice", "Interact"].each do |name|
          attributes = {
            :name => name,
            :lesson_id => lesson_id,
            :concept_id => concept_id,
            :program_id => book_id,
            :how_to_use => "Instructions for #{name}",
            :objective => "Objective for #{name}"
          }
          find_or_create_track_group(attributes)
        end
      end
    end

    def find_or_create_track_group(attributes)
      TrackGroup.where(attributes.except(:how_to_use, :objective)).first ||
        TrackGroup.create!(attributes)
    end
    private :find_or_create_track_group
  end
end
