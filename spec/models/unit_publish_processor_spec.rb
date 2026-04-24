describe UnitPublishProcessor do
  let(:params) do
    {
      'program_id'    => '48',
      'rank'          => '1',
      'toc_location'  => '1500',
      'name'          => 'Unidad 1: Los viajes del viento',
      'label'         => 'Unidad 1',
      'media_item_id' => '150620',
      'released'      => '1',
      'use_type'      => 'Unit'
    }
  end

  it 'includes BasePublishProcessor' do
    expect(UnitPublishProcessor.new(params)).to be_a BasePublishProcessor
  end
end
