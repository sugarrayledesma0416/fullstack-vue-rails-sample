class CreateQuestionBankTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :question_bank_topics do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
