describe SchoolConfig do
  describe 'after save callback' do
    let(:school) { create(:school) }

    context 'when disabling chat support' do
      let(:school_config) { described_class.new(school:, chat_support_disabled: true) }

      it 'disables chat of the open courses in the school' do
        course = create(:open_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_truthy
      end

      it 'does not disable chat of the closed courses in the school' do
        course = create(:closed_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end

      it 'does not disable chat of the editable courses in the school' do
        course = create(:editable_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end

      it 'does not disable chat of the archived courses in the school' do
        course = create(:archived_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end
    end

    context 'when enabling chat support' do
      let(:school_config) { described_class.new(school:, chat_support_disabled: false) }

      it 'does not disable chat of the open courses in the school' do
        course = create(:open_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end

      it 'does not disable chat of the closed courses in the school' do
        course = create(:closed_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end

      it 'does not disable chat of the editable courses in the school' do
        course = create(:editable_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end

      it 'does not disable chat of the archived courses in the school' do
        course = create(:archived_course, school:, chat_level: 'partner_chat')

        school_config.save

        expect(course.reload.chat_disabled?).to be_falsey
      end
    end
  end

  describe 'content sharing field validations' do
    subject(:school_config) { build_stubbed(:school_config, school:) }

    let(:school) { build_stubbed(:school) }

    describe '#school_content_sharing' do
      context 'when is a nil value' do
        before { school_config.school_content_sharing = nil }

        it { expect(school_config).not_to be_valid }
      end

      context 'when is a true value' do
        before { school_config.school_content_sharing = true }

        it { expect(school_config).to be_valid }
      end

      context 'when is a false value' do
        before { school_config.school_content_sharing = false }

        it { expect(school_config).to be_valid }
      end
    end

    describe '#program_content_sharing_json' do
      context 'when is not a hash value' do
        before { school_config.program_content_sharing_json = 'invalid_json' }

        it { expect(school_config).not_to be_valid }
      end

      context 'when is a nil value' do
        before { school_config.program_content_sharing_json = nil }

        it { expect(school_config).to be_valid }
      end

      context 'when is an empty hash value' do
        before { school_config.program_content_sharing_json = {} }

        it { expect(school_config).to be_valid }
      end

      context 'when the hash contains a valid key and value' do
        before { school_config.program_content_sharing_json['347'] = true }

        it { expect(school_config).to be_valid }
      end

      context 'when the hash contains an invalid key' do
        before { school_config.program_content_sharing_json['invalid'] = true }

        it { expect(school_config).not_to be_valid }
      end

      context 'when the hash contains an invalid value' do
        before { school_config.program_content_sharing_json['347'] = 'invalid' }

        it { expect(school_config).not_to be_valid }
      end

      context 'when the school is a district' do
        let(:school) { build_stubbed(:district) }

        before { school_config.program_content_sharing_json['347'] = true }

        it { expect(school_config).not_to be_valid }
      end
    end
  end
end
