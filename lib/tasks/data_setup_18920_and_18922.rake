namespace :my_vocab do
  require 'csv'

  desc 'set qa data for stories 18920, 18922'
  task :setup => :environment do |t, args|

    if ENV['username'].blank?
      puts "usage: rake my_vocab:setup username=<username>"
      exit(1)
    end

    student = User.where(username: ENV['username']).first
    vocab_group = VocabProgramGroup.create!
    other_vocab_group = VocabProgramGroup.create!

    program_temas = Program.find 61
    program_temas.update(vocab_program_group_id: vocab_group.id)

    program_ap_spanish = Program.find 60
    program_ap_spanish.update(vocab_program_group_id: vocab_group.id)

    program_without_access = Program.where(title: 'Panorama, Fourth Edition').first
    program_without_access.update(vocab_program_group_id: vocab_group.id)

    program_descubre = Program.where(title: 'Descubre 1A').first
    program_descubre.update(vocab_program_group_id: vocab_group.id)

    program_in_other_program_group = Program.where(title: 'Promenades, Second Edition').first
    program_in_other_program_group.update(vocab_program_group_id: other_vocab_group.id)

    default_word_temas = FactoryBot.create(:default_vocab_word,
                                              vocab_program_group_id: vocab_group.id,
                                              target_word: 'temas',
                                              program_id: program_temas.id)
    default_word_panorama = FactoryBot.create(:default_vocab_word,
                                                  vocab_program_group_id: vocab_group.id,
                                                  arget_word: 'panorama',
                                                  rogram_id: program_without_access.id)
    default_word_descubre = FactoryBot.create(:default_vocab_word,
                                                  vocab_program_group_id: other_vocab_group.id,
                                                  target_word: 'descubre',
                                                  program_id: program_descubre.id)
    default_word_promenades = FactoryBot.create(:default_vocab_word,
                                                  vocab_program_group_id: vocab_group.id,
                                                  target_word: 'promenades',
                                                  program_id: program_in_other_program_group.id)

    temas_german_word = FactoryBot.create(:vocab_word,
                                              vocab_program_group_id: vocab_group.id,
                                              target_word: 'temas_german_word',
                                              user_id: student.id,
                                              program_id: program_temas.id,
                                              language: 'de')
    no_program_german_word = FactoryBot.create(:vocab_word,
                                                  vocab_program_group_id: vocab_group.id,
                                                  target_word: 'no_program_german_word',
                                                  user_id: student.id,
                                                  language: 'de')

    puts "User id: " + student.id.to_s
  end
end
