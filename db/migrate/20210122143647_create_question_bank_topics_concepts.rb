class CreateQuestionBankTopicsConcepts < ActiveRecord::Migration[5.2]
  def change
    create_table :question_bank_topics_concepts do |t|
      t.references :question_bank_topic
      t.references :concept
      t.timestamps
    end
  end
end
