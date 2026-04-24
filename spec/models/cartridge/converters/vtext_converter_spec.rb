describe Cartridge::Converters::VtextConverter do
  include ActiveSupport::Testing::TimeHelpers

  let(:creator) { create(:user) }
  let(:program) { create(:program) }
  let(:vtext_label) { 'vWritings' }
  let(:teacher_vtext_label) { 'Teacher Guidelines' }
  let(:program_settings_hash) do
    {
      settings: [],
      vtext_label: vtext_label,
      teacher_vtext_label: teacher_vtext_label,
      vtext: { url: '/vtext/sentieri2e/book.html' },
      teacher_vtext: { url: '/vtext/teacher/sentieri2e/book.html' }
    }
  end
  let(:no_vtext_settings_hash) do
    {
      settings: []
    }
  end
  let(:program_settings) { ProgramSettings.new(program) }
  let(:converter) { described_class.new(program) }

  describe '#convert' do
    context 'when the program has no vtext' do
      before do
        ProgramConfig.create!(
          no_vtext_settings_hash.merge(
            program_id: program.id,
            creator_id: creator.id
          )
        )
      end

      it 'returns nil' do
        expect(converter.convert).to be_nil
      end
    end

    context 'when the program has vtexts' do
      before do
        ProgramConfig.create!(
          program_settings_hash.merge(
            program_id: program.id,
            creator_id: creator.id
          )
        )
      end

      it 'returns an item' do
        expect(converter.convert).to be_a(MultiVersionCommonCartridge::Item)
      end

      it 'sets the identifier' do
        item = converter.convert
        expect(item.identifier).to start_with('_')
      end

      describe 'when it has only the student vtext' do
        before do
          program_settings_hash.delete(:teacher_vtext)
          travel_to 1.hour.from_now do
            ProgramConfig.create!(
              program_settings_hash.merge(
                program_id: program.id,
                creator_id: creator.id
              )
            )
          end
        end

        it 'creates a resource_link record' do
          expect { converter.convert }.to change(Cartridge::ResourceLink, :count).by(1)
          cartridge_resource_link = Cartridge::ResourceLink.last
          expect(cartridge_resource_link.resource_id).to eq program.id
          expect(cartridge_resource_link.resource_type).to eq 'student_vtext'
        end

        it 'does not create a resource_link record if it exists' do
          create(
            :cartridge_resource_link,
            resource_id: program.id,
            resource_type: 'student_vtext',
            program_id: program.id
          )
          expect { converter.convert }.not_to change(Cartridge::ResourceLink, :count)
        end
      end

      describe 'when it has only the instructor vtext' do
        before do
          program_settings_hash.delete(:vtext)
          travel_to 1.hour.from_now do
            ProgramConfig.create!(
              program_settings_hash.merge(
                program_id: program.id,
                creator_id: creator.id
              )
            )
          end
        end

        it 'creates a resource_link record' do
          expect { converter.convert }.to change(Cartridge::ResourceLink, :count).by(1)
          cartridge_resource_link = Cartridge::ResourceLink.last
          expect(cartridge_resource_link.resource_id).to eq program.id
          expect(cartridge_resource_link.resource_type).to eq 'instructor_vtext'
        end

        it 'does not create a resource_link record if it exists' do
          create(
            :cartridge_resource_link,
            resource_type: :instructor_vtext,
            resource_id: program.id,
            program_id: program.id
          )
          expect { converter.convert }.not_to change(Cartridge::ResourceLink, :count)
        end
      end

      describe 'when it has both student and teacher vtexts' do
        it 'creates two resource_link records' do
          expect { converter.convert }.to change(Cartridge::ResourceLink, :count).by(2)
        end

        it 'does not create the resource_link records if they exists' do
          create(
            :cartridge_resource_link,
            resource_type: :student_vtext,
            resource_id: program.id,
            program_id: program.id
          )
          create(
            :cartridge_resource_link,
            resource_type: :instructor_vtext,
            resource_id: program.id,
            program_id: program.id
          )
          expect { converter.convert }.not_to change(Cartridge::ResourceLink, :count)
        end

        context 'when TechProd did not set a label for the vtexts' do
          let(:program_settings_hash) do
            {
              settings: [],
              vtext_label: '',
              teacher_vtext_label: '',
              vtext: { url: '/vtext/sentieri2e/book.html' },
              teacher_vtext: { url: '/vtext/teacher/sentieri2e/book.html' }
            }
          end

          it 'sets a default vtext label specific for VOL programs' do
            allow(program).to receive(:vista_online_learning?).and_return(true)
            children = converter.convert.children
            expect(children[0].title).to eq 'eCompanion'
            expect(children[1].title).to eq "Instructor's Manual"
          end

          it 'sets a default vtext label specific for non VOL programs' do
            allow(program).to receive(:vista_online_learning?).and_return(false)
            children = converter.convert.children
            expect(children[0].title).to eq 'eCompanion'
            expect(children[1].title).to eq "Teacher's Edition"
          end
        end
      end

      describe 'on its children' do
        let(:children) { converter.convert.children }

        it 'sets an identifier' do
          expect(children[0].identifier).to start_with('_')
          expect(children[1].identifier).to start_with('_')
        end

        it 'sets a title that matches the vtext label' do
          expect(children[0].title).to eq vtext_label
          expect(children[1].title).to eq teacher_vtext_label
        end

        it 'sets a basic lti link' do
          expect(children[0].resource).to be_a(
            MultiVersionCommonCartridge::Resources::BasicLtiLink::BasicLtiLink
          )
          expect(children[1].resource).to be_a(
            MultiVersionCommonCartridge::Resources::BasicLtiLink::BasicLtiLink
          )
        end

        it 'sets the title in the lti resource' do
          expect(children[0].resource.title).to eq vtext_label
          expect(children[1].resource.title).to eq teacher_vtext_label
        end

        it 'sets an empty description in the lti resource' do
          expect(children[0].resource.description).to be_empty
          expect(children[1].resource.description).to be_empty
        end

        it 'sets the secure launch url in the lti resource' do
          expect(children[0].resource.secure_launch_url).to eq(
            URI.join(UA_URL, "cartridge/launches/" \
              "#{Cartridge::ResourceLink.find_by(resource_type: :student_vtext).resource_link_id}"
            ).to_s
          )
          expect(children[1].resource.secure_launch_url).to eq(
            URI.join(UA_URL, "cartridge/launches/" \
              "#{Cartridge::ResourceLink.find_by(resource_type: :instructor_vtext).resource_link_id}"
            ).to_s
          )
        end

        it 'sets the identifier in the lti resource' do
          expect(children[0].resource.identifier).to eq children[0].identifier + '_r'
          expect(children[1].resource.identifier).to eq children[1].identifier + '_r'
        end

        it 'sets the vendor information' do
          expect(children[0].resource.vendor).to have_attributes(
            code: 'Vhl Central',
            name: 'Vista Higher Learning',
            url: 'https://www.vhlcentral.com',
            contact_email: 'contact@vhlcentral.com'
          )
          expect(children[1].resource.vendor).to have_attributes(
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
