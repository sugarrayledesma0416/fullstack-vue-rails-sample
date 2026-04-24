describe StandardsMapping::StandardsProcessor do
  let(:standard_processor) { described_class.new }
  let(:one_standard_processor) { described_class.new }

  before do
    standards_call = Rails.root.join('spec/fixtures/json/standards.json').read
    standards_call_empty = Rails.root.join('spec/fixtures/json/standards_empty.json').read
    one_standard_call = Rails.root.join('spec/fixtures/json/one_standard.json').read

    allow(standard_processor.ab_client).to(
      receive(:fetch_all_standards)
      .with(0, 100)
      .and_return(JSON.parse(standards_call))
    )

    allow(standard_processor.ab_client).to(
      receive(:fetch_all_standards)
      .with(10, 10)
      .and_return(JSON.parse(standards_call_empty))
    )

    allow(one_standard_processor.ab_client).to(
      receive(:fetch_all_standards)
      .with(0, 100)
      .and_return(JSON.parse(one_standard_call))
    )

    allow(one_standard_processor.ab_client).to(
      receive(:fetch_all_standards)
      .with(10, 10)
      .and_return(JSON.parse(standards_call_empty))
    )
  end

  describe '#save_process' do
    it 'saves all of the standards it receives' do
      standard_processor.save_process

      expect(Standard.all.count).to eq 10
      expect(StandardSet.all.count).to eq 3

      standard_processor.standards.each do |standard|
        attributes = standard['attributes']
        document = standard['attributes']['document']

        ancestors = standard['relationships']['ancestors']['data'].map do |data|
          data['id']
        end.join(',')

        children = standard['relationships']['children']['data'].map do |data|
          data['id']
        end.join(',')

        additional_info = {
          additional_info: {
            ancestors: ancestors,
            children: children,
            grade_levels: attributes['education_levels']['grades'].map { |grade| grade['code'] }.join(','),
            parent_guid: standard['relationships']['parent']['data']['id']
          }
        }

        expect(Standard.where(
          vendor_guid: attributes['guid'] || '',
          vendor_standard_set_guid: document['guid'] || '',
          name: document['descr'] || '',
          description: attributes['statement']['descr'] || '',
          label: attributes['label'] || '',
          number: attributes['number']['enhanced'] || '',
          additional_info: additional_info.to_json
        ).count).to eq 1

        expect(StandardSet.where(vendor_guid: document['guid']).count).to eq 1
      end
    end

    it 'updates any existing standards it receives' do
      # first value for guid in the file standards_call;
      # create an existing Standard for that guid, using defaults from factory
      standard = create(:standard, vendor_guid: '0030B561-DA3A-4168-BAC6-8E529E0E55B9')
      orig_std_name = standard.name
      standard_processor.save_process
      # it identifies the existing standard
      expect(Standard.all.count).to eq 10
      standard.reload
      # standard should have the values from the file
      expect(standard.name).to_not be orig_std_name
      expect(standard.name).to eq('English Language Arts')
    end

    it 'returns failure message when save standard was not successful' do
      standard = create(:standard)
      allow(Standard).to receive(:new).and_return(standard)
      allow(Rails.logger).to receive(:error)
      allow(standard).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)

      one_standard_processor.save_process

      expect(Rails.logger).to have_received(:error)
        .with(
          "Standard with guid: #{one_standard_processor.standards.first['attributes']['guid']}" \
          ' could not be saved.'
        )
    end

    it 'returns a failure message when there is a validation error' do
      standard = create(:standard)
      allow(Standard).to receive(:new).and_return(standard)
      allow(Rails.logger).to receive(:error)
      allow(standard).to receive(:save!).and_raise(
        ActiveRecord::RecordInvalid
      )

      one_standard_processor.save_process

      expect(Rails.logger).to have_received(:error)
        .with(
          "Standard with guid: #{one_standard_processor.standards.first['attributes']['guid']}" \
          ' has an error. Record invalid'
        )
    end

    it 'returns failure message when save standard set was not successful' do
      standard_set = create(:standard_set)
      allow(StandardSet).to receive(:new).and_return(standard_set)
      allow(Rails.logger).to receive(:error)
      allow(standard_set).to receive(:save!).and_raise(ActiveRecord::RecordNotSaved)

      one_standard_processor.save_process

      expect(Rails.logger).to have_received(:error)
        .with(
          "Standard set with guid: #{one_standard_processor.standards.first['attributes']['document']['guid']}" \
          ' could not be saved.'
        )
    end

    it 'returns a failure message when there is a validation error' do
      standard_set = create(:standard_set)
      allow(StandardSet).to receive(:new).and_return(standard_set)
      allow(Rails.logger).to receive(:error)
      allow(standard_set).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

      one_standard_processor.save_process

      expect(Rails.logger).to have_received(:error)
        .with(
          "Standard set with guid: #{one_standard_processor.standards.first['attributes']['document']['guid']}" \
          ' has an error. Record invalid'
        )
    end
  end
  context ' modification of standards\' numbers and descriptions, post AB pull' do
    let(:std_set_guid) { SecureRandom.uuid }
    let!(:std_set) { create(:standard_set, vendor_guid: std_set_guid) }
    let(:top_level_standard_guid) { SecureRandom.uuid }
    let(:parent_standard_guid) { SecureRandom.uuid }
    let(:child_standard_1_guid) { SecureRandom.uuid }
    let(:child_standard_2_guid) { SecureRandom.uuid }
    let(:next_level_child_standard_1_guid) { SecureRandom.uuid }
    let(:next_level_child_standard_2_guid) { SecureRandom.uuid }

    let(:top_level_add_info) do
      JSON.generate({
                      additional_info:
                        {
                          ancestors: '',
                          parent_guid: '',
                          children: parent_standard_guid
                        }
                    })
    end
    let(:parent_add_info) do
      JSON.generate({
                      additional_info:
                        {
                          ancestors: '',
                          parent_guid: top_level_standard_guid,
                          children: "#{child_standard_1_guid},#{child_standard_2_guid}"
                        }
                    })
    end

    let(:child_level_1_add_info) do
      JSON.generate({
                      additional_info:
                        {
                          ancestors: "#{parent_standard_guid}",
                          grade_levels: '',
                          parent_guid: parent_standard_guid,
                          children: "#{next_level_child_standard_1_guid},#{next_level_child_standard_2_guid}"
                        }
                    })
    end

    let(:child_level_2_add_info) do
      JSON.generate({
                      additional_info:
                        {
                          ancestors: "#{child_standard_1_guid}",
                          grade_levels: '',
                          parent_guid: child_standard_1_guid,
                          children: ''
                        }
                    })
    end

    let!(:top_level_std) do
      create(:standard,
             vendor_guid: top_level_standard_guid,
             number: 'Top Level Standard',
             description: 'Top Level Standard description',
             additional_info: top_level_add_info,
             vendor_standard_set_guid: std_set_guid)
    end
    let!(:parent_std) do
      create(:standard,
             vendor_guid: parent_standard_guid,
             number: 'Standard 6',
             description: 'Standard 6 parent description',
             additional_info: parent_add_info,
             vendor_standard_set_guid: std_set_guid)
    end
    let!(:child_standard_1) do
      create(:standard,
             vendor_guid: child_standard_1_guid,
             number: '',
             description: 'Unnumbered child 1 level 1 description',
             additional_info: child_level_1_add_info,
             vendor_standard_set_guid: std_set_guid)
    end
    let!(:child_standard_2) do
      create(:standard,
             vendor_guid: child_standard_2_guid,
             number: '',
             description: 'Unnumbered child 2 level 1 description',
             additional_info: child_level_1_add_info,
             vendor_standard_set_guid: std_set_guid)
    end

    let!(:next_level_child_standard_1) do
      create(:standard,
             vendor_guid: next_level_child_standard_1_guid,
             number: '',
             description: 'Unnumbered child 1 level 2 description',
             additional_info: child_level_2_add_info,
             vendor_standard_set_guid: std_set_guid)
    end
    let!(:next_level_child_standard_2) do
      create(:standard,
             vendor_guid: next_level_child_standard_2_guid,
             number: '',
             description: 'Unnumbered child 2 level 2 description',
             additional_info: child_level_2_add_info,
             vendor_standard_set_guid: std_set_guid)
    end

    describe '#number_standards' do
      it 'numbers all of the unnumbered standards 1 level down' do
        standard_processor.number_standards(std_set_guid)
        expect(child_standard_1.reload.number).to eql 'Standard 6.1'
        expect(child_standard_2.reload.number).to eql 'Standard 6.2'
      end

      it 'numbers all of the unnumbered standards 2 levels down' do
        standard_processor.number_standards(std_set_guid)
        expect(next_level_child_standard_1.reload.number).to eql 'Standard 6.1.1'
        expect(next_level_child_standard_2.reload.number).to eql 'Standard 6.1.2'
      end
    end

    describe '#prepend_parent_description' do
      it 'prepends the parent description onto the first level of children, if the parent\'s number ends in a character' do
        standard_processor.prepend_parent_description(std_set_guid)
        expect(parent_std.reload.description).to eql 'Top Level Standard description standard 6 parent description'
      end

      it 'does not affect the descriptions of the children on the next level' do
        standard_processor.prepend_parent_description(std_set_guid)
        expect(child_standard_1.reload.description).to eql 'Unnumbered child 1 level 1 description'
      end
    end

    describe '#append_leaf_node_descriptions' do
      it 'appends the descriptions of the leaf node children to the parent description' do
        standard_processor.append_leaf_node_descriptions(std_set_guid)
        expect(child_standard_1.reload.description).to eql 'Unnumbered child 1 level 1 description through: unnumbered child 1 level 2 description; unnumbered child 2 level 2 description.'
      end

      it 'sets the leaf node children to unsearchable' do
        searchable = next_level_child_standard_1.searchable
        standard_processor.append_leaf_node_descriptions(std_set_guid)
        expect(next_level_child_standard_1.reload.searchable).to eql !searchable
      end

      it 'does not change the description or the searchable flag of nodes with children' do
        searchable = top_level_std.searchable
        standard_processor.append_leaf_node_descriptions(std_set_guid)
        expect(top_level_std.reload.description).to eql 'Top Level Standard description'
        expect(top_level_std.reload.searchable).to eql searchable
      end
    end
  end
end
