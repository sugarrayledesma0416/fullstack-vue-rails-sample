describe Lesson, core: true do
  describe 'scopes' do
    describe '.by_unit' do
      it 'returns the lessons for the given unit' do
        first_unit = build_stubbed(:unit)
        second_unit = build_stubbed(:unit)
        first_lesson = create(:lesson, :unit => first_unit)
        second_lesson = create(:lesson, :unit => second_unit)
        results = Lesson.by_unit(first_unit)
        expect(results.size).to eq(1)
        expect(results.first).to eq(first_lesson)
      end
    end
  end

  describe '#strands' do
    let(:lesson) do
      create(
        :lesson,
        toc_entries_xml: Nokogiri::XML(
          File.open('spec/fixtures/xml/lesson.xml')
        ).to_xml
      )
    end

    it 'returns a list of the top level toc entry nodes for the lesson' do
      expect(lesson.strands).to eq(lesson.toc_entries)
    end

    context 'when assesment strands exist,' do
      let(:assessment_strand) do
        create(
          :toc_entry,
          title: 'Exams',
          assessment: true
        )
      end

      before do
        lesson.toc_entries << assessment_strand
        lesson.save
      end

      context 'with default param,' do
        it "doesn't include assessment strands" do
          expect(lesson.strands).not_to include assessment_strand
        end
      end

      context 'with optional param equal to true' do
        it 'includes assessment strands' do
          expect(
            lesson.strands(include_assessment = true)
          ).to include assessment_strand
        end
      end
    end
  end

  describe '#ensure_activities_have_correct_lesson_id' do
    let(:lesson) { create(:lesson) }

    it 'assigns correct lesson id for toc entries' do
      strand_location = 1
      sub_strand_location = 2
      sub_sub_strand_location = 3

      activity_1 = create(
        :activity,
        toc_location: strand_location,
        title: 'activity 1',
        lesson_id: lesson.id
      )
      activity_2 = create(
        :activity,
        toc_location: sub_strand_location,
        title: 'activity 2',
        lesson_id: lesson.id
      )
      activity_3 = create(
        :activity,
        toc_location: sub_sub_strand_location,
        title: 'activity 3',
        lesson_id: lesson.id
        )
      lesson.toc_entries_xml = <<~XML
        <lesson>
        <toc_entry title="strand" location="#{strand_location}">
          <toc_entry title="sub_strand" location="#{sub_strand_location}">
            <toc_entry title="sub_sub_strand" location="#{sub_sub_strand_location}"/>
          </toc_entry>
        </toc_entry>
        </lesson>
      XML
      new_id = Lesson.last.id + 1
      lesson.id = new_id
      lesson.save!
      lesson.from_xml
      lesson.ensure_activities_have_correct_lesson_id
      Activity.find([activity_1.id, activity_2.id, activity_3.id]).each do |activity|
        expect(activity.lesson_id).to eq(new_id)
      end
    end
  end

  describe '#ordered_non_assessment_concepts' do
    let(:other_lesson) { create(:lesson) }
    let(:lesson) { create(:lesson) }

    it 'returns only non-assessment concepts in the current lesson' do
      concept = create(:concept, assessment: false, lesson: lesson)
      create(:concept, assessment: true, lesson: lesson)
      create(:concept, assessment: false, lesson: other_lesson)

      expect(lesson.ordered_non_assessment_concepts).to contain_exactly(concept)
    end

    it 'sorts the concepts by rank' do
      concept_2 = create(:concept, assessment: false, lesson: lesson, rank: 2)
      concept_1 = create(:concept, assessment: false, lesson: lesson, rank: 1)

      expect(lesson.ordered_non_assessment_concepts).to eq([concept_1, concept_2])
    end
  end

  describe '#toc_location_rank_by_id' do
    it 'populates all toc_location_ranks, depth first' do
      lesson = create(:lesson_with_toc_entries)

      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[0].location)).to eq(1)
      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[0].children[0].location)).to eq(2)
      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[0].children[1].location)).to eq(3)
      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[0].children[2].location)).to eq(4)
      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[1].location)).to eq(5)
      expect(lesson.toc_location_rank_by_id(lesson.toc_entries[1].children[0].location)).to eq(6)
    end

    it "caches the result of populating the ranks" do
      lesson = create(:lesson_with_toc_entries)
      expect(lesson).to receive(:populate_toc_location_ranks).once.and_return({'5' => 1, '6' => 2})
      lesson.toc_location_rank_by_id('5')
      lesson.toc_location_rank_by_id('6')
    end

    it "returns zero if location is not found" do
      lesson = create(:lesson_with_toc_entries)
      expect(lesson.toc_location_rank_by_id(999999)).to eq(0)
    end
  end

  describe "#strand_for_toc_location" do
    before(:each) do
      @lesson = create(:lesson_with_toc_entries)
    end

    it "should return nil if no toc entry matches specified location" do
      expect(@lesson.strand_for_toc_location('some invalid location')).to be_nil
    end

    it "should return a top level toc entry if it matches specified location" do
      target = @lesson.toc_entries.first
      expect(@lesson.strand_for_toc_location(target.location)).to eq(target)
    end

    it "should return the top level toc entry that contains the toc entry that matches specified location" do
      expected = @lesson.toc_entries.first
      target = expected.children.first
      expect(@lesson.strand_for_toc_location(target.location)).to eq(expected)
    end
  end

  describe "#substrand_for_toc_location" do
    before(:each) do
      @lesson = create(:lesson_with_strands_substrands_and_activities)
    end

    it "should return nil if no toc entry matches specified location" do
      expect(@lesson.substrand_for_toc_location('some invalid location')).to be_nil
    end

    it "should return a substrand level toc entry if it matches specified location" do
      target = @lesson.toc_entries.first.children.first
      expect(@lesson.substrand_for_toc_location(target.location)).to eq(target)
    end
  end

  describe ".find_strand_by_lesson_and_strand_id" do
    before(:each) do
      @lesson = create(:lesson_with_toc_entries)
      @strand = @lesson.toc_entries.first
    end

    it "should raise an error if passed an invalid lesson id" do
      allow(Lesson).to receive(:find_by_id).and_return(nil)
      expect{Lesson.find_strand_by_lesson_and_strand_id(@lesson.id, @strand.location)}
        .to raise_error(RuntimeError, /no lesson found with id \d+/)
    end

    it "should return nil if no strand in the lesson matches the provided strand id" do
      expect(Lesson.find_strand_by_lesson_and_strand_id(@lesson.id, 'invalid_strand_id')).to be_nil
    end

    it "should return the strand in the lesson matching the specified id" do
      strand = Lesson.find_strand_by_lesson_and_strand_id(@lesson.id, @strand.location)

      expect(strand.location).to eq(@strand.location)
      expect(strand.title).to eq(@strand.title)
    end

  end

  describe "#to_xml" do
    it "should include the root node" do
      lesson = build(:lesson_with_strands_and_activities)
      lesson.toc_entries[0].title = "Something lost, something found"
      lesson.to_xml
      expect(lesson.toc_entries_xml).to include("<toc_entry title=\"Something lost, something found\"")
    end

    it "should include child TocEntries " do
      lesson = build(:lesson_with_strands_substrands_and_activities)
      expect(lesson.toc_entries[0].children[0].class).to eq(TocEntry)
      lesson.toc_entries[0].children[0].title = 'child node'
      lesson.toc_entries[0].children[0].short_title = 'child node short title'
      lesson.to_xml
      expect(lesson.toc_entries_xml).to include("<toc_entry title=\"child node\" short_title=\"child node short title\"")
    end

    it "should store the page number" do
      lesson = build(:lesson_with_strands_substrands_and_activities)
      expect(lesson.toc_entries[0].children[0].class).to eq(TocEntry)
      lesson.toc_entries[0].children[0].page = 25
      lesson.to_xml
      expect(lesson.toc_entries_xml).to include("page=\"25\"")
    end

    it "should store the singular location" do
      lesson = build(:lesson_with_strands_substrands_and_activities)
      lesson.toc_entries[0].children[0].singular_label = 'quiz'
      lesson.to_xml
      expect(lesson.toc_entries_xml).to include("singular_label=\"quiz\"")
    end
  end

  describe "#from_xml" do

    it "raises any syntax errors" do
      lesson = Lesson.new
      lesson.toc_entries_xml = '<lesson><toc_entry broken</lesson>'
      expect{lesson.from_xml}.to raise_error(/syntax error/)
    end

    it "raises any errors caused by xml not matching specs" do
      lesson = Lesson.new
      lesson.toc_entries_xml = '<lesson><toc_entry /><invalid_tag /></lesson>'
      expect{lesson.from_xml}.to raise_error(/unhandled invalid_tag tag/)
    end

    it "should handle top-level toc_entries" do
      lesson = Lesson.new
      lesson.toc_entries_xml = '<lesson><toc_entry title="huzzah"/></lesson>'
      lesson.from_xml
      expect(lesson.toc_entries).not_to be_nil
      expect(lesson.toc_entries.length).to eq(1)
      expect(lesson.toc_entries[0].title).to eq("huzzah")
    end

    it "should handle deeper toc_entries" do
      lesson = Lesson.new
      lesson.toc_entries_xml = <<EOT
        <lesson>
          <toc_entry title="anything">
            <toc_entry title="something to search for"/>
          </toc_entry>
        </lesson>
