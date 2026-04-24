#encoding: utf-8

describe VtextDataGenerator do
  let!(:activity) do
    create(:activity,
           cms_activity_id: 1,
           toc_location: lesson.toc_entries.first.location,
           icon: 'textbook',
           has_vhl_image: true,
           lesson: lesson, assignment_group: 'Practice'
          )
  end
  let(:data_generator) { VtextDataGenerator.new(program.id) }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:lesson) { create(:lesson_with_strands_and_activities, unit: unit) }
  let(:concept) do
    create(:concept,
           activities: [activity],
           name: lesson.toc_entries.detect{ |toc_entry| toc_entry.location == activity.toc_location.to_s }.title
          )
  end
  LICENSE_GROUP = { 1 => '01-Supersite',
                    2 => '02-Supersite_Plus',
                    3 => 'WebSAM',
                    4 => '00-Media_Only',
                    21 => 'VOL',
                    23 => 'Premium' }.freeze

  describe '#generate' do
    let(:expected_headers) do
      bom = "\uFEFF"

      ["#{bom}unit_lesson",
       'strand_name',
       'content_category',
       'activity_type',
       'mouse_icon',
       'lesson_rank',
       'strand_rank',
       'activity_rank',
       'rank',
       'activity_title',
       'activity_source_code',
       'cms_activity_id',
       'license_group',
       'm3_link',
       'audio',
       'image',
       'video',
       'assignment_group']
    end

    let(:expected_data) do
      [lesson.name,
       concept.name,
       activity.component_name,
       activity.activity_type,
       (activity.icon.include? 'textbook').to_s,
       lesson.rank.to_s,
       activity.toc_location_rank.to_s,
       activity.concept_rank.to_s,
       activity.concept_rank.to_s,
       activity.title,
       activity.id.to_s,
       activity.cms_activity_id.to_s,
       LICENSE_GROUP[activity.license_group_id],
       "m3a.vhlcentral.com/sections/0/activities/#{activity.id}",
       (activity.icon.include? 'audio').to_s,
       activity.has_vhl_image.to_s,
       (activity.icon.include? 'video').to_s,
       activity.assignment_group]
    end

    it 'create a vtext data generator' do
      expect(VtextDataGenerator).to receive(:new).with(program.id)
      data_generator
    end

    it 'generate a data in a CVS format' do
      csv = data_generator.generate
      csv_data = CSV.parse(csv)
      expected = [expected_headers] + [expected_data]
      expect(csv_data).to eq(expected)
    end

    it 'replaces <br> tags in strand_name with "|"' do
      location = activity.strand.location
      # Set a strand_name with </br>
      allow(data_generator).to receive(:strand_lookup).and_return(
        {
          location => TocEntry.new.tap { |entry| entry.title = 'Strukturen 2A <br/> Regular verbs' }
        }
      )

      csv = data_generator.generate
      csv_data = CSV.parse(csv)
      transformed_strand_name = csv_data[1][1]
      expect(transformed_strand_name).to eq 'Strukturen 2A | Regular verbs'
    end

    it "when 'audio' exists in icon attribute" do
      activity.update!(icon: 'audio')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['audio']).to eq('true')
    end

    it "when 'audio' does not exist in icon attribute" do
      activity.update!(icon: '')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['audio']).to eq('false')
    end

    it "returns true when at least one 'image' exists in media items activity" do
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['image']).to eq('true')
    end

    it "returns false when there is no 'image' in media items activity" do
      activity.update!(has_vhl_image: false)
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['image']).to eq('false')
    end

    it 'when textbook exists in icon attribute' do
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['mouse_icon']).to eq('true')
    end

    it 'when textbook does not exist in icon attribute' do
      activity.update!(icon: '')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['mouse_icon']).to eq('false')
    end

    it 'does not include activities that have a broken strand caused by a publishing bug' do
      activity.update!(lesson: create(:lesson_with_strands_and_activities, unit: unit))
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data).to be_empty
    end

    it 'includes Unlisted activities' do
      activity.update!(toc_location: nil, component_name: 'Unlisted')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['content_category']).to eq 'Unlisted'
    end

    it 'removes the line breaks from the activity title' do
      activity.update!(title: "\nThis is the \nexpected title\n")
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['activity_title']).to eq 'This is the expected title'
    end

    it "when 'video' exists in icon attribute" do
      activity.update!(icon: 'video')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['video']).to eq('true')
    end

    it "when 'video' does not exist in icon attribute" do
      activity.update!(icon: '')
      activity.reload
      csv_data = CSV.parse(data_generator.generate, headers: true)
      expect(csv_data[0]['video']).to eq('false')
    end

    it 'ensures strands are ordered consistently within the same unit and lesson' do
      program = create(:program)
      unit = create(:unit, program:)
      lesson = create(:lesson_with_strands_and_activities, unit:)
      lesson_2 = create(:lesson_with_strands_and_activities, unit:)

      strand_1 = lesson.toc_entries[0]
      strand_2 = lesson.toc_entries[1]
      strand_3 = lesson_2.toc_entries[0]
      strand_4 = lesson_2.toc_entries[1]

      create(:activity, cms_activity_id: 101, toc_location: strand_2.location, icon: 'textbook', lesson:)
      create(:activity, cms_activity_id: 102, toc_location: strand_1.location, icon: 'textbook', lesson:)
      create(:activity, cms_activity_id: 103, toc_location: strand_4.location, icon: 'textbook', lesson: lesson_2)
      create(:activity, cms_activity_id: 104, toc_location: strand_3.location, icon: 'textbook', lesson: lesson_2)

      generator = described_class.new(program.id)
      csv_data = CSV.parse(generator.generate, headers: true)

      activity_rows = csv_data.select { |row| row['cms_activity_id'].present? }
      strand_order_in_csv = activity_rows.pluck('strand_name')
      strand_order_in_program = program.lessons.flat_map(&:toc_entries).map(&:title)

      expect(strand_order_in_csv).to eq(strand_order_in_program)
      expect(strand_order_in_csv).to eq(
        [strand_1.title, strand_2.title, strand_3.title, strand_4.title]
      )
      expect(strand_order_in_csv.uniq.size).to eq(strand_order_in_csv.size)
    end
  end

  describe '#file_name' do
    it 'return a file name' do
      expect(data_generator.file_name). to eq("#{program.prefix_abbreviation}_maestro3_vtext.csv")
    end
  end

  describe '#generate_information' do
    it 'genere activities items' do
      data_generator.generate_information.each do |act|
        expect(act.cms_activity_id).to eq activity.cms_activity_id
        expect(act.m3_link).to eq "m3a.vhlcentral.com/sections/0/activities/#{activity.id}"
        expect(act.strand_name).to eq activity.toc_location
        expect(act.content_category).to eq activity.component_name
        expect(act.activity_title).to eq activity.title
        expect(act.activity_type).to eq activity.activity_type
        expect(act.rank).to eq activity.concept_rank
        expect(act.license_group_id).to eq activity.license_group_id
        expect(act.unit_lesson).to eq lesson.name
      end
    end
  end
end
