class ScoringRulesetFixer
  def fix
    #find all Categories where category.current_scoring_ruleset.category_id != category.id
    broken_categories = Category.find_by_sql("select * from categories c left outer join scoring_rulesets s on c.current_scoring_ruleset_id = s.id where s.category_id != c.id")
    broken_categories.each do |cat|
      old_ruleset = cat.current_scoring_ruleset
      new_ruleset = ScoringRuleset.create(category_id: cat.id,
                                      ignore_accents: old_ruleset.ignore_accents,
                                      ignore_capitalization: old_ruleset.ignore_capitalization,
                                      ignore_punctuation: old_ruleset.ignore_punctuation)
      cat.current_scoring_ruleset_id = new_ruleset.id
      cat.save
    end
  end
end
