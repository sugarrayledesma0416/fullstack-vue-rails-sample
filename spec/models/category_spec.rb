describe Category, core: true do
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:program) { create(:program) }

  let(:course) do
    create(:course, owner: instructor, program: program, school: school)
  end

  describe 'scopes' do
    describe '.with_assessment_count' do
      let(:category) { create(:category, course: course) }
      let(:assessment_concept) { create(:concept, assessment: true) }
      let(:non_assessment_concept) { create(:concept, assessment: false) }
      let(:activity) { create(:activity, lesson: create(:lesson_with_toc_entries)) }
      let!(:assignment) { create(:assignment, category: category, assignable: activity) }

      context 'when there are assessments related to the category' do
        it 'returns the categories with their number of assessments' do
          activity.update!(concept_id: assessment_concept.id)
          expected_category = described_class.with_assessment_count(course).first
          expect(expected_category).to eq(category)
          expect(expected_category.assessment_count).to eq(1)
        end
      end

      context 'when there are no assessments related to the category' do
        it 'returns the categories with a count of zero assessments' do
          activity.update!(concept_id: non_assessment_concept.id)
          expected_category = described_class.with_assessment_count(course).first
          expect(expected_category).to eq(category)
          expect(expected_category.assessment_count).to eq(0)
        end
      end
    end
    describe '.by_course' do
      let!(:category_1) { create(:category, course: course) }
      let!(:category_2) { create(:category) }
      it 'returns the categories for the course' do
        categories = described_class.by_course(course).to_a
        expect(categories).to include(category_1)
        expect(categories).to_not include(category_2)
      end
    end
  end

  describe 'callbacks' do
    let(:category) { create(:category) }

    describe 'update_gradebook' do
      describe 'after commit' do
        it 'triggers update_gradebook in after_commit' do
          category.name = 'Homework'
          expect(category).to receive(:update_gradebook)
          category.save
        end

        it 'triggers notify_update when category is created' do
          acategory = described_class.new
          acategory.name = 'Online Research'
          acategory.course = create(:course)
          acategory.weighting_percent = 10
          expect(acategory).to receive(:notify_update)
          acategory.save
        end

        it 'triggers notify_deletion for an archived category' do
          acategory = described_class.new
          acategory.name = 'Online Research'
          acategory.course = create(:course)
          acategory.weighting_percent = 10
          acategory.is_archived = true
          expect(acategory).to receive(:notify_deletion)
          acategory.save
        end

        it 'triggers notify_deletion for a destroyed category' do
          acategory = described_class.new
          acategory.name = 'Online Research'
          acategory.course = create(:course)
          acategory.weighting_percent = 10
          acategory.save
          expect(acategory).to receive(:notify_deletion)
          acategory.destroy
        end
      end
    end

    describe 'before_create :set_rank_from_siblings' do
      let(:instructor) { build_stubbed(:instructor) }
      let(:program) { build_stubbed(:program) }
      let(:school) {  build_stubbed(:school) }
      let(:course) do
        create(:course, program: program, school: school, owner: instructor)
      end
      let(:new_category) do
        build(
          :category,
          course: course,
          name: 'Homework',
          weighting_percent: 100
        )
      end

      it 'sets the rank to 1 if the course has no gradebook categories' do
        new_category.save

        expect(new_category.rank).to eq(1)
      end

      it 'sets the rank 1 if the course has only archived categories' do
        create(
          :category,
          course: course,
          is_archived: true,
          name: 'label',
          rank: 1,
          weighting_percent: 100
        )
        new_category.save

        expect(new_category.rank).to eq(1)
      end

      it 'sets the rank to the highest rank + 1 if there are multiple gradebook categories' do
        create(
          :category,
          course: course,
          name: 'label_1',
          rank: 15,
          weighting_percent: 50
        )
        create(
          :category,
          course: course,
          name: 'label_2',
          rank: 3,
          weighting_percent: 50
        )
        new_category.save

        expect(new_category.rank).to eq(16)
      end

      it 'excludes archived categories when finding highest rank' do
        create(
          :category,
          course: course,
          is_archived: true,
          name: 'label_1',
          rank: 15,
          weighting_percent: 50
        )
        create(
          :category,
          course: course,
          name: 'label_2',
          rank: 3,
          weighting_percent: 50
        )
        new_category.save

        expect(new_category.rank).to eq(4)
      end
    end
  end

  it 'raises no error when created with valid attributes' do
    expect do
      described_class.create!(
        course_id: course.id,
        name: 'valid label',
        weighting_percent: 100
      )
    end.not_to raise_error
  end

  it 'requires a non-blank label name' do
    expect(build(:category, name: nil)).not_to be_valid
    expect(build(:category, name: '')).not_to be_valid
  end

  it 'removes whitespace from name fields before saving' do
    category = build(:category, name: "\n\t expected_name \n\t")
    category.save
    category.reload
    expect(category.name).to eq('expected_name')
  end

  it 'allows nil max attempts' do
    expect(build(:category, max_attempts: nil)).to be_valid
  end

  it 'returns default value of 2 if max_attempts is not set' do
    category = build(:category, max_attempts: nil)
    expect(category.max_attempts).to eq(2)
  end

  it 'allows max attempts of -1 (to mean unlimited)' do
    expect(build(:category, max_attempts: -1 )).to be_valid
  end

  it "should require max attempts, if not nil or -1, to be an integer between 1 and 9" do
    expect(build(:category, :max_attempts => 0  )).not_to be_valid
    expect(build(:category, :max_attempts => 10 )).not_to be_valid
    expect(build(:category, :max_attempts => 'a')).not_to be_valid
    expect(build(:category, :max_attempts => 1.5)).not_to be_valid
    expect(build(:category, :max_attempts => 1  )).to be_valid
    expect(build(:category, :max_attempts => 9  )).to be_valid
  end

  it "should require weighting percent to be an integer and give a reasonable error message" do
    category = build(:category, :weighting_percent => 1.5)
    category.valid?
    expect(category.errors).not_to be_empty
    expect(category.errors[:weighting_percent]).not_to eq(['is not a number'])
    expect(category.errors[:weighting_percent]).to eq(['is not a whole number'])
  end

  it "should require weighting percent to be a number between 0 and 100" do
    expect(build(:category, :weighting_percent => -1)).not_to be_valid
    expect(build(:category, :weighting_percent => 101)).not_to be_valid
    expect(build(:category, :weighting_percent => 'a')).not_to be_valid
    expect(build(:category, :weighting_percent => 0)).to be_valid
    expect(build(:category, :weighting_percent => 1.0)).to be_valid
    expect(build(:category, :weighting_percent => 1  )).to be_valid
    expect(build(:category, :weighting_percent => 100)).to be_valid
  end

  it "should require penalty percent to be an integer and give a reasonable error message" do
    category = build(:category, :penalty_percent => 1.5)
    category.valid?
    expect(category.errors).not_to be_empty
    expect(category.errors[:penalty_percent]).not_to eq(['is not a number'])
    expect(category.errors[:penalty_percent]).to eq(['is not a whole number'])
  end

  it "should require penalty percent to be a number between 0 and 100" do
    expect(build(:category, :penalty_percent => -1  )).not_to be_valid
    expect(build(:category, :penalty_percent => 101 )).not_to be_valid
    expect(build(:category, :penalty_percent => 'a')).not_to be_valid
    expect(build(:category, :penalty_percent => 1.0 )).to be_valid
    expect(build(:category, :penalty_percent => 1  )).to be_valid
    expect(build(:category, :penalty_percent => 100  )).to be_valid
  end

  it "should set the penalty percent to zero if the late_work_penalty is none" do
    category = create(:category, :late_work_penalty => 'none')
    expect(category.penalty_percent).to eq(0)
  end

  it "requires that drop_low_scores be a non-blank value between 0 and 5" do
    expect(build(:category, :drop_low_scores => nil)).not_to be_valid
    expect(build(:category, :drop_low_scores => -1)).not_to be_valid
    expect(build(:category, :drop_low_scores => 6)).not_to be_valid
    expect(build(:category, :drop_low_scores => 0)).to be_valid
    expect(build(:category, :drop_low_scores => 5)).to be_valid
  end

  describe '#assignments' do
    let(:category) { create(:category) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }
    let!(:assignment_1) do
      create(:assignment, section: section_1, category: category)
    end
    let!(:assignment_2) do
      create(:assignment, section: section_2, category: category)
    end

    it 'returns assignments for the category' do
      expect(category.assignments).to eq([assignment_1, assignment_2])
    end

    it 'returns assignments only from active sections' do
      section_2.update!(is_archived: true)
      expect(category.assignments).to eq([assignment_1])
    end
  end

  context "#destroyable?" do
    let(:category) { create(:category) }

    it 'adds error to base when the category has assignments' do
      allow(category).to receive(:assignments).and_return(['assignment'])
      expect(category).not_to be_destroyable
    end

    it "doesn't add error to base when the category has no assignments" do
      allow(category).to receive(:assignments).and_return([])
      expect(category).to be_destroyable
    end
  end

  context 'when saving a newly created category,' do
    context 'when setting the category name' do
      it 'does not allow to categories with the same name for the same course' do
        course = create(:course)
        first_category = build(:category, name: 'Homework', course: course)
        first_category.save!
        course.categories.reload
        same_name_category = build(:category, name: 'Homework', course: course)
        expect do
          same_name_category.save!
        end.to raise_error(ActiveRecord::RecordInvalid, /Validation failed/)
        expect(same_name_category.errors[:name]).to eq(
          [
            "cannot be 'Homework' because this course already has a " \
            'category with that name. Please choose a different name.'
          ]
        )
      end

      it "allows to do change on the same category without raising error of type same name category" do
        course = create(:course)
        category = create(:category, name: 'Homework', course: course)
        expect{ category.save! }.not_to raise_error
      end

      it "raises an error when editing a category sets the same name of another category" do
        course = create(:course)
        first_category = build(:category, name: 'Homework', course: course)
        first_category.save!
        course.categories.reload
        another_category = build(:category, name: 'Practice', course: course)
        expect do
          another_category.save!
        end.not_to raise_error
        course.categories.reload
        another_category.name = 'Homework'
        expect do
          another_category.save!
        end.to raise_error(ActiveRecord::RecordInvalid, /Validation failed/)
        expect(another_category.errors[:name]).to eq(
          [
            "cannot be 'Homework' because this course already has a " \
            'category with that name. Please choose a different name.'
          ]
        )
      end
    end
  end

  context "when updating an existing category," do
    let(:category) { create(:category) }

    before do
      @original_ruleset = ScoringRuleset.where(category_id: category.id).first
      @original_ruleset.update!(:ignore_accents => false)
    end

    context "when saving after rules have been changed," do
      it "does not change the values of the old ruleset" do
        old_ruleset_id = @original_ruleset.id

        category.current_scoring_ruleset.ignore_accents = true

        category.save!
        category.reload

        old_ruleset = ScoringRuleset.find(old_ruleset_id)
        expect(old_ruleset.ignore_accents?).to be_falsey
      end
    end

    context "when saving when rules have not been changed," do
      it "keeps the same current scoring ruleset if rules have not changed when saved" do
        old_ruleset_id = @original_ruleset.id
        expect(ScoringRuleset.where(category_id: category.id).size).to eq(1)
        category.current_scoring_ruleset.ignore_accents = false
        category.save!
        category.reload
        expect(ScoringRuleset.where(category_id: category.id).size).to eq(1)
        expect(category.current_scoring_ruleset_id).to eq(old_ruleset_id)
      end
    end
  end

  context 'when no rank is specified,' do
    context 'when the specified course already has categories,' do
      it 'sets rank to the next highest rank for the course' do
        create(
          :category,
          course: course,
          name: 'label_1',
          rank: 15,
          weighting_percent: 25
        )
        create(
          :category,
          course: course,
          name: 'label_2',
          rank: 3,
          weighting_percent: 25
        )
        course.categories.reload

        category = described_class.create!(
          course_id: course.id, name: 'label', weighting_percent: 50
        )

        expect(category.reload.rank).to eq(16)
      end
    end

    context 'when the current course has no categories,' do
      it 'sets a rank of 1' do
        new_course_category = create(:category, name: 'label', course: course)
        expect(new_course_category.reload.rank).to eq(1)
      end
    end
  end

  context 'when a rank is specified,' do
    context 'when the specified course already has categories,' do
      it "sets the rank as specified" do
        described_class.create!(
          course: course,
          name: 'label_1',
          weighting_percent: 25
        )
        described_class.create!(
          course: course,
          name: 'label_2',
          rank: 3,
          weighting_percent: 25
        )
        course.categories.reload
        category = create(
          :category,
          course: course,
          name: 'label',
          rank: 7,
          weighting_percent: 50
        )

        expect(category.reload.rank).to eq(7)
      end
    end

    context 'when the current course has no categories,' do
      it 'sets the rank as specified ' do
        new_course_category = create(
          :category,
          name: 'label',
          rank: 5,
          course: course
        )
        expect(new_course_category.reload.rank).to eq(5)
      end
    end
  end

  describe "#enhanced_feedback_enabled" do
    context "when enhanced feedback is disabled" do
      it "is false" do
        category = build_stubbed(:category, :enhanced_feedback_disabled => true)
        expect(category.enhanced_feedback_enabled).to be_falsey
      end
    end

    context "when enhanced feedback is enabled" do
      it "is true" do
        category = build_stubbed(:category, :enhanced_feedback_disabled => false)
        expect(category.enhanced_feedback_enabled).to be_truthy
      end
    end
  end

  describe "#enhanced_feedback_enabled=(value)" do
    context "when value is '1'" do
      it "sets enhanced_feedback_disabled to false" do
        category = build_stubbed(:category)
        category.enhanced_feedback_enabled = '1'
        expect(category.enhanced_feedback_disabled).to be_falsey
      end
    end

    context "when value is '0'" do
      it "sets enhanced_feedback_disabled to true" do
        category = build_stubbed(:category)
        category.enhanced_feedback_enabled = '0'
        expect(category.enhanced_feedback_disabled).to be_truthy
      end
    end
  end

  describe ".find" do
    it "should not return archived records" do
      archived_record = create(:category, :is_archived => true)
      expect(described_class.all).not_to include(archived_record)
    end
  end

  describe "#late_penalty_percent" do
    context "when the category penalty type is percent_per_day" do
      it "should calculate penalty percentage based on category penalty amount" do
        category = create(:category, :accept_late_work => true,
                                      :late_work_penalty => 'percent_per_day',
                                      :penalty_percent => 3)
        expect(category.late_penalty_percent(3)).to eq(9)
      end

      it "should not return a penalty > 100" do
        category = create(:category, :accept_late_work => true,
                                      :late_work_penalty => 'percent_per_day',
                                      :penalty_percent => 5)
        expect(category.late_penalty_percent(25)).to eq(100)
      end
    end

    context "when the category penalty type is flat_percent" do
      it "should calculate penalty percentage based on category penalty amount" do
        category = create(:category, :accept_late_work => true,
                                      :late_work_penalty => 'flat_percent',
                                      :penalty_percent => 10)
        expect(category.late_penalty_percent(3)).to eq(10)
      end
    end

    context "when the category penalty type is none" do
      it "should return zero" do
        category = create(:category, :accept_late_work => true,
                                      :late_work_penalty => 'none',
                                      :penalty_percent => 10)
        expect(category.late_penalty_percent(3)).to eq(0)
      end
    end

    it "should return 100 if accept_late_work is false" do
      category = create(:category, :accept_late_work => false)
      expect(category.late_penalty_percent(1)).to eq(100)
    end

  end

  describe "#unlimited_attempts?" do
    it "returns true if max attempts equals -1" do
      category = create(:category, :max_attempts => -1)
      expect(category.unlimited_attempts?).to eq(true)
    end

    it "returns false if max attempts does not equal -1" do
      category = create(:category, :max_attempts => 2)
      expect(category.unlimited_attempts?).to eq(false)
    end
  end

  describe "#has_assignments?" do
    before do
      @category = create(:category)
    end

    it "returns true if any assignments exist" do
      create(:assignment, :category => @category)
      expect(@category.has_assignments?).to be_truthy
    end

    it "returns false if no assignment exist" do
      expect(@category.assignments).to be_empty
      expect(@category.has_assignments?).to be_falsey
    end

  end

  describe "#has_assessment_assignments?" do
    let(:category) { create(:category) }
    let(:activity) { create(:activity) }

    it 'returns true if it has assignments and one of them is for an assessment' do
      activity.concept.update!(assessment: true)
      assignment = create(:assignment, :category => category, :assignable => activity)
      allow(category).to receive(:assignments) { [assignment] }
      expect(category.has_assessment_assignments?).to be_truthy
    end

    it 'returns false if it has assignments but none of them is for an assessment' do
      activity.concept.update!(assessment: false)
      assignment = create(:assignment, :category => category, :assignable => activity)
      allow(category).to receive(:assignments) { [assignment] }
      expect(category.has_assessment_assignments?).to be_falsey
    end

    it 'returns false if it has no assignments' do
      expect(category.has_assessment_assignments?).to be_falsey
    end

  end

  describe ".sorted_indices" do
    before(:each) do
      @category1 = build_stubbed(:category, rank: 1)
      @category1.index = '1'
      @category2 = build_stubbed(:category, rank: 2)
      @category2.index = '2'
      @category3 = build_stubbed(:category, rank: 3)
      @category3.index = '3'
      @category4 = build_stubbed(:category, rank: 4)
      @category4.index = '4'
    end

    it 'returns an empty array when no categories are passed' do
      expect(described_class.sorted_indices({})).to eq([])
    end

    it "should assign each category a zero-based index if it does not have one" do
      new_category = build_stubbed(:category, rank: 1)
      expect(described_class.sorted_indices([new_category, @category2])).to eq(['0', '2'])
    end

    it "should return category indices in order based on rank" do
      @category1.rank = 2
      @category2.rank = 1
      expect(described_class.sorted_indices([@category1, @category2])).to eq(['2', '1'])
    end

    context "when a category to be moved is specified by index," do
      it "should force that category into the position specified by its rank even if there is a tie" do
        @category2.rank = 2
        @category3.rank = 2
        categories = [@category1, @category2, @category3]
        expect(described_class.sorted_indices(categories, @category3.index)).to eq(['1', '3', '2'])
      end

      context "when the category's rank is outside of the range of positions," do
        it "should place the specified category at the end" do
          @category2.rank = 99
          categories = [@category1, @category2, @category3]
          expect(described_class.sorted_indices(categories, @category2.index)).to eq(['1', '3', '2'])
        end
      end
    end
  end

  describe "#to_hash" do
    it "should return a hash of the attributes" do
      category = create(:category)
      expect(category.to_hash).to be_a Hash
      expect(category.to_hash['name']).to eq(category.name)
      expect(category.to_hash['weighting_percent']).to eq(category.weighting_percent.to_s)
      expect(category.to_hash['rank']).to eq(category.rank.to_s)
    end
  end
end