EOT
      lesson.from_xml
      expect(lesson.toc_entries).not_to be_nil
      expect(lesson.toc_entries.length).to eq(1)
      expect(lesson.toc_entries[0].children[0].title).to eq("something to search for")
    end

    it "should include page numbers for each node" do
      lesson = Lesson.new
            lesson.toc_entries_xml = <<EOT
              <lesson>
                <toc_entry title="anything">
                  <toc_entry title="something to search for" page="5"/>
                </toc_entry>
              </lesson>
EOT
      lesson.from_xml
      expect(lesson.toc_entries[0].children[0].page).to eq(5)
    end

    it "should include background colors when they exist" do
      lesson = Lesson.new
            lesson.toc_entries_xml = <<EOT
              <lesson>
                <toc_entry title="anything" background_color="#FFFFFF">
                  <toc_entry title="something to search for" page="5"/>
                </toc_entry>
              </lesson>
EOT
      lesson.from_xml
      expect(lesson.toc_entries[0].background_color).to eq("#FFFFFF")
    end

    it "should include singular_labels when they exist" do
      lesson = Lesson.new
            lesson.toc_entries_xml = <<EOT
              <lesson>
                <toc_entry title="Vocabulary Quizzes" singular_label="quiz">
                  <toc_entry title="something to search for" page="5"/>
                </toc_entry>
              </lesson>
