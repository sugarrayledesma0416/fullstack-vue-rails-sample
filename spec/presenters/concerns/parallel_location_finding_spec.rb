describe ParallelLocationFinding do
  describe '#parallel_location' do
    let(:program) { build_stubbed(:program) }
    let(:lesson_1) { create(:lesson, :name => 'Lesson 1', :toc_entries_xml => File.read('spec/fixtures/xml/lesson_1.xml')) }
    let(:lesson_2) { create(:lesson, :name => 'Lesson 2', :toc_entries_xml => File.read('spec/fixtures/xml/lesson_2.xml')) }

    before do
      allow(Program).to receive(:find_by_id).and_return(program)
      allow(program).to receive(:lesson_for_toc_location).and_return(lesson_1)
      allow(lesson_1).to receive(:program).and_return(program)
      allow(lesson_2).to receive(:program).and_return(program)
      lesson_1.extend(described_class)
      lesson_2.extend(described_class)
    end

    it "should return nil if toc_entry is nil" do
      expect(lesson_2.parallel_location(nil)).to be_nil
    end

    it "should return a toc location with the same strand name" do
      orig = lesson_1.strands[1]
      dest = lesson_2.parallel_location(orig.location)
      expect(dest).not_to be_nil
      expect(dest.name).to eq(orig.name)
      expect(dest.location).not_to eq(orig.location)
    end

    context "when the destination strand has the same or more substrands" do
      it "should return a toc location with the same sub_strand position" do
        orig = lesson_1.strands[4].children[2]
        allow(orig).to receive(:descendant_activities).and_return([build_stubbed(:activity, :lesson => lesson_1)])
        dest = lesson_2.parallel_location(orig.location)
        expect(dest).not_to be_nil
        expect(dest).to eq(lesson_2.strands[4].children[2])
      end
    end

    context "when the destination has less substrands" do
      it "should return the last sub_strand position within the matching strand" do
        orig = lesson_1.strands[7].children[2]
        allow(orig).to receive(:descendant_activities).and_return([build_stubbed(:activity, :lesson => lesson_1)])
        dest = lesson_2.parallel_location(orig.location)
        expect(dest).not_to be_nil
        expect(dest).to eq(lesson_2.strands[7].children[0])
      end
    end

    it "should return the matching parent toc location (strand) when the destination strand has no substrands" do
      orig = lesson_1.strands[0].children[0]
      allow(orig).to receive(:descendant_activities).and_return([build_stubbed(:activity, :lesson => lesson_1)])
      dest = lesson_2.parallel_location(orig.location)
      expect(dest).not_to be_nil
      expect(dest).to eq(lesson_2.strands[0])
    end

    context "when at the strand level" do
      it "should should return the first strand when there is no match" do
        orig = lesson_1.strands[9]
        dest = lesson_2.parallel_location(orig.location)
        expect(dest).not_to be_nil
        expect(dest.name).to eq(lesson_2.strands[0].name)
      end

      it "returns the proper strand when the short_title is the same on multiple strands" do
        orig = lesson_1.strands[11]
        dest = lesson_1.parallel_location(orig.location)
        expect(dest).not_to be_nil
        expect(dest.title).to eq(lesson_1.strands[11].title)
      end
    end

    context "when at the substrand level" do
      it "should return the first strand when there is no match" do
        orig = lesson_1.strands[9].children[0]
        allow(orig).to receive(:descendant_activities).and_return([build_stubbed(:activity, :lesson => lesson_1)])
        dest = lesson_2.parallel_location(orig.location)
        expect(dest).not_to be_nil
        expect(dest.name).to eq(lesson_2.strands[0].name)
      end
    end
  end

  describe "#parallel_toc_location" do
    let(:lesson) { build_stubbed(:lesson_with_strands_and_activities) }
    let(:toc_entry) { build_stubbed(:toc_entry) }

    before do
      lesson.extend(described_class)
    end

    context "when there is no parallel toc entry for the specified location" do
      it "returns nil" do
        allow(lesson).to receive(:parallel_location).and_return(nil)
        expect(lesson.parallel_toc_location(toc_entry)).to be_nil
      end
    end

    context "when there is a parallel toc entry for the specified location" do
      it "returns the location of the parallel toc entry" do
        allow(lesson).to receive(:parallel_location).and_return(toc_entry)
        location = toc_entry.location
        expect(lesson.parallel_toc_location(location)).to eq(toc_entry.location)
      end
    end
  end

  describe "#most_relevant_strand" do
    let(:lesson) { build_stubbed(:lesson_with_toc_entries) }

    before do
      lesson.extend(described_class)
    end

    context "when neither a start strand or a saved location are specified" do
      it "returns a default value of the first strand in the lesson" do
        expect(lesson.most_relevant_strand(nil, nil)).to eq(lesson.strands.first.children.first)
      end
    end

    context "when a saved location is specified" do
      #TODO: Set data up to avoid stubbing methods on the tested object
      it "returns a strand from the lesson's strands when specified saved location is set to any of the lesson's strands" do
        match_strand = lesson.strands[rand(5)]
        allow(lesson).to receive(:parallel_toc_location).and_return(match_strand.location)
        allow(lesson).to receive(:strand_for_toc_location).and_return(match_strand)
        expect(lesson.most_relevant_strand(nil, 'some_location')).to eq(match_strand)
      end
      context "when specified saved location is not set to any lesson's strands" do
        before do
          allow(lesson).to receive(:parallel_toc_location).and_return(nil)
          allow(lesson).to receive(:strand_for_toc_location).and_return(nil)
        end

        it "returns the first strand in the lesson when lesson's first strand does not have children" do
          allow(lesson.strands.first).to receive(:children).and_return([])
          expect(lesson.most_relevant_strand(nil, 'some_location')).to eq(lesson.strands.first)
        end

        it "returns the first strand's child in the lesson when lesson's first strand has children" do
          expected_strand = lesson.strands.first.children.first
          expect(lesson.most_relevant_strand(nil, 'some_location')).to eq(expected_strand)
        end
      end
    end

    context "when a start strand is specified and there is no saved location" do
      context "when the specified start strand isn't one of the strands of the lesson" do
        it "returns a default value of the first strand in the lesson" do
          expect(lesson.most_relevant_strand("Some strand", nil)).to eq(lesson.strands.first.children.first)
        end
      end

      context "when the specified start strand is one of the strands of the lesson" do
        it "returns the toc entry whose location matches  the specified start strand " do
          random_strand = lesson.strands[rand(5)]
          expect(lesson.most_relevant_strand(random_strand.location, nil)).to eq(random_strand)
        end
      end
    end
  end

  describe '#dropdown' do
    let(:program) { create(:program_with_toc_entries) }
    let(:user) { build_stubbed(:instructor) }
    let(:course_id) { create(:course, program_id: program.id).id }
    let(:section) { create(:section, course_id: course_id) }
    let(:sections) { [:section] }
    let(:media_item) { create(:media_item) }

    let(:presenter_klass) do
      Class.new do
        include Rails.application.routes.url_helpers
        # "Common" means shared between Supersite Junior and non-Supersite Junior
        include TocPresenterCommon
        # "Standard" means "not Supersite Junior"
        include StandardTocPresentation
        include StudentTocPresentation

        attr_accessor :program, :section

        def initialize(user, program, section, base_url)
          self.program = program
          self.current_user = user
          self.section = section
          @base_url = base_url
        end

        def base_url(options = {})
          @base_url
        end

        def current_focus
          options = {
            program.id.to_s => { 'section_id' => section.id }
          }
          @current_focus = Focus.new(current_user, program, options)
        end
      end
    end

    let(:presenter) { presenter_klass.new(user, program, section, 'base url') }

    before do
      allow(presenter).to receive(:trial_access?).and_return(false)
    end
    it 'creates the information needed for the dropdown' do
      expect(presenter.dropdown.units.length).to be(2)
    end

    it 'creates the unit information for the dropdown' do
      expect(presenter.dropdown.units.first).to be_a(
        StandardTocPresentation::UnitForSelector
      )
    end

    it 'creates the lesson information for the dropdown' do
      expect(presenter.dropdown.units.first.lessons.first).to be_a(
        StandardTocPresentation::LessonForSelector
      )
    end

    context 'if there is no lesson range, as in "my content"' do
      it 'sets the label to an empty string' do
        allow(presenter).to receive(:course_units_link).and_return(nil)

        expect(presenter.dropdown.unit_range_label).to eq('')
      end
    end

    context 'if the course covers all units' do
      it 'does not show the toggle lesson/unit range option' do
        # section.stub(:covers_all_program_units?).and_return(true)
        # sections.first.stub(:covers_all_program_units?).and_return(true)
        # @presenter.sections.first.stub(:covers_all_program_units?).and_return(true)
        # current_focus.sections.first.stub(:covers_all_program_units?).and_return(true)

        # TODO: This is stubbing a private method. Need help. The above attempts
        # to stub sections.first.covers_all_program_units? failed
        allow(presenter).to receive(:course_covers_all_program_units?).and_return(true)
        expect(presenter.dropdown.unit_range_toggle_path).to eq(false)
      end
    end

    context 'if the course does not cover all units' do
      it 'shows the toggle lesson/unit range option' do
        expect(presenter.dropdown.unit_range_toggle_path).to eq('base url')
      end
    end
  end
end
