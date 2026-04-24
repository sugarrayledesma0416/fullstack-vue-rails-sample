describe Cartridge::ResourceLink do
  let!(:resource_link) { create(:cartridge_resource_link) }

  describe '.validations' do
    it 'requires a valid resource type' do
      resource_link = build(:cartridge_resource_link, resource_type: 'assessment')
      expect(resource_link).not_to be_valid
      expect(resource_link.errors.full_messages).to include 'Resource type assessment is not valid resource type'
    end
  end

  describe '.find_by_resource_link_id' do
    it 'retrieves resource link instance' do
      expect(described_class.find_by_resource_link_id(resource_link.resource_link_id))
        .to eq resource_link
    end

    it 'returns nil if resource link instance does not exist' do
      resource_link = build(:cartridge_resource_link)
      expect(described_class.find_by_resource_link_id(resource_link.resource_link_id)).to be nil
    end
  end

  describe '.find_or_create' do
    let(:resource_id) { SecureRandom.random_number(100..900_000) }
    let(:resource_type) { 'resource' }
    let!(:program) { create(:program) }

    it 'creates a new resource_link' do
      expect do
        described_class.find_or_create(resource_id, resource_type, program)
      end.to change(described_class, :count).by(1)
      expect(described_class.last).to have_attributes(
        resource_id: resource_id,
        resource_type: resource_type
      )
    end

    it 'retrieves an existing resource_link' do
      new_rl = described_class.find_or_create(resource_id, resource_type, program)
      expect do
        described_class.find_or_create(new_rl.resource_id, new_rl.resource_type, new_rl.program)
      end.not_to change(described_class, :count)
      expect(Cartridge::ResourceLink.last).to eq new_rl
    end
  end

  describe '#url' do
    let!(:resource) { create(:resource) }
    let(:expected_signed_url) { 'http://example.com/signed_url' }
    let(:link_vtext_activity_link) { '//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2?rid=977211&page=12' }
    let(:instructor_dsl_reader_link) { '//reader.vhlcentral.com/portales1e/teacher-edition/vol1_ecompanion-v2' }
    let(:instructor_dsl_reader2_link) { '//reader2.vhlcentral.com/portales1e/teacher-edition/vol1_ecompanion-v2' }
    let(:student_dsl_reader_link) { '//reader.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext' }
    let(:student_dsl_reader2_link) { '//reader2.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext' }
    let(:student_dsl_reader3_link) { '//reader3.vhlcentral.com/portales1e/student-edition/vol1_ecompanion-v2_vtext' }
    let(:student_ecompanion_reader_link) { '//reader.vhlcentral.com/portales1e/ecompanion/vol1_ecompanion-v2_ecompanion' }
    let(:student_ecompanionv2_reader_link) { '//reader2.vhlcentral.com/portales1e/ecompanionv2/vol1_ecompanion-v2_vtext' }
    let(:student_ecompanion_reader3_link) { '//reader3.vhlcentral.com/portales1e/ecompanion/vol1_ecompanion-v2_ecompanion' }
    let(:activity) { create(:activity) }
    let(:link_vtext_activity) { create(:activity, activity_type: 'link_vtext') }
    let(:activity_resource_link) { create(:cartridge_resource_link, resource_id: activity.id, resource_type: 'activity') }
    let(:downloadable_resource_resource_link) do
      create(:cartridge_resource_link,
             resource_id: resource.id,
             resource_type: 'resource')
    end
    let(:student_vtext_resource_link) { create(:cartridge_resource_link, resource_type: 'student_vtext') }
    let(:instructor_vtext_resource_link) { create(:cartridge_resource_link, resource_type: 'instructor_vtext') }
    let(:link_vtext_activity_resource_link) { create(:cartridge_resource_link, resource_id: link_vtext_activity.id, resource_type: 'activity') }
    let!(:user) { create(:user) }
    let!(:course) { create(:course) }
    let!(:section) { create(:section, course: course) }

    before do
      allow(user).to receive(:downloadable_resource).with(resource.id, section.course.program, section).and_return(resource)
      allow(resource).to receive(:signed_url).and_return(expected_signed_url)
      allow_any_instance_of(VtextLinker).to receive(:link).and_return(link_vtext_activity_link)
      allow_any_instance_of(ProgramSettings).to receive(:vtext_link).and_return(student_dsl_reader_link)
      allow_any_instance_of(ProgramSettings).to receive(:teacher_vtext_link).and_return(instructor_dsl_reader_link)
    end

    it 'produces the url to access an activity' do
      url_regexp = %r{\/cartridge\/sections\/\d+\/activities\/\d+$}
      expect(activity_resource_link.url(user, section) =~ url_regexp).not_to be_nil
    end

    it 'produces the url to access a link_vtext activity' do
      expect(link_vtext_activity_resource_link.url(user, section)).to eq link_vtext_activity_link
    end

    it 'produces the url to download a resource' do
      expect(downloadable_resource_resource_link.url(user, section)).to eq expected_signed_url
    end

    it 'produces the url that opens the student flat ecompanion edition of the program vtext' do
      expect(student_vtext_resource_link.url(user, section)).to eq student_ecompanion_reader_link
    end

    context 'when the program setting has vtext_link with reader2 domain' do
      before do
        allow(ProgramSettings).to receive(:new).and_return(
          instance_double(
            ProgramSettings,
            vtext_link: student_dsl_reader2_link
          )
        )
      end

      it 'produces the url that opens the student flat ecompanion edition' \
         'of the program vtext with reader domain' do
        expect(student_vtext_resource_link.url(user, section)).to eq(
          student_ecompanionv2_reader_link
        )
      end
    end

    it 'produces the url that opens the instructor edition vtext of the program' do
      expect(instructor_vtext_resource_link.url(user, section)).to eq instructor_dsl_reader_link
    end

    context 'when the program setting has vtext_link with reader2 domain' do
      before do
        allow(ProgramSettings).to receive(:new).and_return(
          instance_double(
            ProgramSettings,
            vtext_link: student_dsl_reader2_link
          )
        )
      end

      it 'produces the url that opens the student flat ecompanion edition' \
         'of the program vtext with reader domain' do
        expect(student_vtext_resource_link.url(user, section)).to eq student_ecompanionv2_reader_link
      end
    end

    context 'when the program setting has vtext_link with reader3 domain' do
      before do
        allow(ProgramSettings).to receive(:new).and_return(
          instance_double(
            ProgramSettings,
            vtext_link: student_dsl_reader3_link
          )
        )
      end

      it 'produces the url that opens the student flat ecompanion edition' \
         'of the program vtext with reader3 domain' do
        expect(student_vtext_resource_link.url(user, section)).to eq student_ecompanion_reader3_link
      end
    end

    context 'when the program has vital source vtexts' do
      let(:student_dsl_reader_link) { '//vtext-cdn.vhlcentral.com/vtext_facetas4e/book.html' }

      it 'returns the vtext link without any changes' do
        expect(student_vtext_resource_link.url(user, section)).to eq student_dsl_reader_link
      end
    end

    context 'when the user is an instructor and the reader domain is reader2' do
      before do
        allow(ProgramSettings).to receive(:new).and_return(
          instance_double(
            ProgramSettings,
            teacher_vtext_link: instructor_dsl_reader2_link
          )
        )
      end

      it 'converts the reader2 domain to reader3' do
        expect(instructor_vtext_resource_link.url(user, section)).to eq(
          '//reader3.vhlcentral.com/portales1e/teacher-edition/vol1_ecompanion-v2'
        )
      end
    end
  end
end
