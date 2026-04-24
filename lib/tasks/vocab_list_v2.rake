#encoding: utf-8
namespace :vocab_list_v2 do
  desc "Extract words from vocabulary activities for vocab-tools feature"
  task :extract_vocab_words, [:program_id]  => :environment do |task, args|
    program = Program.find(args.program_id)
    VocabListV2Extractor.generate_vocabulary_for(program)
  end

  desc "Clean up vocabulary words for a given program"
  task :delete_vocab_words, [:program_id, :dry_run] => :environment do |task, args|
    if args[:program_id].nil? || args[:dry_run].nil?
      puts "Usage #{task}[program_id,dry_run]"
      abort
    end

    count = VocabWordsCleaner.clean(args[:program_id], args[:dry_run] == 'false')
    puts "Deleted records #{count}"
  end
end
