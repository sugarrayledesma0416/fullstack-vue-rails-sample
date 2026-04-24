class UpdatesProgramIdInVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    VocabWord.all.each do |word|
      if word.default_vocab_word_id.present?
        program = word.default_vocab_word.program_id
        word.update_attributes(:program_id => program)
      end
    end
  end

  def self.down
    VocabWord.update_all(:program_id => nil)
  end
end
