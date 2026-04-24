RSpec.shared_examples 'school sharing content for program' do
  context 'when the school does not have school_config' do
    let(:school_config) { nil }

    it { expect(school.sharing_content_for_program?(347)).to be true }
  end

  context 'when the school have school_config' do
    let(:school_config) { build_stubbed(:school_config) }

    context 'when the school is allowed to share content' do
      before { school_config.school_content_sharing = true }

      context 'when there is no configuration for the program' do
        before { school_config.program_content_sharing_json = {} }

        it { expect(school.sharing_content_for_program?(347)).to be true }
      end

      context 'when there is a false configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = false }

        it { expect(school.sharing_content_for_program?(347)).to be false }
      end

      context 'when there is a true configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = true }

        it { expect(school.sharing_content_for_program?(347)).to be true }
      end
    end

    context 'when school is not allowed to share content' do
      before { school_config.school_content_sharing = false }

      context 'when there is no configuration for the program' do
        before { school_config.program_content_sharing_json = {} }

        it { expect(school.sharing_content_for_program?(347)).to be false }
      end

      context 'when there is a false configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = false }

        it { expect(school.sharing_content_for_program?(347)).to be false }
      end

      context 'when there is a true configuration for the program' do
        before { school_config.program_content_sharing_json['347'] = true }

        it { expect(school.sharing_content_for_program?(347)).to be false }
      end
    end
  end
end
