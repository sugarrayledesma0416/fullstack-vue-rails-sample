describe StandardsReports::SectionReportCollection do
  let(:activity) { create(:activity, cms_activity_id: 285_669) }
  let(:program) { create(:program) }
  let(:course) { create(:course, program:) }
  let(:section) { create(:section, course:) }
  let(:standard_sets) do
    [
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
    ]
  end

  let(:report) do
    described_class.new(activities: [activity], section:, standard_sets:)
  end

  let(:standards) do
    [
      described_class::StandardInfo.new(
        label: 'CCSS.ELA-Literacy.L.7.1',
        guids: %w[
          56a5775a-589f-49d7-a922-506de373c4ba
          8ba67231-ea4e-43cc-99bd-cc9171c237ed
          93e1814e-1935-4591-95a3-d8ff9554c0bb
        ],
        vendor_guid: SecureRandom.uuid
      ),
      described_class::StandardInfo.new(
        label: 'CCSS.ELA-Literacy.L.7.2',
        guids: ['eee7ea48-bfdd-4e41-8342-d53b165ce636'],
        vendor_guid: SecureRandom.uuid
      ),
      described_class::StandardInfo.new(
        label: 'CCSS.ELA-Literacy.L.7.4',
        guids: ['7c41dd1b-bd6c-4ab5-9176-19b7f8cfadc0'],
        vendor_guid: SecureRandom.uuid
      )
    ]
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
        }
      )
    ]
  end

  let(:existing_guid) { standards_results.first.results_data.keys.first }

  before do
    allow(report).to receive(:standards_results).and_return(standards_results)
    allow(report).to receive(:standards).and_return(standards)
    allow(program).to receive(:standard_grade_levels).and_return(%w[6 7 8])
  end

  describe '#find_or_create_row' do
    before do
      allow(report).to receive(:rows).and_return(
        [
          StandardsReports::SectionReportRow.new(
            standard: standards[2],
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
          }
        )
        report.find_or_create_row(standards[1], new_guid, data)

        expect(report.rows.count).to eq(2)
        expect(report.rows.last.standard.label).to eq(standards[1].label)
        expect(report.rows.last.standard.guids).to eq(standards[1].guids)
      end
    end

    context 'when there is a matching row' do
      it 'adds data to the matching row' do
        report.find_or_create_row(
          standards[2],
          existing_guid,
          build(
            :standards_results,
            results_data: {
              existing_guid => {
                question_label: 'question_02',
                points_earned: 2,
                points_possible: 2
              }
            }
          )
        )

        expect(report.rows.count).to eq(1)
        expect(report.rows.first.standard.label).to eq(standards[2].label)
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
            }
          }
        )
        report.find_or_create_row(standards[2], existing_guid, new_data)

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

    context 'when there is a sample student submission' do
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
            }
          ),
          create(
            :standards_results,
            cms_activity_id: activity.cms_activity_id,
            results_data: {
              '56a5775a-589f-49d7-a922-506de373c4ba' => {
                question_label: 'question_01',
                points_earned: 2,
                points_possible: 2
              }
            }
          )
        ]
      end
    end
  end

  describe '#standards_for_guid' do
    it 'returns an array of Structs containing the standard' do
      expect(
        report.standards_for_guid('8ba67231-ea4e-43cc-99bd-cc9171c237ed').map(&:label)
      ).to eq(['CCSS.ELA-Literacy.L.7.1'])
    end

    it 'returns an array of structs containing the guids' do
      expect(
        report.standards_for_guid('8ba67231-ea4e-43cc-99bd-cc9171c237ed').first.guids
      ).to eq(
        %w[
          56a5775a-589f-49d7-a922-506de373c4ba
          8ba67231-ea4e-43cc-99bd-cc9171c237ed
          93e1814e-1935-4591-95a3-d8ff9554c0bb
        ]
      )
    end

    it 'returns an empty array when there is no match' do
      expect(report.standards_for_guid('this-does-not-match-anything')).to be_empty
    end
  end

  describe '#report_rows' do
    let(:standards) do
      [
        described_class::StandardInfo.new(
          description: 'Cite several pieces of textual evidence to support ' \
                       'analysis of what the text says explicitly as well ' \
                       'as inferences drawn from the text.',
          guids: %w[
            8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e
            5f531235-490b-457b-9369-d7e09ca2b190
            acec2b30-ccec-445e-b8d9-54460309df00
            9a26e3fd-2b26-41f4-94e2-e6c65d01476d
          ],
          label: 'CCSS.ELA-Literacy.RL.7.1'
        ),
        described_class::StandardInfo.new(
          description: 'Determine a theme or central idea of a text and ' \
                       'analyze its development over the course of the ' \
                       'text; provide an objective summary of the text.',
          guids: %w[
            ad3c1e29-447c-47cf-b89a-fa3d13488b88
            aa0b6a1c-206f-4192-932e-c980dcea572e
            56a5775a-589f-49d7-a922-506de373c4ba
          ],
          label: 'CCSS.ELA-Literacy.RL.7.2'
        )
      ]
    end

    before do
      allow(report).to receive(:standards).and_return(standards)
    end

    it 'returns an array with standards' do
      expect(report.report_rows.map(&:standard).map(&:label)).to eq(
        %w[CCSS.ELA-Literacy.RL.7.1 CCSS.ELA-Literacy.RL.7.2]
      )
    end

    it 'returns results data associated with each standard' do
      expect(report.report_rows.first.data_set.map(&:guid)).to eq(
        ['56a5775a-589f-49d7-a922-506de373c4ba']
      )
      expect(report.report_rows.last.data_set).to eq([])
    end

    # For the standard summary at the top of the student details report
    context 'when a standard is provided' do
      let(:standard_sets) do
        [
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
        ]
      end

      let(:standards) do
        [
          Standard.create(
            vendor_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
            vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
            name: 'English Language Arts/Literacy',
            description: 'Demonstrate command of the conventions of standard English ' \
                         'grammar and usage when writing or speaking.',
            label: 'Grade Level Standard',
            number: 'CCSS.ELA-Literacy.L.7.1',
            additional_info: { additional_info: { grade_levels: '6, 7, 8' } }.to_json
          ),
          Standard.create(
            vendor_guid: '80D05CB2-7440-11DF-93FA-01FD9CFF4B22',
            vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
            name: 'English Language Arts/Literacy',
            description: 'Explain the function of phrases and clauses in general ' \
                         'and their function in specific sentences.',
            label: '',
            number: 'CCSS.ELA-Literacy.L.7.1.a',
            additional_info: { additional_info: { grade_levels: '6, 7, 8' } }.to_json
          )
        ]
      end

      let(:report) do
        described_class.new(
          activities: [activity],
          section: section,
          standard_sets: standard_sets,
          standard: standards.first
        )
      end

      before do
        allow(report).to receive(:standards).and_call_original
        allow(report).to receive(:alignments).and_return(
          [
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '93e1814e-1935-4591-95a3-d8ff9554c0bb'
            ),
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '56a5775a-589f-49d7-a922-506de373c4ba'
            ),
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '8ba67231-ea4e-43cc-99bd-cc9171c237ed'
            )
          ]
        )
        allow(report).to receive(:alignment_question_guids)
          .with('80CF6BE0-7440-11DF-93FA-01FD9CFF4B22')
          .and_return(
            %w[
              56a5775a-589f-49d7-a922-506de373c4ba
              8ba67231-ea4e-43cc-99bd-cc9171c237ed
              93e1814e-1935-4591-95a3-d8ff9554c0bb
            ]
          )
        allow(report).to receive(:alignment_question_guids)
          .with('80D05CB2-7440-11DF-93FA-01FD9CFF4B22')
          .and_return(['eee7ea48-bfdd-4e41-8342-d53b165ce636'])
      end

      it 'creates a data structure with just one standard' do
        expect(report.report_rows.count).to eq(1)
      end

      it 'contains the specified standard' do
        expect(report.report_rows.first.standard.label).to eq(
          standards.first.number
        )
      end
    end

    context 'when no standard is provided' do
      let(:standard_sets) do
        [
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
        ]
      end

      let(:standards) do
        [
          Standard.create(
            vendor_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
            vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
            name: 'English Language Arts/Literacy',
            description: 'Demonstrate command of the conventions of standard English ' \
              'grammar and usage when writing or speaking.',
            label: 'Grade Level Standard',
            number: 'CCSS.ELA-Literacy.L.7.1',
            additional_info: { additional_info: { grade_levels: '6, 7, 8' } }.to_json
          ),
          Standard.create(
            vendor_guid: '80D05CB2-7440-11DF-93FA-01FD9CFF4B22',
            vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
            name: 'English Language Arts/Literacy',
            description: 'Explain the function of phrases and clauses in general ' \
              'and their function in specific sentences.',
            label: '',
            number: 'CCSS.ELA-Literacy.L.7.1.a',
            additional_info: { additional_info: { grade_levels: '6, 7, 8' } }.to_json
          ),
          Standard.create(
            vendor_guid: '053A60A8-769C-11DF-90A5-0D639DFF4B22',
            vendor_standard_set_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
            name: 'English Language Arts/Literacy',
            description: 'Determine the central ideas or conclusions of a text.',
            label: '',
            number: 'CCSS.ELA-Literacy.L.9.1',
            additional_info: { additional_info: { grade_levels: '9, 10' } }.to_json
          )
        ]
      end

      let(:report) do
        described_class.new(
          activities: [activity],
          section: section,
          standard_sets: standard_sets
        )
      end

      before do
        allow(report).to receive(:standards).and_call_original
        allow(report).to receive(:alignments).and_return(
          [
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '93e1814e-1935-4591-95a3-d8ff9554c0bb'
            ),
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '56a5775a-589f-49d7-a922-506de373c4ba'
            ),
            double(
              'StandardAlignment',
              vendor_standard_guid: '80CF6BE0-7440-11DF-93FA-01FD9CFF4B22',
              item_guid: '8ba67231-ea4e-43cc-99bd-cc9171c237ed'
            ),
            double(
              'StandardAlignment',
              vendor_standard_guid: '053A60A8-769C-11DF-90A5-0D639DFF4B22',
              item_guid: '56a5775a-589f-49d7-a922-506de373c4ba'
            )
          ]
        )
      end

      it 'eliminates the standard that does not match program grade levels' do
        expect(report.report_rows.count).to eq(1)
      end

      it 'does not contain any standard with a grade level that does not match the program' do
        expect(
          report.standards_for_guid('56a5775a-589f-49d7-a922-506de373c4ba').map(&:label)
        ).not_to include 'CCSS.ELA-Literacy.L.9.1'
      end
    end

    context 'when sorting' do
      let(:standards) do
        [
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.L.7.1',
            guids: %w[
              56a5775a-589f-49d7-a922-506de373c4ba
              8ba67231-ea4e-43cc-99bd-cc9171c237ed
              93e1814e-1935-4591-95a3-d8ff9554c0bb
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.L.7.2',
            guids: ['eee7ea48-bfdd-4e41-8342-d53b165ce636'],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.L.7.4',
            guids: ['7c41dd1b-bd6c-4ab5-9176-19b7f8cfadc0'],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.RL.7.1',
            guids: %w[
              5f531235-490b-457b-9369-d7e09ca2b190
              8e4b78f3-a05d-4e43-ac6f-b1c2dcb7f11e
              9a26e3fd-2b26-41f4-94e2-e6c65d01476d
              acec2b30-ccec-445e-b8d9-54460309df00
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.RL.7.2',
            guids: %w[
              12ac65d6-ac41-4f79-8309-a10888712e3f
              aa0b6a1c-206f-4192-932e-c980dcea572e
              ad3c1e29-447c-47cf-b89a-fa3d13488b88
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.RL.7.4',
            guids: %w[
              6a99b9fd-fd76-4af8-8386-ad2140afa48b
              e1c19962-18ea-4a5b-9675-4df13def5996
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.RL.7.5',
            guids: %w[
              349552ff-7996-436c-9118-16edf2df8fb2
              64d70de5-89f3-4653-a94c-905336f58f9b
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.SL.7.1',
            guids: ['34b00ac9-37b7-4c1b-b866-be3f71e7cd88'],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.SL.7.2',
            guids: %w[
              05c950e8-d0fa-47a5-abe1-0d43f0e9aa83
              6e3d3807-de76-478f-b51c-171f5f2ab755
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.SL.7.4',
            guids: %w[
              5a9c4e7e-75d8-46ae-b8ce-384fbb874480
              dfef4f16-1948-4133-9817-c9245fe2d4bb
            ],
            vendor_guid: SecureRandom.uuid
          ),
          described_class::StandardInfo.new(
            label: 'CCSS.ELA-Literacy.W.7.3',
            guids: ['eee7ea48-bfdd-4e41-8342-d53b165ce636'],
            vendor_guid: SecureRandom.uuid
          )
        ]
      end

      MockArel = Struct.new(:cms_activity_id, :results_data, :user_id)

      let(:standards_results) do
        json = File.read('spec/fixtures/json/standards_results.json')
        records = JSON.parse(json).map(&:symbolize_keys)
        records.map do |record|
          MockArel.new(
            record[:cms_activity_id],
            record[:results_data],
            build_stubbed(:student).id
          )
        end
      end

      def create_sorted_report(sort = nil, direction = nil)
        report = described_class.new(
          activities: [activity],
          section:,
          standard_sets:,
          sort:,
          direction:
        )

        allow(report).to receive(:standards_results).and_return(standards_results)
        allow(report).to receive(:standards).and_return(standards)
        report
      end

      it 'sorts by standards as a default' do
        report = create_sorted_report

        expect(report.report_rows.map { |r| r.standard.label }).to eq(
          %w[
            CCSS.ELA-Literacy.L.7.1
            CCSS.ELA-Literacy.L.7.2
            CCSS.ELA-Literacy.L.7.4
            CCSS.ELA-Literacy.RL.7.1
            CCSS.ELA-Literacy.RL.7.2
            CCSS.ELA-Literacy.RL.7.4
            CCSS.ELA-Literacy.RL.7.5
            CCSS.ELA-Literacy.SL.7.1
            CCSS.ELA-Literacy.SL.7.2
            CCSS.ELA-Literacy.SL.7.4
            CCSS.ELA-Literacy.W.7.3
          ]
        )
      end

      it 'uses the default sort if sort params are empty' do
        report = create_sorted_report('', '')

        expect(report.report_rows.map { |r| r.standard.label }).to eq(
          %w[
            CCSS.ELA-Literacy.L.7.1
            CCSS.ELA-Literacy.L.7.2
            CCSS.ELA-Literacy.L.7.4
            CCSS.ELA-Literacy.RL.7.1
            CCSS.ELA-Literacy.RL.7.2
            CCSS.ELA-Literacy.RL.7.4
            CCSS.ELA-Literacy.RL.7.5
            CCSS.ELA-Literacy.SL.7.1
            CCSS.ELA-Literacy.SL.7.2
            CCSS.ELA-Literacy.SL.7.4
            CCSS.ELA-Literacy.W.7.3
          ]
        )
      end

      context 'when sorting by the activity percent_correct' do
        it 'sorts in descending order' do
          report = create_sorted_report(activity.id.to_s, 'desc')

          expect(
            report.report_rows.map { |a| a.percent_correct_by_activity(activity.cms_activity_id) }
          ).to eq(
            [92, 86, 86, 84, 84, 82, 82, 82, 82, 81, 72]
          )
        end

        it 'sorts in ascending order' do
          report = create_sorted_report(activity.id.to_s, 'asc')

          expect(
            report.report_rows.map { |a| a.percent_correct_by_activity(activity.cms_activity_id) }
          ).to eq(
            [72, 81, 82, 82, 82, 82, 84, 84, 86, 86, 92]
          )
        end

        it 'applies a secondary sort by standards' do
          report = create_sorted_report(activity.id.to_s, 'asc')

          expect(report.report_rows[2..5].map { |r| r.standard.label }).to eq(
            %w[
              CCSS.ELA-Literacy.L.7.2
              CCSS.ELA-Literacy.RL.7.1
              CCSS.ELA-Literacy.SL.7.4
              CCSS.ELA-Literacy.W.7.3
            ]
          )
        end
      end

      context 'by number of items' do
        it 'sorts in descending order' do
          report = create_sorted_report(:number_of_items, 'desc')

          expect(report.report_rows.map(&:total_number_of_items)).to eq(
            [4, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1]
          )
        end

        it 'sorts in ascending order' do
          report = create_sorted_report(:number_of_items, 'asc')

          expect(report.report_rows.map(&:total_number_of_items)).to eq(
            [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 4]
          )
        end

        it 'applies a secondary sort by standards' do
          report = create_sorted_report(:number_of_items, 'asc')

          expect(report.report_rows.first(4).map { |r| r.standard.label }).to eq(
            %w[
              CCSS.ELA-Literacy.L.7.2
              CCSS.ELA-Literacy.L.7.4
              CCSS.ELA-Literacy.SL.7.1
              CCSS.ELA-Literacy.W.7.3
            ]
          )
        end
      end
    end
  end
end
