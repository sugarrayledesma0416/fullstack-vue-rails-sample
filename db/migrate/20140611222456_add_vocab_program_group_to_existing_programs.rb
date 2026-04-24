class AddVocabProgramGroupToExistingPrograms < ActiveRecord::Migration[4.2]
  def self.up
    Program.all.each do |program|
      unless program.vocab_program_group
        program_group = VocabProgramGroup.create
        program.update_attributes(vocab_program_group_id: program_group.id)
      end
    end
  end

  def self.down
    Program.all.each do |program|
      program_group = program.vocab_program_group
      vocab_words = program_group.default_vocab_words || program_group.vocab_words
      unless vocab_words
        program_group.destroy
        program.update_attributes(vocab_program_group_id: nil)
      end
    end
  end
end
