describe VtextLinker do
  let(:activity) { build(:activity, page: '2-5') }
  let(:program) { create(:program) }
  let(:user) { build(:student) }
  let!(:program_settings) { ProgramSettings.new(program) }

  before do
    allow(ProgramSettings).to receive(:new).and_return(program_settings)
  end

  describe '#activity_linkable?' do
    let(:vtext_linker) { described_class.new(program, user, activity) }
    let(:access_guardian) { instance_double(AccessGuardian) }

    it 'is false if the program settings do not include a vtext link' do
      allow(program_settings).to receive(:vtext_link).and_return(nil)

      expect(vtext_linker).not_to be_activity_linkable(access_guardian)
    end

    it 'is false if the program settings include a blank vtext link' do
      allow(program_settings).to receive(:vtext_link).and_return('')

      expect(vtext_linker).not_to be_activity_linkable(access_guardian)
    end

    context 'when the program settings include a vtext link,' do
      before do
        allow(program_settings).to receive(:vtext_link).and_return('blah.html')
      end

      it 'is false when an activity has no page numbers' do
        activity.page = nil

        expect(vtext_linker).not_to be_activity_linkable(access_guardian)
      end

      context 'when the access guardian grants access to the vtext ' \
              'for the default program' do
        before do
          allow(access_guardian).to receive(:has_vtext?)
            .with(nil)
            .and_return(true)
        end

        it 'is true when the activity page has no vtext prefix' do
          expect(vtext_linker).to be_activity_linkable(access_guardian)
        end

        it 'is true when the activity page has a vtext prefix of 1' do
          activity.page = 'v1(2-4)'

          expect(vtext_linker).to be_activity_linkable(access_guardian)
        end

        context 'when the activity page has a vtext prefix of 2' do
          before do
            activity.page = 'v2(2-4)'
          end

          it 'is true if there is a teacher vtext' do
            allow(program_settings).to receive(:teacher_vtext_link).and_return(
              'teacher.html'
            )

            expect(vtext_linker).to be_activity_linkable(access_guardian)
          end

          it 'is false if there is no teacher vtext' do
            allow(program_settings).to receive(:teacher_vtext_link).and_return(nil)

            expect(vtext_linker).not_to be_activity_linkable(access_guardian)
          end

          it 'is false if there is a teacher vtext with a blank url' do
            allow(program_settings).to receive(:teacher_vtext_link).and_return('')

            expect(vtext_linker).not_to be_activity_linkable(access_guardian)
          end
        end
      end

      context 'when the access guardian does not grant access to the vtext ' \
              'for the default program' do
        before do
          allow(access_guardian).to receive(:has_vtext?)
            .with(nil)
            .and_return(false)
        end

        it 'is false when the activity page has no vtext prefix' do
          expect(vtext_linker).not_to be_activity_linkable(access_guardian)
        end

        it 'is false when the activity page has a vtext prefix of 1' do
          activity.page = 'v1(2-4)'

          expect(vtext_linker).not_to be_activity_linkable(access_guardian)
        end

        context 'when the activity page has a vtext prefix of 2' do
          before do
            activity.page = 'v2(2-4)'
          end

          it 'is false if there is a teacher vtext' do
            allow(program_settings).to receive(:teacher_vtext_link).and_return(
              'teacher.html'
            )

            expect(vtext_linker).not_to be_activity_linkable(access_guardian)
          end
        end
      end

      context 'when the activity page has a vtext prefix of 3 or higher' do
        before do
          activity.page = 'v3(2-4)'
        end

        it 'is false if there is no additional vtext' do
          allow(program_settings).to receive(:content_menu_additional_entries)
            .and_return([])

          expect(vtext_linker).not_to be_activity_linkable(access_guardian)
        end

        it 'is false if there is an additional vtext with a blank url' do
          allow(program_settings).to receive(:content_menu_additional_entries)
            .and_return([OpenStruct.new(url: '')])

          allow(access_guardian).to receive(:has_vtext?)
            .with(nil)
            .and_return(true)

          expect(vtext_linker).not_to be_activity_linkable(access_guardian)
        end

        context 'when there is an additional vtext with no program id' do
          before do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([OpenStruct.new(url: 'extra.html')])
          end

          it 'is true when the access guardian grants access to the vtext ' \
             'for the default program' do
            allow(access_guardian).to receive(:has_vtext?)
              .with(nil)
              .and_return(true)

            expect(vtext_linker).to be_activity_linkable(access_guardian)
          end

          it 'is false when the access guardian does not grant access to ' \
             'the vtext for the default program' do
            allow(access_guardian).to receive(:has_vtext?)
              .with(nil)
              .and_return(false)

            expect(vtext_linker).not_to be_activity_linkable(access_guardian)
          end
        end

        context 'when there is an additional vtext with a program id' do
          let(:other_program_id) { build_stubbed(:program).id }

          before do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return(
                [OpenStruct.new(program_id: other_program_id, url: 'extra.html')]
              )
          end

          it 'is true when the access guardian grants access to the vtext ' \
             'for the alternate program' do
            allow(access_guardian).to receive(:has_vtext?)
              .with(other_program_id)
              .and_return(true)

            expect(vtext_linker).to be_activity_linkable(access_guardian)
          end

          it 'is false when the access guardian does not grant access to ' \
             'the vtext for the alternate program' do
            allow(access_guardian).to receive(:has_vtext?)
              .with(other_program_id)
              .and_return(false)

            expect(vtext_linker).not_to be_activity_linkable(access_guardian)
          end
        end
      end
    end
  end

  describe '#menu_linkable?' do
    it 'is true if the program settings include a vtext link' do
      allow(program_settings).to receive(:has_vtext_link?).and_return(true)

      vtext_linker = described_class.new(program, user)
      expect(vtext_linker).to be_menu_linkable
    end

    it 'is false if the program settings do not include a vtext link' do
      allow(program_settings).to receive(:has_vtext_link?).and_return(false)

      vtext_linker = described_class.new(program, user)
      expect(vtext_linker).not_to be_menu_linkable
    end
  end

  describe '#link' do
    before do
      allow(program_settings).to receive(:vtext_link).and_return('blah.html')
      allow(program_settings).to receive(:teacher_vtext_link).and_return(
        'teacher.html'
      )
    end

    context 'with a student' do
      let(:user) { create(:student) }

      context 'when the user is in a section' do
        let(:course) { create(:course, program: program) }
        let(:section) { create(:section, course: course) }

        before { user.sections << section }

        it 'returns a link with the rid and no page number with a nil activity' do
          vtext_linker = described_class.new(program, user, nil)
          expect(vtext_linker.link).to eq("blah.html?rid=#{section.id}")
        end

        it 'returns a link with the rid and page number with an activity' do
          vtext_linker = described_class.new(program, user, activity)
          expect(vtext_linker.link).to eq("blah.html?rid=#{section.id}&page=2")
        end
      end

      context 'when the student is not in a section' do
        it 'returns a link with an rid of 0 and the page number' do
          vtext_linker = described_class.new(program, user, activity)
          expect(vtext_linker.link).to eq('blah.html?rid=0&page=2')
        end
      end

      context 'with an activity with an activity_type that is not "link_vtext"' do
        let(:vtext_linker) { described_class.new(program, user, activity) }

        context 'when the activity page has no vtext prefix' do
          it 'returns a url with the default vtext link followed by ' \
             'the first part of the activity page attribute' do
            expect(vtext_linker.link).to eq 'blah.html?rid=0&page=2'
          end
        end

        context 'when the activity page has a vtext prefix of 1' do
          it 'returns a url with the default vtext link followed by ' \
             'the first part of the activity page attribute' do
            activity.page = 'v1(2-4)'

            expect(vtext_linker.link).to eq 'blah.html?rid=0&page=2'
          end
        end

        context 'when the activity page has a vtext prefix of 2' do
          it 'returns a url with the default teacher vtext link followed by ' \
             'the first part of the activity page attribute' do
            activity.page = 'v2(2-4)'

            expect(vtext_linker.link).to eq 'teacher.html?rid=0&page=2'
          end
        end

        context 'when the activity page has a vtext prefix of 3 or higher' do
          before do
            activity.page = 'v3(2-4)'
          end

          it 'returns a url with the additional content menu entry url ' \
             'with an index of the vtext prefix minus 3 if one exists' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([OpenStruct.new(url: 'extra.html')])

            expect(vtext_linker.link).to eq 'extra.html?rid=0&page=2'
          end

          it 'returns an empty string if no additional content menu entry url ' \
             'with an index of the vtext prefix minus 3 exists' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([])

            expect(vtext_linker.link).to eq('')
          end

          it 'returns an empty string if an additional content menu entry with ' \
             'an index of the vtext prefix minus 3 exists with a blank url' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([OpenStruct.new(url: '')])

            expect(vtext_linker.link).to eq('')
          end
        end
      end

      context 'with an activity with activity_type "link_vtext"' do
        let(:module_prefix) { MaestroActivityEngine::ActivityContent }
        let(:link_vtext_class) { module_prefix::LinkVtext::LinkVtext }
        let(:link_vtext) { instance_double(link_vtext_class, page: '2') }
        let(:vtext_linker) { described_class.new(program, user, activity) }
        let(:content_object_class) { module_prefix::LinkVtextContent }

        before do
          allow(activity).to receive(:activity_type).and_return('link_vtext')
          allow(activity).to receive(:content_object).and_return(
            instance_double(content_object_class, link_vtext: link_vtext)
          )
        end

        context 'when the link_vtext page has no vtext prefix' do
          it 'returns a url with the default vtext link followed by ' \
             'the first part of the link_vtext page attribute' do
            expect(vtext_linker.link).to eq 'blah.html?rid=0&page=2'
          end
        end

        context 'when the link_vtext page has a vtext prefix of 1' do
          it 'returns a url with the default vtext link followed by ' \
             'the first part of the link_vtext page attribute' do
            allow(link_vtext).to receive(:page).and_return('v1(2-4)')

            expect(vtext_linker.link).to eq 'blah.html?rid=0&page=2'
          end
        end

        context 'when the link_vtext page has a vtext prefix of 2' do
          it 'returns a url with the default teacher vtext link followed by ' \
             'the first part of the link_vtext page attribute' do
            allow(link_vtext).to receive(:page).and_return('v2(2-4)')

            expect(vtext_linker.link).to eq 'teacher.html?rid=0&page=2'
          end
        end

        context 'when the link_vtext page has a vtext prefix of 3 or higher' do
          before do
            allow(link_vtext).to receive(:page).and_return('v3(2-4)')
          end

          it 'returns a url with the additional content menu entry url ' \
             'with an index of the vtext prefix minus 3 if one exists' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([OpenStruct.new(url: 'extra.html')])

            expect(vtext_linker.link).to eq 'extra.html?rid=0&page=2'
          end

          it 'returns an empty string if no additional content menu entry url ' \
             'with an index of the vtext prefix minus 3 exists' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([])

            expect(vtext_linker.link).to eq('')
          end

          it 'returns an empty string if an additional content menu entry with ' \
             'an index of the vtext prefix minus 3 exists with a blank url' do
            allow(program_settings).to receive(:content_menu_additional_entries)
              .and_return([OpenStruct.new(url: '')])

            expect(vtext_linker.link).to eq('')
          end
        end
      end
    end

    context 'with an instructor' do
      before do
        allow(activity).to receive(:activity_type).and_return('multiple_choice')
      end

      let(:user) { create(:instructor) }

      it 'returns a link with an rid of 0 and no page number with a nil activity' do
        vtext_linker = described_class.new(program, user, nil)

        expect(vtext_linker.link).to eq('blah.html?rid=0')
      end

      it 'returns a link with the page number and an rid of 0' do
        vtext_linker = described_class.new(program, user, activity)

        expect(vtext_linker.link).to eq('blah.html?rid=0&page=2')
      end
    end
  end

  describe '#link_label' do
    let(:user) { create(:instructor) }

    it 'returns the overriden configuration for the vText label if present' do
      program_setting = instance_double(ProgramSettings, vtext_label: 'vWritings')
      program = build(:program)

      allow(ProgramSettings).to receive(:new).and_return(program_setting)

      vtext_linker = described_class.new(program, user, activity)

      expect(vtext_linker.link_label).to eq program_setting.vtext_label
    end

    context 'when no overriden configuration has been set for the vText label' do
      let(:vtext_configuration) { OpenStruct.new }
      let(:program) { build(:program) }
      before do
        allow(ProgramSettings).to receive(:new).and_return(
          instance_double(ProgramSettings, vtext_label: nil, vtext: vtext_configuration)
        )
      end

      it 'returns the expected label if the textbook type has been set explicitly' do
        expected_label = 'eCompanion'
        vtext_configuration.type = expected_label
        vtext_linker = described_class.new(program, user, activity)

        expect(vtext_linker.link_label).to eq expected_label
      end

      it 'returns vText when no virtual textbook type has been set' do
        vtext_linker = described_class.new(program, user, activity)

        expect(vtext_linker.link_label).to eq 'vText'
      end
    end
  end
end