EOT
      lesson.from_xml
      expect(lesson.toc_entries[0].singular_label).to eq('quiz')
    end

  end

  describe "#display_name" do
    it "should return label if valid label exists" do
      lesson = build_stubbed(:lesson, :label => "Label")
      allow(lesson).to receive(:program).and_return(build_stubbed(:program , :maestro_version => 3))
      expect(lesson.display_name).to eq("Label")
    end

    it "should return name if label is nil" do
      lesson = build_stubbed(:lesson, :label => nil)
      allow(lesson).to receive(:program).and_return(build_stubbed(:program , :maestro_version => 2))
      expect(lesson.display_name).to eq("Lesson 1")
    end

    it "should return name if label is blank" do
      lesson = build_stubbed(:lesson, :label => " ")
      allow(lesson).to receive(:program).and_return(build_stubbed(:program , :maestro_version => 2))
      expect(lesson.display_name).to eq("Lesson 1")
    end
  end

  describe "#<=>" do
    it "should compare lessons by rank" do
      @first_lesson = create(:lesson, :rank => 1, :name => 'bbb')
      @second_lesson = create(:lesson, :rank => 2, :name => 'aaa')
      expect(@first_lesson <=> @second_lesson).to eq(-1)

      @also_first_lesson = create(:lesson, :rank => 1, :name => 'ccc')
      expect(@first_lesson <=> @also_first_lesson).to eq(0)
    end
  end

  describe '#combined_rank' do
    it 'return rank when lesson_combined_rank is called' do
      unit = create(:unit, rank: 15)
      lesson = create(:lesson, unit: unit, rank: 10)
      concept = create(:concept)
      lesson.concepts = [concept]
      calculated_rank = unit.rank * 100 + lesson.rank + 1

      #expect(concept).to receive(:lesson_combined_rank).and_return(calculated_rank)
      expect(lesson.combined_rank).to eq calculated_rank
    end
  end

  describe "#activity_list_header" do
    let(:lesson) { build_stubbed(:lesson_with_toc_entries) }

    it "returns an empty string when lesson strands and substrands do not contain any match for the specified toc location" do
      allow(lesson).to receive(:strand_for_toc_location).and_return(nil)
      allow(lesson).to receive(:substrand_for_toc_location).and_return(nil)
      expect(lesson.activity_list_header('some_location')).to eq("")
    end

    it "returns a substrand name when lesson strands contain a substrand match for the specified toc location only" do
      match_substrand = lesson.strands[rand(5)]
      allow(lesson).to receive(:strand_for_toc_location).and_return(nil)
      allow(lesson).to receive(:substrand_for_toc_location).and_return(match_substrand)
      expect(lesson.activity_list_header('some_location')).to eq(" | #{match_substrand.name}")
    end

    context "when lesson strands contain a match for the specified toc location" do
      before do
        @match_strand = lesson.strands[rand(5)]
        allow(lesson).to receive(:strand_for_toc_location).and_return(@match_strand)
      end

      it "returns a strand name" do
        allow(lesson).to receive(:substrand_for_toc_location).and_return(nil)
        expect(lesson.activity_list_header('some_location')).to eq("#{@match_strand.name}")
      end

      it "returns strand and substrand names when lesson strands contain a substrand match for the specified toc location" do
        match_substrand = lesson.strands[rand(5)]
        allow(lesson).to receive(:substrand_for_toc_location).and_return(match_substrand)
        expect(lesson.activity_list_header('some_location')).to eq("#{@match_strand.name} | #{match_substrand.name}")
      end
    end
  end

  context 'update_gradebook' do
    context 'after commit' do
      let(:lesson) { create(:lesson) }

      it 'triggers update_gradebook in after_commit' do
        lesson.name = 'Lesson 13 Fun with Spanish'
        expect(lesson).to receive(:update_gradebook)
        lesson.save
      end

      it 'triggers notify_update when lesson is created' do
        alesson = build(:lesson)
        alesson.name = 'Lesson 13 Fun with Spanish'
        expect(alesson).to receive(:notify_update)
        alesson.save
      end

      it 'triggers notify_deletion for a destroyed lesson' do
        alesson = described_class.new
        alesson.name = 'Lesson 13 Fun with Spanish'
        expect(alesson).to receive(:notify_deletion)
        alesson.save
        alesson.destroy
      end
    end
  end
end
