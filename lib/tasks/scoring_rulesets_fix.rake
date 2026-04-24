require_relative 'scoring_rulesets_fixer'
namespace :live do
  desc "fix errors caused by categories referencing the wrong scoring ruleset"
  task :fix_scoring_rulesets => :environment do |cmd_name|
    fixed_categories = ScoringRulesetFixer.new.fix
    puts "Finished."
    puts "Fixed the following Categories (and their current_scoring_rulesets): #{fixed_categories.map(&:id)}"
  end
end

