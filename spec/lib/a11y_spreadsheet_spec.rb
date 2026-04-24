describe A11ySpreadsheet do
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
  let(:concept) { create(:concept, id: strand.location, lesson: lesson) }

  before do
    allow(Activity).to receive(:filepath_from_revision_id).and_return(
      File.join('spec', 'fixtures', 'xml', 'open_ended.xml')
    )
  end

  describe '.file_path' do
    it 'generates a path in the /tmp dir including the program id in the name' do
      expect(described_class.new(program.id, false).file_path).to match(
        %r{^/tmp/.*#{program.id}_.*.xlsx}
      )
    end
  end

  describe '#write' do
    it 'outputs a spreadsheet to the /tmp dir' do
      create(:activity, concept: concept, lesson: lesson)
      spreadsheet = described_class.new(program.id, false)

      spreadsheet.write
      expect(File).to exist(spreadsheet.file_path)
    end
  end

  describe '#data' do
    let(:data) { described_class.new(program.id, false).data }

    it 'reports a Rating of "Accessible" when an activity has no a11y issues' do
      create(:activity, concept: concept, lesson: lesson)
      expect(data.first['Rating']).to eq('Accessible')
    end

    it 'reports a Rating of "Accessible" when an activity has only ' \
       'a11y issues that should be excluded' do
      create(:activity, concept: concept, lesson: lesson)
      non_reportable_keys = described_class::NON_REPORTABLE_ISSUES
      issues = non_reportable_keys.each_with_object({}) do |key, memo|
        memo[key] = 1
      end
      allow_any_instance_of(Activity).to receive(:a11y_issues)
        .and_return(issues)

      expect(data.first['Rating']).to eq('Accessible')
    end

    it 'reports a Rating of "Not Accessible" when an activity has a11y issues' do
      allow(Activity).to receive(:filepath_from_revision_id).and_return(
        File.join('spec', 'fixtures', 'xml', 'cucumber_map.xml')
      )
      create(:activity, concept: concept, lesson: lesson)
      expect(data.first['Rating']).to eq('Not Accessible')
    end

    describe 'string cleanup' do
      let(:concept) { concept_with_name(bad_title) }

      def concept_with_name(name)
        create(:concept, id: strand.location, lesson: lesson, name: name)
      end

      before do
        create(:activity, concept: concept, lesson: lesson, title: bad_title)
      end

      context 'when titles contain combining diacritical marks,' do
        let(:bad_title) { "title e\u0301" }
        let(:good_title) { 'title é' }

        it 'converts the combining marks to precomposed equivalents ' \
           'in the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'converts the combining marks to precomposed equivalents ' \
           'in the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end

      context 'when titles contain html tags,' do
        let(:bad_title) { 'title<tag>' }
        let(:good_title) { 'title' }

        it 'strips the tags from the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'strips the tags from the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end

      context 'when titles contain html entities,' do
        let(:bad_title) { 'title &amp; &gt;' }
        let(:good_title) { 'title & >' }

        it 'strips the html entities from the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'strips the html entities from the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end

      context 'when titles contain arrows,' do
        let(:bad_title) { "\u279e \u2794title\u279e \u2794" }
        let(:good_title) { '-> ->title-> ->' }

        it 'replaces the arrow symbols with "->" in the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'replaces the arrow symbols with "->" in the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end

      context 'when titles contain minus signs,' do
        let(:bad_title) { "\u2212title\u2212" }
        let(:good_title) { '-title-' }

        it 'replaces the minus sign symbols with "-" in the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'replaces the minus sign symbols with "-" in the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end

      context 'when titles contain next line control characters,' do
        let(:bad_title) { "\u0085title\u0085" }
        let(:good_title) { 'title' }

        it 'strips the next line control characters from the concept name' do
          expect(data.first['Strand']).to eq(good_title)
        end

        it 'strips the next line control characters from the activity title' do
          expect(data.first['Title']).to eq(good_title)
        end
      end
    end
  end
end
