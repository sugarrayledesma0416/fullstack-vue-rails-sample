require 'rails_helper'

RSpec.describe StandardsMapping::Etl::StandardAlignmentSource do
  let(:params) do
    {
      batch_size: 100,
      upload_type: 'INITIAL',
      last_upload_date: Time.zone.parse('2024-01-01')
    }
  end

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
      additional_attrs: { domain: 'Math, Science', subdomain: 'Algebra, Physics' }
    )
  end

  let(:alignment) do
    create(
      :standard_alignment,
      standard_asset:,
      vendor_standard_guid: standard.vendor_guid
    )
  end

  before do
    allow(StandardAlignment).to receive(:count).and_return(5)
    allow(Rails.logger).to receive(:info)
  end

  describe '#each' do
    let(:source) { described_class.new(params) }

    context 'when upload type is INITIAL' do
      let(:params) do
        {
          batch_size: 100,
          upload_type: 'INITIAL',
          last_upload_date: Time.zone.parse('2024-01-01')
        }
      end

      before do
        allow(StandardAlignment).to receive(:includes)
          .with(:standard, :standard_asset)
          .and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:find_each)
          .with(batch_size: 100)
          .and_yield(alignment)
      end

      it 'fetches all StandardAlignment records and yields them' do
        expect { |b| source.each(&b) }.to yield_with_args(alignment)
      end
    end

    context 'when upload type is INCREMENTAL and last_upload_date is present' do
      before do
        allow(StandardAlignment).to receive(:eager_load)
          .with(:standard, :standard_asset)
          .and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:where).and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:distinct).and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:find_each)
          .with(batch_size: 100)
          .and_yield(alignment)
      end

      it 'fetches records created or updated after last_upload_date and yields them' do
        expect { |b| source.each(&b) }.to yield_with_args(alignment)
      end
    end

    context 'when no records are available' do
      before do
        allow(StandardAlignment).to receive(:eager_load)
          .with(:standard, :standard_asset)
          .and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:where).and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:distinct).and_return(StandardAlignment)
        allow(StandardAlignment).to receive(:find_each).with(batch_size: 100) # No yield
      end

      it 'does not yield any records' do
        expect { |b| source.each(&b) }.not_to yield_control
      end
    end
  end
end
