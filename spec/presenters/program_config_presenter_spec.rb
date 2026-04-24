describe ProgramConfigPresenter do
  describe '#standard_sets' do
    context 'when the program config is for a VOL program,' do
      it 'returns a list of all the existing standard sets ' \
        'sorted by the format display_name' do
        standard_set_1 = create(:standard_set)
        standard_set_2 = create(:standard_set)
        standard_set_3 = create(:standard_set)
        program_config = create(:program_config)

        presenter = described_class.new(program_config)

        expect(presenter.standard_sets).to eq(
          [
            {
              name: standard_set_1.display_name,
              ids: standard_set_1.id.to_s
            },
            {
              name: standard_set_2.display_name,
              ids: standard_set_2.id.to_s
            },
            {
              name: standard_set_3.display_name,
              ids: standard_set_3.id.to_s
            }
          ]
        )
      end
    end

    it 'returns a list of all the existing standard sets ' \
       'sorted by the format display_name' do
      standard_set_1 = create(:standard_set)
      standard_set_2 = create(:standard_set)
      standard_set_3 = create(:standard_set)
      program_config = create(:program_config)

      presenter = described_class.new(program_config)

      expect(presenter.standard_sets).to eq(
        [
          {
            name: standard_set_1.display_name,
            ids: standard_set_1.id.to_s
          },
          {
            name: standard_set_2.display_name,
            ids: standard_set_2.id.to_s
          },
          {
            name: standard_set_3.display_name,
            ids: standard_set_3.id.to_s
          }
        ]
      )
    end

    context 'when the display name is empty' do
      it 'returns an empty array' do
        create(:standard_set, name: 'standard_set_1', display_name: '')
        program_config = create(:program_config)

        presenter = described_class.new(program_config)

        expect(presenter.standard_sets).to eq([])
      end
    end
  end
end
