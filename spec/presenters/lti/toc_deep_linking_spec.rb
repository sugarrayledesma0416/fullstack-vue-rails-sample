describe Lti::TocDeepLinking do
  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }
  let(:deep_link_return_url) { 'https://lms.example.com/deep_link/return_url' }

  let(:launch) do
    create(
      :deep_linking_lti_launch,
      deep_linking_settings: { deep_link_return_url: }
    )
  end

  # Define an anonymous class that includes the module under test and has
  # the methods required to be implemented when it is included.
  let(:test_class) do
    Class.new do
      include Lti::TocDeepLinking

      attr_accessor :session

      def initialize(session)
        self.session = session
      end
    end
  end

  let(:default_session) do
    {
      lti_deep_link_launch_guid: launch.guid,
      lti_launch_expiration: 1.minute.from_now.to_i
    }
  end

  def create_instance(extra_session_args = {})
    test_class.new(
      default_session.merge(extra_session_args)
    )
  end

  describe '#launch_guid' do
    it 'returns nil if there is no launch_guid in the session' do
      expect(
        create_instance(lti_deep_link_launch_guid: nil).launch_guid
      ).to be_nil
    end

    it 'returns the launch_guid from the session if it is set' do
      expect(
        create_instance(lti_deep_link_launch_guid: launch.guid).launch_guid
      ).to eq(launch.guid)
    end
  end

  describe '#lti_deep_link_enabled?' do
    it 'is false if session has no lti deep link keys' do
      expect(test_class.new({})).not_to be_lti_deep_link_enabled
    end

    context 'when the session has an :lti_launch_expiration in the future' do
      let(:default_session) { { lti_launch_expiration: 1.minute.from_now.to_i } }

      it 'is false if session has no :lti_deep_link_launch_guid key' do
        expect(create_instance({})).not_to be_lti_deep_link_enabled
      end

      it 'is false if session has a nil value for :lti_deep_link_launch_guid' do
        expect(
          create_instance(lti_deep_link_launch_guid: nil)
        ).not_to be_lti_deep_link_enabled
      end

      it 'is false if there is no Lti::Launch record with a guid matching ' \
         'the :lti_deep_link_launch_guid of the session' do
        expect(
          create_instance(lti_deep_link_launch_guid: 'invalid_guid')
        ).not_to be_lti_deep_link_enabled
      end

      it 'is true if there is an Lti::Launch record with a guid matching ' \
         'the :lti_deep_link_launch_guid of the session' do
        expect(
          create_instance(lti_deep_link_launch_guid: launch.guid)
        ).to be_lti_deep_link_enabled
      end
    end

    context 'with a valid :lti_deep_link_launch_guid in the session' do
      let(:default_session) { { lti_deep_link_launch_guid: launch.guid } }

      it 'is false if session has an :lti_launch_expiration in the past' do
        expect(
          create_instance(lti_launch_expiration: 1.minute.ago.to_i)
        ).not_to be_lti_deep_link_enabled
      end
    end
  end

  describe '#lti_deep_link_return_url' do
    it 'returns the deep_link_return_url of the launch' do
      expect(
        create_instance.lti_deep_link_return_url
      ).to eq(deep_link_return_url)
    end
  end
end
