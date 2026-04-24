describe StandardDecorator do
  describe '#display_number' do
    context 'with a standard with a number' do
      let(:standard_with_num) { create(:standard, description: 'standard_with_num description') }

      it 'shows the number' do
        expect(
          described_class.new(standard_with_num).display_number
        ).to equal(standard_with_num.number)
      end
    end

    context 'with a standard with a blank number' do
      # Setup for standard with no number, parent has a number
      let(:parent_standard_with_num) { create(:standard) }
      let(:standard_with_no_num) do
        create(
          :standard,
          number: '',
          additional_info: {
            additional_info: {
              ancestors: parent_standard_with_num.vendor_guid.to_s
            }
          }.to_json
        )
      end

      it 'returns the parent number, plus the standard description' do
        expect(
          described_class.new(standard_with_no_num).display_number
        ).to eq(parent_standard_with_num.number)
      end
    end

    context 'with a standard with a blank number & 1st parent has blank number' do
      # Setup for standard with no number, parent has no number, first ancester has a number
      let!(:parent_standard_with_no_num_2) { create(:standard, number: '') }
      let(:ancestor_standard_with_num) { create(:standard) }
      let(:standard_with_no_num_and_parent_no_num) do
        create(
          :standard,
          number: '',
          additional_info: {
            additional_info: {
              ancestors: "#{ancestor_standard_with_num.vendor_guid}," \
                         "#{parent_standard_with_no_num_2.vendor_guid}"
            }
          }.to_json
        )
      end

      it 'returns the ancestor with a number, plus the standard description' do
        expect(
          described_class.new(standard_with_no_num_and_parent_no_num).display_number
        ).to eq(ancestor_standard_with_num.number)
      end
    end
  end
end
