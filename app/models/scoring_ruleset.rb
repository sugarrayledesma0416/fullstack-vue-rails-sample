class ScoringRuleset < ApplicationRecord
  belongs_to :category, optional: true

  attr_writer :chinese
  after_create :set_current_scoring_ruleset_on_category

  def respected_features_list
    feature_list = []
    %i[ignore_accents ignore_capitalization ignore_punctuation].each do |rule|
      status = ignore_rule?(rule)
      feature_list << { text: rule.to_s.split('_')[-1], status: status }
    end
    feature_list
  end

  def self.new_course_defaults
    ruleset = default.clone
    {
      'must_match_accents' => ruleset.must_match_accents,
      'must_match_capitalization' => ruleset.must_match_capitalization,
      'must_match_punctuation' => ruleset.must_match_punctuation
    }
  end

  def self.default
    find_by(category_id: nil) || create!(
      ignore_accents: false,
      ignore_capitalization: true,
      ignore_punctuation: true
    )
  end

  def chinese?
    !!@chinese
  end

  def must_match_accents
    !ignore_accents?
  end

  def must_match_capitalization
    !ignore_capitalization?
  end

  def must_match_punctuation
    !ignore_punctuation?
  end

  def must_match_accents=(value)
    self.ignore_accents = !param_to_boolean(value)
  end

  def must_match_capitalization=(value)
    self.ignore_capitalization = !param_to_boolean(value)
  end

  def must_match_punctuation=(value)
    self.ignore_punctuation = !param_to_boolean(value)
  end

  private def set_current_scoring_ruleset_on_category
    category&.update!(current_scoring_ruleset_id: id)
  end

  private def param_to_boolean(value)
    if ['true', '1', 1].include? value
      true
    elsif ['false', '0', 0].include? value
      false
    else
      !!value
    end
  end

  private def ignore_rule?(rule)
    public_send(rule)
  end
end
