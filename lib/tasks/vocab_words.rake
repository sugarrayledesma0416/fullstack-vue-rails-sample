require 'csv'
require_relative 'csv_read_write'
require_relative 'vocab_tags_translator'

namespace :vocab_words do
  desc 'translate existing lesson-based tags to appropriate lessons by title'
  task :translate_lesson_tags => :environment do |t, args|

    words_without_lesson = DefaultVocabWord.where(lesson_id: nil)
    VocabTagsTranslator.new(words_without_lesson).translate
  end

  desc "Adds default vocabulary word seed data for a program and language"
  task :seed => :environment do |t, args|
    if ENV['program_id'].blank? || ENV['filename'].blank? || ENV['language'].blank?
      puts "usage: rake vocab_words:seed program_id=<id> filename=<filename> language=<es>"
      exit(1)
    end

    filename = ENV['filename']
    common_data = {
      :language   => ENV['language'],
      :program_id => ENV['program_id']
    }

    # Merge csv data with the common data given in the command line arguments.
    vocab_words = CsvReadWrite.read(filename).map do |word|
      word.merge(common_data)
    end

    DefaultVocabWord.create(vocab_words)
  end

  desc "Adds 1000+ default vocabulary words and tags for a program and language"
  task :generate_large_dataset => :environment do |t, args|
    if ENV['program_id'].blank? || ENV['language'].blank?
      puts "usage: rake vocab_words:generate_large_dataset program_id=<id> language=<lang> [word_count=<word_count>]"
      exit(1)
    end

    [DefaultVocabWord, DefaultVocabTag, VocabTag, VocabWord].map(&:delete_all)

    vocab_word_count = ENV['word_count'] || 1000
    words = []
    vocab_word_count.times do |index|
      fake_words = Faker::Lorem.words(5)
      word = DefaultVocabWord.new({:target_word => "#{fake_words[0]}_#{index}",
                                   :base_word => "#{fake_words[1]}_#{index}",
                                   :target_definition => "#{fake_words[2]}_#{index}",
                                   :language => ENV['language'],
                                   :program_id => ENV['program_id'] })

      word.vocab_tags.build([{:name => "#{fake_words[3]}_#{index}"}, {:name => "#{fake_words[4]}_#{index}"}])
      word.save
    end
  end

  desc "Populate real vocab words and vocab tags"
  task :populate_real_data => :environment do |t, args|

    if ENV['program_id'].blank? || ENV['language'].blank? || ENV['filename'].blank?
      puts "usage: rake vocab_words:populate_real_data program_id=<id> language=<lang> filename=<filename>"
      puts "common locations of vocab tool csv's is db/example_data/"
      exit(1)
    end

    filename = ENV['filename']
    csv_friendly_file = File.open(filename).read.encode('UTF-8', 'Windows-1252')
    csv_word_rows = CSV.parse(csv_friendly_file, :headers => true, :encoding => 'u')

    common_data = {
      :language   => ENV['language'],
      :program_id => ENV['program_id']
    }

    word_attrs = csv_word_rows.inject([]) do |memo, row|
      row = row.to_hash.merge(common_data) #add language and program_id to word attributes
      row['vocab_tags_attributes'] = row['vocab_tags_attributes'].split(';').map{|tag| {:name => tag} } #parse ; separated tags, and create array of new tags
      memo << row
      memo
    end

    DefaultVocabWord.create(word_attrs)
  end
end
