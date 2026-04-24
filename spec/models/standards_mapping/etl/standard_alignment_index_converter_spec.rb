require 'rails_helper'

RSpec.describe StandardsMapping::Etl::StandardAlignmentIndexConverter do
  let(:standard_set) do
    create(
      :standard_set,
      issuer: 'Some Issuer',
      display_name: 'Standard Set Name'
    )
  end

  let(:standard) do
    create(
      :standard,
      vendor_guid: 'STD-123',
      name: 'Standard Name',
      number: '1.1',
      label: 'Standard Label',
      description: 'Standard Description',
      vendor_standard_set_guid: standard_set.vendor_guid,
      additional_info: JSON.generate(
        {
          additional_info: {
            parent_guid: 'PARENT-456',
            ancestors: 'ANCESTOR-1,ANCESTOR-2',
            grade_levels: '8,9'
          }
        }
      ),
      standard_set:,
      searchable: true
    )
  end

  let(:standard_asset) do
    create(
      :standard_asset,
      reference_id: 'REF-123',
      reference_type: 'Activity',
      additional_attrs: { domain: 'Math,Science', subdomain: 'Algebra,Physics' }
    )
  end

  let(:alignment) do
    create(
      :standard_alignment,
      standard_asset:,
      vendor_standard_guid: standard.vendor_guid
    )
  end

  let(:program) { create(:program) }
  let(:unit) { create(:unit, program:) }
  let(:lesson) { create(:lesson, unit:) }
  let(:activity) { create(:activity, cms_activity_id: 101, toc_location: 'Unit 1', lesson:) }
  let(:converter) { described_class.new }

  before do
    allow(Activity).to receive(:where).and_return([activity])
  end

  describe '#convert' do
    it 'includes alignment_id' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:alignment_id]).to eq(alignment.id)
    end

    it 'includes alignment_status' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:alignment_status]).to eq(alignment.alignment_status)
    end

    it 'includes standard_asset_id' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:standard_asset_id]).to eq(standard_asset.id)
    end

    it 'includes standard_asset_reference_id' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:standard_asset_reference_id]).to eq(standard_asset.reference_id)
    end

    it 'includes standard_asset_reference_type' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:standard_asset_reference_type]).to eq(standard_asset.reference_type)
    end

    it 'includes issuer' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:issuer]).to eq(standard_set.issuer)
    end

    it 'includes display_name' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:display_name]).to eq(standard_set.display_name)
    end

    it 'includes searchable' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:searchable]).to eq(standard.searchable)
    end

    it 'includes standard_asset_domains' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:standard_asset_domains]).to eq(%w[math science])
    end

    it 'includes standard_asset_subdomains' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:standard_asset_subdomains]).to eq(%w[algebra physics])
    end

    it 'includes programs' do
      result = converter.convert(alignment, standard, standard_asset)
      expect(result[:programs]).to include(
        program_id: program.id,
        lesson_id: lesson.id,
        unit_id: unit.id
      )
    end
  end

  describe '#convert_programs' do
    context 'when standard asset has activity reference' do
      it 'fetches activity programs' do
        converter.instance_variable_set(:@std_asset, standard_asset)
        converter.send(:determine_cms_activity_id)

        expect(converter.send(:convert_programs)).to include(
          program_id: program.id,
          lesson_id: lesson.id,
          unit_id: unit.id
        )
      end
    end

    context 'when standard asset has no valid reference' do
      before do
        allow(standard_asset).to receive(:activity_reference?).and_return(false)
        allow(standard_asset).to receive(:assessment_item_reference?).and_return(false)
        allow(standard_asset).to receive(:ereader_item_reference?).and_return(false)
      end

      it 'returns an empty array' do
        converter.instance_variable_set(:@std_asset, standard_asset)
        converter.send(:determine_cms_activity_id)

        expect(converter.send(:convert_programs)).to eq([])
      end
    end
  end

  describe '#add_standard' do
    it 'returns vendor_guid' do
      result = converter.send(:add_standard, standard)
      expect(result[:vendor_guid]).to eq('STD-123')
    end

    it 'returns name' do
      result = converter.send(:add_standard, standard)
      expect(result[:name]).to eq('Standard Name')
    end

    it 'returns number' do
      result = converter.send(:add_standard, standard)
      expect(result[:number]).to eq('1.1')
    end

    it 'returns label' do
      result = converter.send(:add_standard, standard)
      expect(result[:label]).to eq('Standard Label')
    end

    it 'returns description' do
      result = converter.send(:add_standard, standard)
      expect(result[:description]).to eq('Standard Description')
    end

    it 'returns vendor_standard_set_guid' do
      result = converter.send(:add_standard, standard)
      expect(result[:vendor_standard_set_guid]).to eq(standard_set.vendor_guid)
    end

    it 'returns issuer' do
      result = converter.send(:add_standard, standard)
      expect(result[:issuer]).to eq('Some Issuer')
    end

    it 'returns display_name' do
      result = converter.send(:add_standard, standard)
      expect(result[:display_name]).to eq('Standard Set Name')
    end
  end
end
