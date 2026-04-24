require_relative 'question_bank_topic_parser'
require_relative 'question_bank_topic_concept_parser'

namespace :topics do
  desc 'Imports question bank topic data from file'
  task import: :environment do
    extend ActionView::Helpers

    parser = QuestionBankTopicParser.new
    progress_bar = RakeProgressbar.new(parser.row_count)

    if parser.validate
      parser.import do
        progress_bar.inc
      end
      progress_bar.finished
    end

    puts parser.errors.inspect
  end
end

namespace :topic_concepts do
  desc 'Imports question bank topic concept mappings data from a semi-colon separated file'
  task import: :environment do
    extend ActionView::Helpers

    parser = QuestionBankTopicConceptParser.new
    progress_bar = RakeProgressbar.new(parser.row_count)

    if parser.validate
      parser.import do
        progress_bar.inc
      end
      progress_bar.finished
    end

    puts parser.errors.inspect
  end
end
