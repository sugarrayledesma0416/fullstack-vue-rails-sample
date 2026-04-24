describe ProgramHelper do
  include ProgramHelper

  describe "#format_toc_entry_title" do
    it "should return a div with the toc entry title" do
      expected_title = 'abcdef'
      toc_entry = build_stubbed(:toc_entry, :title => expected_title)
      results = format_toc_entry_title(toc_entry)
      expect(results).to have_selector('div.toc_entry_title', text: expected_title)
    end

    context "when a toc entry has a background color," do
      it "should include a style with the background color" do
        toc_entry = build_stubbed(:toc_entry, :background_color => '#FFFFCC' )
        results = format_toc_entry_title(toc_entry)
        expect(results).to have_selector('div[class="toc_entry_title"][style="background-color: #FFFFCC; color: white;"]')
      end
    end
  end

  describe "#total_question_count" do
    it "returns the number of questions for the activity" do
      content_summary = {:multiple_choice => 1, :open_ended => 4}
      expect(total_question_count(content_summary)).to eql 5
    end
  end

  describe '#format_prev_unit_link' do
    let(:program) { build_stubbed(:program) }
    let(:user) { build_stubbed(:user) }
    let(:presenter) { InstructorTocPresenter.new(program, user, nil, { :start_unit => 1 }, {}) }

    it 'returns the previous link' do
      allow(presenter).to receive(:start_unit).and_return(1)

      results = format_prev_unit_link(1, presenter)
      expect(results)
        .to have_selector("a[class=prev][href=\"/instructor/contents/#{program.id}?start_unit=0\"][id=carousel_previous]")
      expect(results).to have_selector('span', text: 'Previous')
    end
  end

  describe "#assign_strand_html_options" do
    context "when the strand is a parent of cute little substrands" do
      it "returns a hash with parent class and corresponding background color" do
        is_parent = true
        toc_entry = build_stubbed(:toc_entry)
        allow(toc_entry).to receive(:background_color).and_return('yellow')
        expect(assign_strand_html_options(toc_entry, is_parent)[:class]).to match('test-strand')
        expect(assign_strand_html_options(toc_entry, is_parent)[:class]).to match('parent')
        expect(assign_strand_html_options(toc_entry, is_parent)[:style]).to match(toc_entry.background_color)
      end
    end
    context "when the strand is not a parent" do
      it "returns a hash with strand_track class" do
        is_parent = false
        toc_entry = build_stubbed(:toc_entry)
        expect(assign_strand_html_options(toc_entry, is_parent)[:class]).to match('test-strand')
      end
    end
  end

  describe "#assign_first_child_with_location" do
    it "returns the first child toc entry that has a location" do
      toc_entry = build_stubbed(:toc_entry)
      child_toc_entry = build_stubbed(:toc_entry)
      allow(toc_entry).to receive(:children).and_return([child_toc_entry])
      expect(assign_first_child_with_location(toc_entry)).to eql child_toc_entry
    end

  end

  describe "#choose_first_child_with_activities" do
    let(:user) { build_stubbed(:user) }

    context "when a toc entry has activities" do
      it "returns the location of that toc entry" do
        parent_toc_entry = double(TocEntry, :activities_list => ['activity'], :location => 1)
        child_toc_entry = double(TocEntry, :location => 2)
        choose_first_child_with_activities(parent_toc_entry, child_toc_entry, nil, user)
      end
    end
    context "when a toc entry does not have activities" do
        it "returns the location of the first child toc entry" do
          parent_toc_entry = double(TocEntry, :activities_list => [], :location => 1)
          child_toc_entry = double(TocEntry, :location => 2)
          choose_first_child_with_activities(parent_toc_entry, child_toc_entry, nil, user)
        end
      end
  end

  describe '#format_next_unit_link' do
    let(:program) { build_stubbed(:program) }
    let(:user) { build_stubbed(:user) }
    let(:presenter) { InstructorTocPresenter.new(program, user, nil, { :start_unit => 1 }, {}) }

    it 'returns the next link' do
      allow(presenter).to receive(:start_unit).and_return(1)

      results = format_next_unit_link(1, presenter)
      expect(results)
        .to have_selector("a[class=next][href=\"/instructor/contents/#{program.id}?start_unit=2\"][id=carousel_next]")
      expect(results).to have_selector('span', text: 'Next')
    end
  end

  describe '#two_line_unit_name' do
    let(:unit)  { build_stubbed(:unit) }
    it 'returns the unit name when there is no dash' do
      name = 'Lesson 1'
      allow(unit).to receive(:name).and_return(name)
      expect(two_line_unit_name(unit)).to eq(name)
    end

    it 'returns the unit name split into spans when there is a dash surrounded by spaces' do
      name = 'One - Two'
      allow(unit).to receive(:name).and_return(name)
      expect(two_line_unit_name(unit)).to eq('<span class="unit_number">One</span><br /><span class="unit_title">Two</span>')
    end
  end

  describe '#two_part_unit_name' do
    let(:unit)  { build_stubbed(:unit) }
    it 'returns the unit name when there is no dash' do
      name = 'Lesson 1'
      allow(unit).to receive(:name).and_return(name)
      expect(two_part_unit_name(unit)).to eq(name)
    end

    it 'returns the unit name split into spans when there is a dash surrounded by spaces' do
      name = 'One - Two'
      allow(unit).to receive(:name).and_return(name)

      results = two_part_unit_name(unit)
      expect(results).to have_selector('span[class=unit_number]', text: 'One')
      expect(results).to have_selector('span[class=unit_title]', text: 'Two')
    end
  end

  describe '#unit_carousel_member_for' do
    context 'without a block' do
      context 'when the current_rank is in the unit rank bound (+-2)' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 2, [3]))
            .to have_selector('div[class=item][id=unit_rank_1][style="display: block;"]')
        end
      end

      context 'when the current rank is outside the unit rank found (+- >2)' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 4, [3]))
            .to have_selector('div[class=item][id=unit_rank_1][style="display: none;"]')
        end
      end

      context 'when the visible unit ranks include the unit rank' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 2, [1]))
            .to have_selector('div[class="item course_units_link"][id=unit_rank_1][style="display: block;"]')
        end
      end

      context 'when the visible unit ranks do not include the unit rank' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 2, [2]))
            .to have_selector('div[class=item][id=unit_rank_1][style="display: block;"]')
        end
      end

      context 'when the current rank equals the unit rank' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 1, [2]))
            .to have_selector('div[class="item current_unit"][id=unit_rank_1][style="display: block;"]')
        end
      end

      context 'when the current rank does not equal the unit rank' do
        it 'returns the correct div' do
          expect(unit_carousel_member_for(1, 2, [2]))
            .to have_selector('div[class=item][id=unit_rank_1][style="display: block;"]')
        end
      end
    end

    context 'when given a block' do
      it 'returns the correct div wrapping the contents' do
        content_to_test = unit_carousel_member_for(1, 2, [3]) { 'banana' }
        expect(content_to_test)
          .to have_selector('div[class=item][id=unit_rank_1][style="display: block;"]',
                             text: 'banana')
      end
    end
  end

  describe "#format_selectable_reference_links" do
    let(:program) { build_stubbed(:program) }

    it "returns array with blank" do
      allow(program).to receive(:reference_links).and_return([])
      expect(format_selectable_reference_links(program)).to eq ["Select reference tools."]
    end

    it "returns array with blank as the first element" do
      ref_link = OpenStruct.new(label: 'label', link: 'link')
      allow(program).to receive(:reference_links).and_return([ref_link])
      expect(format_selectable_reference_links(program)).to eq ["Select reference tools.",[ref_link.label,ref_link.link]]
    end

    it "returns a modified array when program has vocab tools" do
      lesson = double(Lesson, id: 123, unit_id: 456)
      allow(Lesson).to receive(:find).and_return(lesson)

      ref_link = OpenStruct.new(label: 'Vocabulary Tools', link: "/#{program.id}/vocab_tools/units")
      allow(program).to receive(:reference_links).and_return([ref_link])

      allow(program).to receive(:has_vocab_tools?).and_return(true)
      expected_links = [
        'Select reference tools.',
        [
          'Vocabulary Tools',
          "/#{program.id}/sections/0/vocab_tools/words?unit_id=#{lesson.unit_id}"
        ]
      ]

      allow(helper).to receive(:current_section).and_return(Section.section_zero)
      expect(helper.format_selectable_reference_links(program, lesson.id)).to eq expected_links
    end
  end

  describe "#add_vocab_tools_words_link" do
    let(:program) { double(Program, id: 79) }
    let(:lesson) { double(Lesson, id: 123, unit_id: 456) }

    it "returns an array modified with the vocab words link" do
      links_array = [
        '',
        ['Dictionary', 'http://www.wordreference.com/enes/'],
        ['Vocabulary Tools', "/#{program.id}/vocab_tools/units"]
      ]
      allow(Lesson).to receive(:find).with(lesson.id).and_return(lesson)
      allow(helper).to receive(:current_section).and_return(Section.section_zero)

      results = helper.add_vocab_tools_words_link(program, lesson.id, links_array)

      expect(results[2][1]).to eq(
        vocab_tools_words_path(program.id, Section.section_zero, unit_id: lesson.unit_id)
      )
    end
  end
end
