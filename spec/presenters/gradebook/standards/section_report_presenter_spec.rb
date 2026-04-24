describe Gradebook::Standards::SectionReportPresenter do
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, unit:) }
  let(:activity) { create(:activity) }
  let(:activity_2) { create(:activity) }
  let(:section) { create(:section) }

  let(:standard) do
    Standard.create(
      vendor_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
      vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      name: 'English Language Arts/Literacy',
      description: 'Demonstrate command of the conventions of standard English ' \
                   'grammar and usage when writing or speaking.',
      label: 'Grade Level Standard',
      number: 'CCSS.ELA-Literacy.L.7.1'
    )
  end

  let!(:standard_set_1) do
    StandardSet.create(
      vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2010,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: 'CCSS'
    )
  end

  let(:standard_set_2) do
    StandardSet.create(
      vendor_guid: 'AAAAAAAA-BBBB-CCCC-DDDD-123456789ABC',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2023,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: 'CCSS'
    )
  end

  let(:standard_set_3) do
    StandardSet.create(
      vendor_guid: 'EEEEEEEE-FFFF-0000-1111-123456789ABC',
      issuer: 'NGA Center/CCSSO',
      name: 'Fallback Name',
      adopt_year: 2023,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards',
      display_name: nil
    )
  end

  let(:presenter_opts) do
    {
      assessment_ids: [activity.id, activity_2.id],
      standard_set_display_name: standard_set_1.display_name,
      standard_id: standard.id,
      lesson_id: lesson.id
    }
  end

  describe '#standards_data' do
    before do
      allow(StandardsReports::SectionReportCollection).to receive(:new).and_call_original
      allow(StandardsReports::StudentDetailReportCollection).to receive(:new).and_call_original
    end

    context 'when a section report is needed' do
      let(:presenter) do
        described_class.new(
          section:,
          program:,
          **presenter_opts.except(:standard_id)
        )
      end

      it 'creates a data collection object' do
        presenter.standards_data

        expect(StandardsReports::SectionReportCollection).to have_received(:new).with(
          activities: [activity, activity_2],
          direction: nil,
          section:,
          sort: nil,
          standard_sets: [standard_set_1, standard_set_2]
        )
      end
    end

    context 'when a student detail report is needed' do
      let(:presenter) do
        described_class.new(section:, program:, **presenter_opts)
      end

      it 'creates a data collection object' do
        presenter.standards_data

        expect(StandardsReports::StudentDetailReportCollection).to have_received(:new).with(
          activities: [activity, activity_2],
          direction: nil,
          section:,
          sort: nil,
          standard_sets: [standard_set_1, standard_set_2],
          standard:
        )
      end
    end
  end

  describe '#standards_summary_data' do
    let(:presenter) do
      described_class.new(section:, program:, **presenter_opts)
    end

    before do
      allow(StandardsReports::SectionReportCollection).to receive(:new).and_call_original
    end

    it 'creates a section report collection' do
      presenter.standards_summary_data

      expect(StandardsReports::SectionReportCollection).to have_received(:new).with(
        activities: [activity, activity_2],
        section:,
        standard_sets: [standard_set_1, standard_set_2],
        standard:
      )
    end
  end

  describe '#current_column_sort' do
    def create_presenter(sort_opts = {})
      described_class.new(
        section:,
        program:,
        **presenter_opts.merge(sort_opts)
      )
    end

    it 'returns unsorted for a column when the table is sorted by' \
       'another column in descending order.' do
      expect(
        create_presenter(sort: activity.id.to_s, direction: 'desc')
         .current_column_sort('Student', :student)
      ).to eq('unsorted')
    end

    it 'returns unsorted for a column when the table is sorted by' \
       'another column in ascending order.' do
      expect(
        create_presenter(sort: activity.id.to_s, direction: 'asc')
          .current_column_sort('Student', :student)
      ).to eq('unsorted')
    end

    it 'returns ascending for a sorted ascending column' do
      expect(
        create_presenter(sort: 'student', direction: 'asc')
          .current_column_sort('Student', :student)
      ).to eq('ascending')
    end

    it 'returns descending for a sorted descending column' do
      expect(
        create_presenter(sort: 'student', direction: 'desc')
          .current_column_sort('Student', :student)
      ).to eq('descending')
    end

    it 'returns unsorted for an invalid column name' do
      expect(
        create_presenter(sort: 'percent_correct', direction: 'asc')
          .current_column_sort('Student', :points_earned)
      ).to eq('unsorted')
    end

    it 'returns ascending when sorting has an invalid direction' do
      expect(
        create_presenter(sort: 'student', direction: 'north')
        .current_column_sort('Student', :student)
      ).to eq('ascending')
    end
  end

  describe '#standard_sets_for_select' do
    let!(:course_standard_sets) do
      [standard_set_1, standard_set_2, standard_set_3].each do |standard_set|
        CourseStandardSet.create(
          course: section.course,
          standard_set:
        )
      end
    end

    let(:presenter) do
      described_class.new(section:, program:, **presenter_opts.except(:standard_id))
    end

    it 'creates the selections for the standard set drop-down' do
      expect(presenter.standard_sets_for_select).to eq(
        [['CCSS'], ['NGA Center/CCSSO - Fallback Name']]
      )
    end
  end

  describe '#standard_set' do
    let(:presenter) do
      described_class.new(section:, program:, **presenter_opts)
    end

    context 'when the standard set display name matches' do
      it 'returns the correct standard set' do
        expect(presenter.standard_set).to eq(standard_set_1)
      end
    end

    context 'when the standard set display name does not match' do
      before do
        presenter_opts[:standard_set_display_name] = 'Non-existent Display Name'
      end

      it 'returns nil' do
        expect(presenter.standard_set).to be_nil
      end
    end

    context 'when the standard set display name is nil' do
      before do
        presenter_opts[:standard_set_display_name] = nil
      end

      it 'returns nil' do
        expect(presenter.standard_set).to be_nil
      end
    end
  end
end
