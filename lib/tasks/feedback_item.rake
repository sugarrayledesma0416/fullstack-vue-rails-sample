require_relative 'feedback_item_fixer'

namespace :feedback_item do
  desc 'Fixes duplicate FeedbackItem (that have same attempt_id, question_label and user_id)'
  task :fix_duplicates => :environment do |cmd_name|
    fixer = FeedbackItemFixer.new
    feedback_items_to_fix = fixer.duplicate_feedback_items
    puts "There are #{fixer.total_to_fix} FeedbackItem records that present duplication."
    puts "Fix started"
    fixer.perform
    puts "Fix ended"
  end
end
