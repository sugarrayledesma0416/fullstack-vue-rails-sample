describe ScoringRuleset do

  it "should get set when course attributes are updated" do
    course = create(:course)
    category = create(:category, :course => course)

    posted_params = {'categories_attributes' => {'0' =>
    { 'id' => category.id, 'name' => '123', 'weighting_percent' => '100',
      'scoring_rulesets_attributes' => [{'must_match_accents' => '0', 'must_match_punctuation' => '1'}] } } }
    course.reload
    course.updated_by = course.owner_id
    course.update(posted_params)
    course.reload
    expect(course.categories.first.current_scoring_ruleset.ignore_accents?).to be_truthy
  end

  describe ".new_course_defaults" do
    it "returns the default form attributes hash" do
      default_params = ScoringRuleset.new_course_defaults
      expect(default_params).to be_a Hash
    end

    it "sets the default ruleset values" do
      default_ruleset = ScoringRuleset.default
      default_params = ScoringRuleset.new_course_defaults
      expect(default_params['must_match_accents']).to eql default_ruleset.must_match_accents
      expect(default_params['must_match_capitalization']).to  eql default_ruleset.must_match_capitalization
      expect(default_params['must_match_punctuation']).to eql default_ruleset.must_match_punctuation
    end
  end

  describe ".default" do
    it "should create a new entry if a default doesn't already exist." do
      expect(ScoringRuleset.all.length).to eql 0
      ScoringRuleset.default
      expect(ScoringRuleset.all.length).to eql 1
    end

    it "should have ignore_accents false" do
      default_ruleset = ScoringRuleset.default
      expect(default_ruleset.ignore_accents).not_to be_nil
      expect(default_ruleset.ignore_accents).to be_falsey
    end

    it "should have ignore_capitalization true" do
      default_ruleset = ScoringRuleset.default
      expect(default_ruleset.ignore_capitalization).not_to be_nil
      expect(default_ruleset.ignore_capitalization).to be_truthy
    end

    it "should have ignore_punctuation true" do
      default_ruleset = ScoringRuleset.default
      expect(default_ruleset.ignore_punctuation).not_to be_nil
      expect(default_ruleset.ignore_punctuation).to be_truthy
    end

    it "should use the existing entry if found" do
      ScoringRuleset.default
      expect(ScoringRuleset.all.length).to eql 1
      ScoringRuleset.default
      expect(ScoringRuleset.all.length).to eql 1
    end
  end

  it "should set database-backed ignore_* attribute values from must_match_* accessors" do
    scoring_ruleset = ScoringRuleset.new(:must_match_accents => false, :must_match_punctuation => true)
    expect(scoring_ruleset.ignore_accents?).to be_truthy
    expect(scoring_ruleset.ignore_punctuation?).to be_falsey
  end

  it "should set correct boolean when passed values of '1', '0'" do
    scoring_ruleset = ScoringRuleset.new(:must_match_accents => '0', :must_match_punctuation => '1')
    expect(scoring_ruleset.ignore_accents?).to be_truthy
    expect(scoring_ruleset.ignore_punctuation?).to be_falsey
  end

  it "should set correct boolean when passed values of 1, 0" do
    scoring_ruleset = ScoringRuleset.new(:must_match_accents => 0, :must_match_punctuation => 1)
    expect(scoring_ruleset.ignore_accents?).to be_truthy
    expect(scoring_ruleset.ignore_punctuation?).to be_falsey
  end

  describe "#respected_features_list" do
    it "should return an array of hashes with the status of each rule" do
      scoring_ruleset = create(:scoring_ruleset,
                        :ignore_capitalization => true,
                        :ignore_accents        => false,
                        :ignore_punctuation    => false)
      results = scoring_ruleset.respected_features_list
      expect(results).to be_a Array
      results.each do |result|
        expect(result).to be_a Hash
        case result[:text]
        when 'capitalization' then expect(result[:status]).to be_truthy
        when 'accents' then expect(result[:status]).to be_falsey
        when 'punctuation' then expect(result[:status]).to be_falsey
        end
      end
    end
  end

  describe "rule status" do
    describe "#must_match_accents" do
      it "should be true when accents is off" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_accents => true)
        expect(scoring_ruleset.ignore_accents?).to be_truthy
        expect(scoring_ruleset.must_match_accents).to be_falsey
      end

      it "should be false when accents are on" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_accents => false)
        expect(scoring_ruleset.ignore_accents?).to be_falsey
        expect(scoring_ruleset.must_match_accents).to be_truthy
      end
    end

    describe "#must_match_capitalization" do
      it "should be false when capitalization is off" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_capitalization => true)
        expect(scoring_ruleset.ignore_capitalization?).to be_truthy
        expect(scoring_ruleset.must_match_capitalization).to be_falsey
      end

      it "should be true when capitalization is on" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_capitalization => false)
        expect(scoring_ruleset.ignore_capitalization?).to be_falsey
        expect(scoring_ruleset.must_match_capitalization).to be_truthy
      end
    end

    describe "#must_match_punctuation" do
      it "should be true when punctuation is off" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_punctuation => true)
        expect(scoring_ruleset.ignore_punctuation?).to be_truthy
        expect(scoring_ruleset.must_match_punctuation).to be_falsey
      end

      it "should be false when punctuation is on" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_punctuation => false)
        expect(scoring_ruleset.ignore_punctuation?).to be_falsey
        expect(scoring_ruleset.must_match_punctuation).to be_truthy
      end
    end
  end

  describe "rule setting" do
    describe "#must_match_accents=" do
      it "should set ignore_accents to the opposite of the specified boolean" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_accents => false)
        scoring_ruleset.must_match_accents = false
        expect(scoring_ruleset.ignore_accents?).to be_truthy
      end
    end

    describe "#must_match_punctuation=" do
      it "should set ignore_punctuation to the opposite of the specified boolean" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_punctuation => false)
        scoring_ruleset.must_match_punctuation = false
        expect(scoring_ruleset.ignore_punctuation?).to be_truthy
      end
    end

    describe "#must_match_capitalization=" do
      it "should set ignore_capitalization to the opposite of the specified boolean" do
        scoring_ruleset = build(:scoring_ruleset, :ignore_capitalization => false)
        scoring_ruleset.must_match_capitalization = false
        expect(scoring_ruleset.ignore_capitalization?).to be_truthy
      end
    end
  end

end
