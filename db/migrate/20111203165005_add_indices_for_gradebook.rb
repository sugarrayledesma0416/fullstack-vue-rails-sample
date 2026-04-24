class AddIndicesForGradebook < ActiveRecord::Migration[4.2]
  def self.up
    add_index :grades, :user_id
    add_index :grades, :section_id
    add_index :grades, :coordinates_key
    add_index :grades, :category_id
    add_index :assignments, :category_id
    add_index :activities, :lesson_id
    add_index :concepts, :lesson_id
    add_index :concepts, :program_id
    add_index :courses, :owner_id
    add_index :feedback_items, :attempt_id
    add_index :feedback_items, :question_label
    add_index :feedback_items, :user_id
    add_index :feedback_items, :section_id
    add_index :grade_offsets, :user_id
    add_index :grade_offsets, :section_id
    add_index :lessons, :unit_id
    add_index :score_adjustments, :score_id
    add_index :units, :program_id
  end

  def self.down
    remove_index :grades, :user_id
    remove_index :grades, :section_id
    remove_index :grades, :coordinates_key
    remove_index :grades, :category_id
    remove_index :assignments, :category_id
    remove_index :activities, :lesson_id
    remove_index :concepts, :lesson_id
    remove_index :concepts, :program_id
    remove_index :courses, :owner_id
    remove_index :feedback_items, :attempt_id
    remove_index :feedback_items, :question_label
    remove_index :feedback_items, :user_id
    remove_index :feedback_items, :section_id
    remove_index :grade_offsets, :user_id
    remove_index :grade_offsets, :section_id
    remove_index :lessons, :unit_id
    remove_index :score_adjustments, :score_id
    remove_index :units, :program_id
  end
end
