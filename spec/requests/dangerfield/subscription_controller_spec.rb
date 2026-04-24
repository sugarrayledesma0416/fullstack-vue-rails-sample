describe Dangerfield::SubscriptionController do
  describe 'POST /dispatch_messages', new_gb_sync: true do
    let(:platform) { create(:lti_platform) }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, owner: instructor) }
    let(:section) { create(:section, course: course, instructor: instructor) }
    let(:context_link) do
      create(:lti_context_link, lti_platform: platform, section: section)
    end

    it 'removes context link records from the gradebook when a context link ' \
       'deletion payload is posted' do
      Dangerfield.configure do |dangerfield|
        dangerfield.sns_topics_config = Rails.root.join('config', 'aws_sns_subscribers.yml')
      end
      # puts Dangerfield.configuration.sns_topics_config.inspect

      payload = {
        Message: JSON.dump(
          {
            rostering_action: 'delete',
            object: {
              id: 4,
              deployment_id: 'D5F*$zr8DD#E#HdM',
              context_id: '1',
              context_label: 'Test Course 1',
              context_title: 'Course 1',
              line_items_url: nil,
              guid: context_link.guid,
              sync_token: 1600454242482,
              request_id: '37aa1ca8-31a0-4110-bfbf-e89572dc7b16',
              created_at: '2020-03-23T16:58:25.000Z',
              updated_at: '2020-09-18T18:36:36.000Z',
              platform_type: 'Canvas',
              lti_platform_guid: platform.guid,
              section_guid: section.guid
            },
            outbound_timestamp: 1600454242.552795,
            inbound_timestamp: nil
          }
        ),
        MessageId: '35477b2b-4e2d-4366-9511-fd31c3ef71e4',
        Signature: '',
        SignatureVersion: '1',
        SigningCertURL: '',
        Subject: nil,
        Timestamp: '2020-09-18T15:37:22.568-0300',
        TopicArn: 'arn:cmb:cns:csv:494865605733:lti_context_link',
        Type: 'Notification',
        UnSubscribeURL: 'http://localhost:6061/?Action=Unsubscribe&SubscriptionArn=arn:cmb:cns:csv:494865605733:development_a_mac_2_local_lti_context_link:7fb3073f-eb78-3026-91e5-cd1e170df4ff'
      }

      post(
        '/dangerfield/inbox',
        headers: {
          'CONTENT_TYPE' => 'application/json',
          'RAW_POST_DATA' => JSON.dump(payload)
        }
      )

      expect(Lti::ContextLink.where(id: context_link.id)).not_to exist
      expect(GradebookEngine::Lti::ContextLink.where(id: context_link.id)).not_to exist
    end
  end
end
