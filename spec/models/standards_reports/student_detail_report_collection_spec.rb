describe StandardsReports::StudentDetailReportCollection do
  let(:activity) { create(:activity, cms_activity_id: 285_669) }
  let(:section) { create(:section) }
  let(:standard) do
    Standard.create(
      id: 4382,
      vendor_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
      vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      name: 'English Language Arts/Literacy',
      description: 'Demonstrate command of the conventions of standard English ' \
                   'grammar and usage when writing or speaking.',
      label: 'Grade Level Standard',
      number: 'CCSS.ELA-Literacy.L.7.1'
    )
  end

  let(:standard_set) do
    StandardSet.create(
      vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
      issuer: 'NGA Center/CCSSO',
      name: 'English Language Arts/Literacy',
      adopt_year: 2010,
      state: 'US,CC',
      acronym: 'CCSS',
      description: 'Common Core State Standards'
    )
  end

  let(:report) do
    described_class.new(
      activities: [activity],
      section: section,
      standard: standard,
      standard_sets: [standard_set]
    )
  end

  let(:student_1) do
    user = build_stubbed(:student)
    described_class::StudentInfo.new(
      name: user.last_name_first,
      user_id: user.id
    )
  end

  let(:student_2) do
    user = build_stubbed(:student)
    described_class::StudentInfo.new(
      name: user.last_name_first,
      user_id: user.id
    )
  end

  let(:standards_results) do
    [
      create(
        :standards_results,
        cms_activity_id: activity.cms_activity_id,
        results_data: {
          '56a5775a-589f-49d7-a922-506de373c4ba' => {
            question_label: 'question_01',
            points_earned: 2,
            points_possible: 2
          }
        },
        user_id: student_1.user_id
      )
    ]
  end

  let(:existing_guid) { standards_results.first.results_data.keys.first }

  before do
    allow(report).to receive(:standards_results).and_return(standards_results)
    allow(report).to receive(:standard).and_return(standard)
    allow(report).to receive(:students).and_return([student_1, student_2])
  end

  describe '#find_or_create_row' do
    before do
      allow(report).to receive(:rows).and_return(
        [
          StandardsReports::StudentDetailReportRow.new(
            student: student_1,
            standard: standard,
            guid: existing_guid,
            record: standards_results.first
          )
        ]
      )
    end

    context 'when there is no matching row' do
      it 'creates a new row object when there is no match' do
        new_guid = SecureRandom.uuid
        data = build(
          :standards_results,
          cms_activity_id: activity.cms_activity_id,
          results_data: {
            new_guid => {
              question_label: 'question_02',
              points_earned: 2,
              points_possible: 2
            }
          },
          user_id: student_2.user_id
        )
        report.find_or_create_row(student_2, new_guid, data)

        expect(report.rows.count).to eq(2)
        expect(report.rows.last.student).to eq(student_2)
      end
    end

    context 'when there is a matching row' do
      it 'adds data to the matching row' do
        report.find_or_create_row(
          student_1,
          existing_guid,
          build(
            :standards_results,
            results_data: {
              existing_guid => {
                question_label: 'question_02',
                points_earned: 2,
                points_possible: 2
              }
            },
            user_id: student_1.user_id
          )
        )

        expect(report.rows.count).to eq(1)
        expect(report.rows.first.student).to eq(student_1)
      end

      it 'adds new data to the row' do
        new_data = build(
          :standards_results,
          cms_activity_id: activity.cms_activity_id,
          results_data: {
            existing_guid => {
              question_label: 'question_02',
              points_earned: 1,
              points_possible: 3
            },
            user_id: student_1.user_id
          }
        )
        report.find_or_create_row(student_1, existing_guid, new_data)

        expect(report.rows.count).to eq(1)
        expect(report.rows.first.data_set.count).to eq(2)
        expected_data = new_data[:results_data][existing_guid]
        expect(report.rows.first.data_set.last.results_data.points_earned).to eq(
          expected_data[:points_earned]
        )
        expect(report.rows.first.data_set.last.results_data.points_possible).to eq(
          expected_data[:points_possible]
        )
      end
    end
  end

  describe '#report_rows' do
    before do
      allow(report).to receive(:standards_results).and_return(standards_results)
      allow(report).to receive(:standard).and_return(standard)
      allow(report).to receive(:alignment_question_guids).and_return([existing_guid])
    end

    it 'returns an array with students' do
      expect(report.report_rows.map(&:student).map(&:name)).to contain_exactly(
        student_1.name, student_2.name
      )
    end

    it 'returns results data associated with each student' do
      expect(report.report_rows.flat_map(&:data_set).map(&:guid)).to eq(
        ['56a5775a-589f-49d7-a922-506de373c4ba']
      )
    end

    context 'when sorting' do
      let(:students) do
        [
          create(:student, last_name: 'Kunde', first_name: 'Brando'),
          create(:student, last_name: 'Vandervort', first_name: 'Noel'),
          create(:student, last_name: 'Rolfson', first_name: 'Lucius'),
          create(:student, last_name: 'Bruen', first_name: 'Bernie'),
          create(:student, last_name: 'Mills', first_name: 'Elmira'),
          create(:student, last_name: 'Turcotte', first_name: 'Breanne'),
          create(:student, last_name: 'Lynch', first_name: 'Norwood'),
          create(:student, last_name: 'Zulauf', first_name: 'Gardner'),
          create(:student, last_name: 'Weber', first_name: 'Julie'),
          create(:student, last_name: 'Heathcote', first_name: 'Curtis')
        ].map do |memo|
          described_class::StudentInfo.new(
            user_id: memo.id,
            name: memo.last_name_first
          )
        end
      end

      let(:standards) do
        [
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.RL.7.1',
            guids: %w[
              8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e
              5f531235-490b-457b-9369-d7e09ca2b190
              acec2b30-ccec-445e-b8d9-54460309df00
              9a26e3fd-2b26-41f4-94e2-e6c65d01476d
            ],
            vendor_guid: SecureRandom.uuid
          )
        ]
      end

      MockArel = Struct.new(:cms_activity_id, :results_data, :user_id)

      let(:standards_results) do
        json = File.read('spec/fixtures/json/standards_results.json')
        records = JSON.parse(json).each_with_index do |standards_result, index|
          standards_result['section_id'] = section.id
          standards_result['user_id'] = (students[index]&.user_id || create(:student).id)
        end.map(&:symbolize_keys)
        records.map do |record|
          MockArel.new(
            record[:cms_activity_id],
            record[:results_data],
            record[:user_id]
          )
        end
      end

      def create_sorted_report(sort = nil, direction = nil)
        report = described_class.new(
          activities: [activity],
          section: section,
          standard: standard,
          standard_sets: [standard_set],
          sort: sort,
          direction: direction
        )

        allow(report).to receive(:standards_results).and_return(standards_results)
        allow(report).to receive(:students).and_return(students)
        allow(report).to receive(:standards).and_return(standards)
        allow(report).to receive(:alignment_question_guids).and_return(
          %w[
            8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e
            5f531235-490b-457b-9369-d7e09ca2b190
            acec2b30-ccec-445e-b8d9-54460309df00
            9a26e3fd-2b26-41f4-94e2-e6c65d01476d
          ]
        )
        report
      end

      it 'sorts by students as a default' do
        report = create_sorted_report

        expect(report.report_rows.map { |r| r.student.name }).to eq(
          [
            'Bruen, Bernie',
            'Heathcote, Curtis',
            'Kunde, Brando',
            'Lynch, Norwood',
            'Mills, Elmira',
            'Rolfson, Lucius',
            'Turcotte, Breanne',
            'Vandervort, Noel',
            'Weber, Julie',
            'Zulauf, Gardner'
          ]
        )
      end

      it 'uses the default sort if sort params are empty' do
        report = create_sorted_report('', '')

        expect(report.report_rows.map { |r| r.student.name }).to eq(
          [
            'Bruen, Bernie',
            'Heathcote, Curtis',
            'Kunde, Brando',
            'Lynch, Norwood',
            'Mills, Elmira',
            'Rolfson, Lucius',
            'Turcotte, Breanne',
            'Vandervort, Noel',
            'Weber, Julie',
            'Zulauf, Gardner'
          ]
        )
      end

      context 'by percent_correct' do
        it 'sorts in descending order' do
          report = create_sorted_report(activity.id.to_s, 'desc')

          expect(
            report.report_rows.map { |a| a.percent_correct_by_activity(activity.cms_activity_id) }
          ).to eq(
            [100, 100, 100, 100, 100, 100, 75, 50, 50, 25]
          )
        end

        it 'sorts in ascending order' do
          report = create_sorted_report(activity.id.to_s, 'asc')

          expect(
            report.report_rows.map { |a| a.percent_correct_by_activity(activity.cms_activity_id) }
          ).to eq(
            [25, 50, 50, 75, 100, 100, 100, 100, 100, 100]
          )
        end

        it 'applies a secondary sort by students' do
          report = create_sorted_report(activity.id.to_s, 'asc')

          expect(report.report_rows[4..9].map { |r| r.student.name }).to eq(
            [
              'Heathcote, Curtis',
              'Kunde, Brando',
              'Lynch, Norwood',
              'Turcotte, Breanne',
              'Vandervort, Noel',
              'Weber, Julie'
            ]
          )
        end
      end

      context 'by number of items' do
        it 'sorts in descending order' do
          report = create_sorted_report(:number_of_items, 'desc')

          expect(report.report_rows.map(&:total_number_of_items)).to eq(
            [4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
          )
        end

        it 'sorts in ascending order' do
          report = create_sorted_report(:number_of_items, 'asc')

          expect(report.report_rows.map(&:total_number_of_items)).to eq(
            [4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
          )
        end

        it 'applies a secondary sort by students' do
          report = create_sorted_report(:number_of_items, 'asc')

          expect(report.report_rows.map { |r| r.student.name }).to eq(
            [
              'Bruen, Bernie',
              'Heathcote, Curtis',
              'Kunde, Brando',
              'Lynch, Norwood',
              'Mills, Elmira',
              'Rolfson, Lucius',
              'Turcotte, Breanne',
              'Vandervort, Noel',
              'Weber, Julie',
              'Zulauf, Gardner'
            ]
          )
        end
      end
    end
  end
end
