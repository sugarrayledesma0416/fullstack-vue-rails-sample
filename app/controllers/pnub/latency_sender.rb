module Pnub
  module LatencySender
    def send_latency_stats(user)
      @grants.each do |grant|
        unless grant.grant_latency.nil?
          # logstash
          data = {user_id: user.id,
                  user_type: user.base_account_type,
                  event: grant.grant_type,
                  latency: { duration: grant.grant_latency },
                  service: 'pubnub' }

          grant.dispatch(payload: data,
                         stats_index: 'vhl-chat-server-pubnub',
                         stats_type: grant.grant_type)

          # datadog
          metric = "chat.pubnub_grants.#{grant.grant_type}.latency"
          grant.ddog_dispatch(metric: metric,
                              stats_type: :gauge,
                              role: 'live_chat',
                              value: grant.grant_latency)
        end
      end
    end
  end
end
