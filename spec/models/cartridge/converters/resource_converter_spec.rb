describe Cartridge::Converters::ResourceConverter do
  let(:sanitized_title) { 'sanitized title' }
  let(:resource) { create(:resource) }
  let(:converter) { described_class.new(resource) }

  before do
    allow(converter).to receive(:sanitize_title)
      .with(resource.title).and_return(sanitized_title)
  end

  describe '#convert' do
    it 'returns an item' do
      expect(converter.convert).to be_a(MultiVersionCommonCartridge::Item)
    end

    describe 'the result item' do
      let(:item) { converter.convert }

      it 'creates a resource_link record' do
        expect { item }.to change(Cartridge::ResourceLink, :count).by(1)

        expect(Cartridge::ResourceLink.last).to have_attributes(
          resource_id: resource.id,
          resource_type: 'resource',
          program_id: resource.program.id
        )
      end

      context 'when a resource_link already exists for this resource,' do
        it 'does not create any resource_link record' do
          create(
            :cartridge_resource_link,
            resource_type: :resource,
            resource_id: resource.id,
            program_id: resource.program.id
          )
          expect { item }.not_to change(Cartridge::ResourceLink, :count)
        end
      end

      it 'sanitizes and sets the title' do
        expect(item.title).to eq(sanitized_title)
      end

      it 'sets the identifier' do
        expect(item.identifier).to start_with('_')
      end

      it 'sets a basic lti link resource' do
        expect(item.resource).to be_a(
          MultiVersionCommonCartridge::Resources::BasicLtiLink::BasicLtiLink
        )
      end

      describe 'the basic lti link resource' do
        let(:basic_lti_resource) { item.resource }

        it 'sets the same title as the item title' do
          expect(basic_lti_resource.title).to eq(item.title)
        end

        it 'sets the identifier' do
          expect(basic_lti_resource.identifier).to eq(item.identifier + '_r')
        end

        it 'sets an empty description' do
          expect(basic_lti_resource.description).to be_empty
        end

        it 'sets the secure launch url' do
          expect(basic_lti_resource.secure_launch_url).to eq(
            URI.join(UA_URL, "/cartridge/launches/" \
              "#{Cartridge::ResourceLink.last.resource_link_id}"
            ).to_s
          )
        end

        it 'sets the vendor information' do
          expect(basic_lti_resource.vendor).to have_attributes(
            code: 'Vhl Central',
            name: 'Vista Higher Learning',
            url: 'https://www.vhlcentral.com',
            contact_email: 'contact@vhlcentral.com'
          )
        end
      end
    end
  end
end
