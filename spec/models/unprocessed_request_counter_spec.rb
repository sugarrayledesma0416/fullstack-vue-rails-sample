describe UnprocessedRequestCounter do

  let(:section) { build_stubbed(:section) }
  let(:student_1){ build_stubbed(:student) }
  let(:student_2){ build_stubbed(:student) }
  let(:section_students){ [student_1, student_2] }
  let(:count_results) { { section.id => 35, ['request_help', section.id] => 123, ['request_review', section.id] => 456 } }
  let(:counter) { UnprocessedRequestCounter.new([section], [section_students]).populate }

  before do
    allow(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).and_return(count_results)
  end

  describe '#populate' do
    it 'retrieves unprocessed counts for help and review requests for specified sections' do
      expected_request_types = ['request_help', 'request_review']
      expected_count_opts = { group: [:request_type, 'help_requests.section_id'] }

      expect(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).with(expected_request_types, [section], section_students, expected_count_opts)

      UnprocessedRequestCounter.new([section], section_students).populate
    end

    it 'retrieves unique student counts for unprocessed help and review requests for specified sections' do
      expected_request_types = ['request_help', 'request_review']
      expected_count_opts = { select: 'distinct help_requests.user_id', group: 'help_requests.section_id' }

      expect(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).with(expected_request_types, [section], section_students, expected_count_opts)

      UnprocessedRequestCounter.new([section], section_students).populate
    end

    it 'returns self to allow method chaining with initialize' do
      unprocessed_request_counter = UnprocessedRequestCounter.new([section], section_students)
      expect(unprocessed_request_counter.populate).to eq unprocessed_request_counter
    end
  end

  describe '#help_request_count' do
    context 'when there is a request_help count for the specified section id' do
      it 'returns that count' do
        expect(counter.help_request_count(section.id)).to eq(123)
      end
    end

    it 'returns 0 when there is no request_help count for the specified section id' do
      other_section = build_stubbed(:section)
      expect(counter.help_request_count(other_section.id)).to eq(0)
    end

    it 'returns 0 when there are no counts' do
      allow(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).and_return({})
      expect(UnprocessedRequestCounter.new([section], section_students).populate.help_request_count(section.id)).to eq(0)
    end
  end

  describe '#review_request_count' do
    context 'when there is a request_review count for the specified section id' do
      it 'returns that count' do
        expect(counter.review_request_count(section.id)).to eq(456)
      end
    end

    it 'returns 0 when there is no request_review count for the specified section id' do
      other_section = build_stubbed(:section)
      expect(counter.review_request_count(other_section.id)).to eq(0)
    end

    it 'returns 0 when there are no counts' do
      allow(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).and_return({})
      expect(counter.review_request_count(section.id)).to eq(0)
    end
  end

  describe '#needy_student_count' do
    it 'returns the count of students for the specified section id' do
      expect(counter.needy_student_count(section.id)).to eq(35)
    end

    it 'returns 0 when there are no student counts for the specified section id' do
      other_section = build_stubbed(:section)
      expect(counter.needy_student_count(other_section.id)).to eq(0)
    end

    it 'returns 0 when there are no counts' do
      allow(HelpRequest).to receive(:count_unprocessed_by_request_type_section_and_students).and_return({})
      expect(counter.needy_student_count(section.id)).to eq(0)
    end
  end

end
