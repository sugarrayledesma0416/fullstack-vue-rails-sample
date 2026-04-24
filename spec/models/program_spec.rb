describe Program do
  context "with valid attributes" do
    before(:each) do
      @program = create(:program,
                        { language_code: 'es',
                          title_part_main: 'The Program',
                          title_part_main_language_code: 'es' })
    end

    it "should expose language code" do
      expect(@program.language_code).to eq('es')
    end

    it "should expose language name" do
      expect(@program.language_name).to eq('Spanish')
    end

    it 'exposes main_title' do
      expect(@program.title_part_main).to eq('The Program')
    end

    it 'exposes language_code_main_title' do
      expect(@program.title_part_main_language_code).to eq('es')
    end
  end

  describe 'column validations' do
    before(:each) do
      @program = create(:program,
                        { language_code: 'es',
                          title_part_main: 'The Program',
                          title_part_main_language_code: 'es' })
    end

    describe 'subtitle and language_code_subtitle columns' do
      context 'when both are not nil' do
        it 'is valid' do
          @program.title_part_sub = 'The Subtitle'
          @program.title_part_sub_language_code = 'en'
          expect(@program).to be_valid
        end
      end

      context 'when subtitle is nil and language_code_subtitle is not nil' do
        it 'is not valid' do
          @program.title_part_sub = nil
          @program.title_part_sub_language_code = 'en'
          expect(@program).not_to be_valid
        end
      end

      context 'when subtitle is not nil and language_code_subtitle is nil' do
        it 'is not valid' do
          @program.title_part_sub = 'The Subtitle'
          @program.title_part_sub_language_code = nil
          expect(@program).not_to be_valid
        end
      end
    end
  end

  describe "program relations with vocab words" do
    context "with valid vocab program group" do
      before do
        @vocab_program_group = VocabProgramGroup.create
        @program = create(:program, :vocab_program_group => @vocab_program_group)

        @vocab_word_1 = create(:vocab_word, vocab_program_group: @vocab_program_group)
        @vocab_word_2 = create(:vocab_word, vocab_program_group: @vocab_program_group)
        @default_word_1 = create(:default_vocab_word, vocab_program_group: @vocab_program_group)
      end

      it "has default vocab words" do
        expect(@program.vocab_program_group.default_vocab_words.count).to eq(1)
      end

      it "has vocab words" do
        expect(@program.vocab_program_group.vocab_words.count).to eq(2)
      end
    end
  end

  describe "after create program" do
    it "save loaded associations" do
      program_group = VocabProgramGroup.new
      program = Program.new(vocab_program_group: program_group)
      program.save
      program.reload
      expect(program.vocab_program_group).to eq(program_group)
    end

    it "does not change the setted program_group" do
      program_group = VocabProgramGroup.create
      program = Program.new(vocab_program_group: program_group)
      program.save
      program.reload
      expect(program.vocab_program_group).to eq(program_group)
    end

    it "has an association with one vocab_program_group" do
      program = Program.create
      expect(program.vocab_program_group).not_to be_nil
    end
  end

  describe "#maestro3?" do
    it "returns true if the maestro_version is 3" do
      @program = create(:program, :maestro_version => 3)
      expect(@program.maestro3?).to be_truthy
    end

    it "returns false if the maestro_version is 2" do
      @program = create(:m2_program)
      expect(@program.maestro3?).to be_falsey
    end

    it "returns false if the maestro_version is not set" do
      @program = create(:program, :maestro_version => nil)
      expect(@program.maestro3?).to be_falsey
    end
  end

  describe "#maestro2?" do
    it "returns true if the maestro_version is 2" do
      @program = create(:m2_program)
      expect(@program.maestro2?).to be_truthy
    end

    it "returns false if the maestro_version is 3" do
      @program = create(:program, :maestro_version => 3)
      expect(@program.maestro2?).to be_falsey
    end

    it "returns false if the maestro_version is not set" do
      @program = create(:program, :maestro_version => nil)
      expect(@program.maestro2?).to be_falsey
    end
  end

  describe "#maestro2_url" do
    it "returns empty string for non-maestro2 programs" do
      program = create(:program)
      expect(program.maestro2_url).to eq('')
    end

    it "raises an error if vhlcentral_subdomain is blank" do
      program = create(:m2_program, :vhlcentral_subdomain => nil)
      expect{program.maestro2_url}.to raise_error(RuntimeError, 'invalid vhlcentral_subdomain')
    end

    it "returns a maestro2 url based on the vhlcentral_subdomain" do
      program = create(:m2_program)
      local_m2_prefix = ''
      local_m2_prefix = LOCAL_M2_URL_PREFIX if defined? LOCAL_M2_URL_PREFIX
      expected_url = "http://#{local_m2_prefix}#{program.vhlcentral_subdomain}.vhlcentral.com/home/?SS=on"
      expect(program.maestro2_url).to eq(expected_url)
    end
  end

  describe "#numeric_edition_title" do
    it "should replace text edition numbers with numeric abbreviations" do
      expect(build(:program, :title => 'Book First Edition').numeric_edition_title).to  eq('Book 1st Edition')
      expect(build(:program, :title => 'Book Second Edition').numeric_edition_title).to eq('Book 2nd Edition')
      expect(build(:program, :title => 'Book Third Edition').numeric_edition_title).to  eq('Book 3rd Edition')
      expect(build(:program, :title => 'Book Fourth Edition').numeric_edition_title).to eq('Book 4th Edition')
      expect(build(:program, :title => 'Book Fifth Edition').numeric_edition_title).to  eq('Book 5th Edition')
    end
  end

  describe '#components' do
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let(:lesson_1) { create(:lesson, unit: unit) }
    let(:lesson_2) { create(:lesson, unit: unit) }

    before do
      create(:activity, component_name: 'component_1', lesson: lesson_1)
      create(:activity, component_name: 'component_1', lesson: lesson_1)
      create(:activity, component_name: 'component_2', lesson: lesson_2)

      # Instructor created activities
      create(
        :activity,
        lesson: lesson_1,
        instructor_revision_id: 1,
        component_name: 'Instructor-Graded activity'
      )
      create(
        :activity,
        lesson: lesson_2,
        instructor_revision_id: 2,
        component_name: 'Instructor-Graded activity'
      )
    end

    it "returns distinct component names for the program's lessons" do
      expect(program.components).to eq(
        ['component_1', 'component_2', 'Instructor-Graded activity']
      )
    end

    context 'when instructor activities do not need to be included,' do
      it 'returns the component names excluding instructor components' do
        include_instructor_content = false
        expect(program.components(include_instructor_content:)).to eq(
          %w[component_1 component_2]
        )
      end
    end
  end

  describe "#activities" do
    let(:program) { create(:program) }
    let(:course) { create(:course, program: program) }
    let(:unit) { create(:unit, program: program) }
    let(:lesson_1) { create(:lesson, unit: unit) }
    let(:lesson_2) { create(:lesson, unit: unit) }
    let(:hidden_activity_1) { create(:activity, lesson: lesson_1) }
    let(:hidden_activity_2) { create(:activity, lesson: lesson_2) }
    let!(:activity_1) { create(:activity, lesson: lesson_1) }
    let!(:activity_2) { create(:activity, lesson: lesson_2) }

    before(:each) do
      CourseLibraryActivity.hide_activity(hidden_activity_1.id, course.id)
      CourseLibraryActivity.hide_activity(hidden_activity_2.id, course.id)
    end

    it "returns activities corresponding to the program's lessons regardless " \
       'of their state on the course library'do
      expect(
        program.activities(sections: course.sections)
      ).to match_array [activity_1, activity_2, hidden_activity_1, hidden_activity_2]
    end
  end

  describe '#activities_with_toc_location' do
    it 'returns activities whose toc_location is not null' do
      program = create(:program)
      unit = create(:unit, rank: 1, program: program)
      lesson_1 = create(:lesson, rank: 1, unit: unit)
      lesson_2 = create(:lesson, rank: 2, unit: unit)

      activity_1 = create(:activity, lesson: lesson_1, toc_location: 100)
      activity_2 = create(:activity, lesson: lesson_2, toc_location: 200)
      activity_3 = create(:activity, lesson: lesson_2, toc_location: nil)
      expect(program.activities_with_toc_location).to eq([activity_1, activity_2])
    end
  end

  describe '#assessments' do
    let(:student) { create(:student) }
    let(:program) { create(:program_with_toc_entries) }
    let(:course) { create(:course, program: program) }
    let(:section) { create(:section, course:, instructor: course.owner) }
    let(:lesson) { program.units.first.lessons.first }
    let(:assessment_strand) { create(:toc_entry, assessment: true) }
    let!(:assessment_1) do
      create(
        :activity,
        toc_location: assessment_strand.location,
        instructor_revision_id: 1,
        instructor_id: course.owner_id
      )
    end
    let!(:assessment_2) do
      create(
        :activity,
        toc_location: assessment_strand.location,
        instructor_revision_id: 1,
        instructor_id: course.owner_id
      )
    end

    before do
      lesson.toc_entries << assessment_strand
      program.save!
      lesson.save!
      program.reload
    end

    it 'returns only the assigned IGCs for the assessment strands if the ' \
       'current_user is a student' do
      create(:assignment, assignable: assessment_1, section:)
      results = program.assessments(sections: course.sections, current_user: student)
      expect(results).not_to be_empty
      expect(results).to eq(
        assessment_strand.descendant_activities(
          sections: course.sections,
          current_user: student
        )
      )
      expect(results).to eq [assessment_1]
    end

    it 'all IGCs for the assessment strand if the current_user is an instructor' do
      create(:assignment, assignable: assessment_1, section:)
      results = program.assessments(sections: course.sections, current_user: course.owner)
      expect(results).not_to be_empty
      expect(results).to eq(
        assessment_strand.descendant_activities(
          sections: course.sections,
          current_user: course.owner
        )
      )
      expect(results).to match_array [assessment_1, assessment_2]
    end
  end

  describe ".units" do
    it "should only return units with use_type equal to 'Unit'" do
      program = create(:program)
      normal_unit = create(:unit, :use_type => 'Unit', :program => program)
      resource_unit = create(:unit, :use_type => 'ResourceUnit', :program => program)
      program.units << normal_unit
      program.units << resource_unit
      program.save!; program.reload

      units = program.units
      expect(units.size).to eq(1)
      expect(units).to include normal_unit
    end
  end

  describe ".units_and_resource_units" do
    it "should only return all units regardless of their use_type" do
      program = create(:program)
      normal_unit = create(:unit, :use_type => 'Unit', :program => program)
      resource_unit = create(:unit, :use_type => 'ResourceUnit', :program => program)
      program.units << normal_unit
      program.units << resource_unit
      program.save!; program.reload

      units = program.units_and_resource_units
      expect(units.size).to eq(2)
      expect(units).to include normal_unit
      expect(units).to include resource_unit
    end
  end

  describe "#has_pronto?" do
    it "returns false if there are no program settings" do
      program = create(:program)
      allow(program).to receive(:program_settings).and_return(nil)
      expect(program.has_pronto?).to be_falsey
    end

    it "returns false when there is no pronto key" do
      program = create(:program)
      allow(program).to receive(:program_settings).and_return(double(ProgramSettings, :has_pronto? => false))
      expect(program.has_pronto?).to be_falsey
    end

    it "returns true when there is a pronto key" do
      program = create(:program)
      allow(program).to receive(:program_settings).and_return(double(ProgramSettings, :has_pronto? => true))
      expect(program.has_pronto?).to be_truthy
    end
  end

  describe "#has_reference_links?" do
    it "should return false if reference links is nil" do
      program = create(:program)
      allow(program).to receive(:reference_links).and_return(nil)
      expect(program.has_reference_links?).to be_falsey
    end

    it "should return false if reference links is empty" do
      program = create(:program)
      allow(program).to receive(:reference_links).and_return([])
      expect(program.has_reference_links?).to be_falsey
    end

    it "should return true if reference links is not empty" do
      program = create(:program)
      allow(program).to receive(:reference_links).and_return(['something'])
      expect(program.has_reference_links?).to be_truthy
    end

  end

  describe "#reference_links" do
    it "should return empty array if program setting is nil" do
      program = create(:program)
      allow(ProgramSettings).to receive(:new).and_return(nil)
      expect(program.reference_links).to be_empty
    end

    it "should return link got from the programs settings " do
      program = create(:program)
      links = [ {:type => 'link'}]
      program_settings = double('program_setting',:links =>links)
      allow(ProgramSettings).to receive(:new).and_return(program_settings)
      expect(program.reference_links).to eq(links)
    end
  end

  describe "#best_display_lesson" do
    let(:program) { build_stubbed(:program) }
    let(:lessons) { [build_stubbed(:lesson, id: 1)] }
    let(:list_of_units) { [build_stubbed(:unit, lessons: lessons)] }

    context "when the the list of units contains the given lesson" do
      it "returns that lesson" do
        @given_lesson_id_param = '1'
        expect(program.best_display_lesson(@given_lesson_id_param, 0, list_of_units)).to eq(lessons.first)
      end
    end

    context "when the list of units does not contain the given lesson" do
      before do
        @given_lesson_id_param = '2'
        @start_unit_lessons = [ build_stubbed(:lesson) ]
        @start_unit = build_stubbed(:unit, :lessons => @start_unit_lessons)
        allow(program).to receive(:best_start_unit).and_return(@start_unit)
      end

      context "when the given start unit has lessons" do
        it "returns the first lesson from the given start unit" do
          expect(program.best_display_lesson(@given_lesson_id_param, 0, list_of_units)).to eq(@start_unit_lessons.first)
        end
      end

      context "when the given start unit does not have lessons" do
        before do
          allow(@start_unit).to receive(:lessons).and_return([])
        end

        it "returns a default lesson of the first lesson from the first unit" do
          expect(program.best_display_lesson(@given_lesson_id_param, 0, list_of_units)).to eq(lessons.first)
        end
      end
    end

    context 'when the program is being accessed with trial access' do
      context 'when there are two units' do
        let(:lesson_1) { build_stubbed(:lesson, id: 1) }
        let(:unit_1) { build_stubbed(:unit, id: 1, lessons: [lesson_1]) }
        let(:lesson_2) { build_stubbed(:lesson, id: 2) }
        let(:unit_2) { build_stubbed(:unit, id: 2, lessons: [lesson_2]) }
        let(:list_of_units) { [unit_1, unit_2] }

        it 'returns the first lesson of the second unit' do
          trial_access = true
          expect(
            program.best_display_lesson(nil, nil, list_of_units, trial_access)
          ).to eq(lesson_2)
        end
      end

      context 'when there are more than two units' do
        let(:lesson_1) { build_stubbed(:lesson, id: 1) }
        let(:unit_1) { build_stubbed(:unit, id: 1, lessons: [lesson_1]) }
        let(:lesson_2) { build_stubbed(:lesson, id: 2) }
        let(:unit_2) { build_stubbed(:unit, id: 2, lessons: [lesson_2]) }
        let(:lesson_3) { build_stubbed(:lesson, id: 3) }
        let(:unit_3) { build_stubbed(:unit, id: 3, lessons: [lesson_3]) }
        let(:list_of_units) { [unit_1, unit_2, unit_3] }

        it 'returns the first lesson of the third unit' do
          trial_access = true
          expect(program.best_display_lesson(nil, nil, list_of_units, trial_access)).to eq(lesson_3)
        end
      end

      context 'when there is one unit' do
        it 'returns the first lesson of the first unit' do
          trial_access = true
          expect(
            program.best_display_lesson(nil, nil, list_of_units, trial_access)
          ).to eq(lessons.first)
        end
      end
    end

    context 'when the program is being accessed without trial access' do
      it 'returns the first lesson of the first unit' do
        trial_access = false

        expect(program.best_display_lesson(nil, nil, list_of_units, trial_access)).to eq(lessons.first)
      end
    end
  end

  context 'current events unit/lesson methods' do
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program) }
    let!(:lesson) { create(:lesson, unit: unit) }
    let!(:current_events_unit) { create(:current_events_unit, program: program) }

    describe '#browsable_units' do
      it "adds current events unit to the program's units" do
        browsable_units = program.browsable_units
        expect(browsable_units.size).to eq 2
        expect(browsable_units).to include current_events_unit
      end

      context 'when a collection is passed in' do
        it 'adds the current events unit to the collection' do
          another_unit = build_stubbed(:unit)
          browsable_units = program.browsable_units([another_unit])
          expect(browsable_units.size).to eq 2
          expect(browsable_units).to include another_unit
          expect(browsable_units).to include current_events_unit
        end
      end
    end

    describe '#browsable_lessons' do
      let(:current_events_lesson) { current_events_unit.lessons.first }

      it "adds current events lesson to the program's lessons" do
        browsable_lessons = program.browsable_lessons
        expect(browsable_lessons.size).to eq 2
        expect(browsable_lessons).to include current_events_lesson
      end

      context 'when a collection is passed in' do
        it 'adds the current events unit to the collection' do
          another_lesson = build_stubbed(:lesson)
          browsable_lessons = program.browsable_lessons([another_lesson])
          expect(browsable_lessons.size).to eq 2
          expect(browsable_lessons).to include another_lesson
          expect(browsable_lessons).to include current_events_lesson
        end
      end
    end
  end

  describe "#best_start_unit" do
    let(:program) { build_stubbed(:program) }
    let(:list_of_units) { [build_stubbed(:unit, :rank => 1)] }

    context "when the list of units contains the given start unit rank" do
      it "returns that unit" do
        @given_start_unit_rank = '1'
        expect(program.best_start_unit(@given_start_unit_rank, list_of_units)).to eq(list_of_units.first)
      end
    end

    context "when the list of units does not contain the given start unit rank" do
      it "returns the first unit in the list" do
        @given_start_unit_rank = '0'
        expect(program.best_start_unit(@given_start_unit_rank, list_of_units)).to eq(list_of_units.first)
      end
    end
  end

  describe "#best_start_unit_rank" do
    let(:program) { build_stubbed(:program) }
    let(:list_of_units) { [build_stubbed(:unit, :rank => 1)] }

    it "returns the rank of the best start unit" do
      allow(program).to receive(:best_start_unit).and_return(list_of_units.first)
      expect(program.best_start_unit_rank(1, list_of_units)).to eq(list_of_units.first.rank)
    end
  end

  describe "#multi_unit_resource_label" do
    it "returns the unit label with a multi prefix" do
      program = create(:program, :unit_label => 'SuperUnit')
      expect(program.multi_unit_resource_label).to eq("Multi-superunit")
    end
  end

  describe '#two-tier?' do
    let(:program) { create(:program) }
    let(:unit) { create(:unit, :program => program) }
    let!(:lesson_1) { create(:lesson, :unit => unit) }

    it 'returns true if the program has more lessons than units' do
      lesson_2 = create(:lesson, :unit => unit)

      expect(program).to be_two_tier
    end

    it 'returns false if the program has the same number of lessons and units' do
      expect(program).not_to be_two_tier
    end
  end

  describe "#visible_units" do
    let(:program) { create(:program) }
    let!(:released_unit) { create(:unit, :program => program, :released => true) }
    let!(:unreleased_unit) { create(:unit, :program => program, :released => false) }

    it "returns only the released units by default" do
      returned_units = program.visible_units
      expect(returned_units).to include released_unit
      expect(returned_units).not_to include unreleased_unit
    end

    it "returns the unreleased and released units if the optional param is true" do
      returned_units = program.visible_units(true)
      expect(returned_units).to include released_unit
      expect(returned_units).to include unreleased_unit
    end

    it "returns the released units if the optional param is false" do
      returned_units = program.visible_units(false)
      expect(returned_units).to include released_unit
      expect(returned_units).not_to include unreleased_unit
    end
  end

  describe "#visible_lessons" do
    let(:program) { create(:program) }
    let!(:released_unit) do
      create(:unit_with_lessons, rank: 2, program: program, released: true)
    end
    let!(:unreleased_unit) do
      create(:unit_with_lessons, rank: 1, program: program, released: false)
    end

    before do
      released_unit.lessons.each do |lesson|
        lesson.concepts << create(:concept_with_calculated_combined_rank, lesson: lesson)
      end

      unreleased_unit.lessons.each do |lesson|
        lesson.concepts << create(:concept_with_calculated_combined_rank, lesson: lesson)
      end

      program.units << released_unit
      program.units << unreleased_unit
    end

    it "returns the lessons from the released units by default" do
      returned_lessons = program.visible_lessons
      released_unit.lessons{ |lesson| expect(returned_lessons).to include lesson }
      unreleased_unit.lessons{ |lesson| expect(returned_lessons).not_to include lesson }
    end

    it "returns the lessons from unreleased and released units if the optional param is true" do
      returned_lessons = program.visible_lessons(true)
      released_unit.lessons{ |lesson| expect(returned_lessons).to include lesson }
      unreleased_unit.lessons{ |lesson| expect(returned_lessons).to include lesson }
    end

    it "returns the lessons from released units if the optional param is true" do
      returned_lessons = program.visible_lessons(false)
      released_unit.lessons{ |lesson| expect(returned_lessons).to include lesson }
      unreleased_unit.lessons{ |lesson| expect(returned_lessons).to include lesson }
    end

    it 'it returns the lessons ordered by unit and lesson rank' do
      first_lessons = released_unit.lessons
      last_lessons = unreleased_unit.lessons

      expect(program.visible_lessons(true)).to eq last_lessons + first_lessons
    end
  end

  describe "#visible_units_and_resource_units" do
    let(:program) { create(:program) }
    let(:released_unit) { create(:unit, :program => program, :released => true, :use_type => 'Resource') }
    let(:unreleased_unit) { create(:unit, :program => program, :released => false, :use_type => 'Resource') }

    before do
      program.units << released_unit
      program.units << unreleased_unit
    end

    it "returns only the released units by default" do
      returned_units = program.visible_units_and_resource_units
      expect(returned_units).to include released_unit
      expect(returned_units).not_to include unreleased_unit
    end

    it "returns the unreleased and released units if the optional param is true" do
      returned_units = program.visible_units_and_resource_units(true)
      expect(returned_units).to include released_unit
      expect(returned_units).to include unreleased_unit
    end

    it "returns the released units if the optional param is false" do
      returned_units = program.visible_units_and_resource_units(false)
      expect(returned_units).to include released_unit
      expect(returned_units).not_to include unreleased_unit
    end
  end

  describe '#vista_online_learning?' do
    it 'returns true if program family is vista_online_learning' do
      program = build(:program, family: 'vista_online_learning')
      expect(program).to be_vista_online_learning
    end

    it 'returns false if program family is not vista_online_learning' do
      program = build(:program)
      expect(program).not_to be_vista_online_learning
    end
  end

  describe '#supersite_junior?' do
    it 'returns true if program family is supersites_jr' do
      program = build(:program, family: 'supersites_jr')
      expect(program).to be_supersite_junior
    end

    it 'returns false if program family is not supersites_jr' do
      program = build(:program)
      expect(program).not_to be_supersite_junior
    end
  end

  describe '#spr?' do
    it 'returns true if program family is spr' do
      program = build(:program, family: 'spr')
      expect(program).to be_spr
    end

    it 'returns false if program family is not spr' do
      program = build(:program)
      expect(program).not_to be_spr
    end
  end

  describe '#audience' do
    it 'returns elementary if program is supersite junior' do
      program = build(:program, family: 'supersites_jr')
      expect(program.audience).to eq(:elementary)
    end

    it 'returns default if program is not supersite junior' do
      program = build(:program)
      expect(program.audience).to eq(:default)
    end
  end

  describe '#supports_standards?' do
    let(:program) { create(:program) }
    let(:standard_set) { create(:standard_set) }

    it 'returns true if the program supports standards' do
      create(
        :program_config_with_standard_sets,
        program:,
        supported_standard_sets: [standard_set]
      )
      expect(program.supports_standards?).to be_truthy
    end

    it 'returns false if the program does not supports standards' do
      create(
        :program_config,
        program:
      )
      expect(program.supports_standards?).to be_falsey
    end
  end
end
