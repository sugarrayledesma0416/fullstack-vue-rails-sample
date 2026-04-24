class AddVocabTutorialTranslationToCourse < ActiveRecord::Migration[5.2]
  def up
    add_column :courses, :enable_vocab_tutorial_translations, :boolean
    change_column_default :courses, :enable_vocab_tutorial_translations, false
  end

  def down
    remove_column :courses, :enable_vocab_tutorial_translations
  end
end
