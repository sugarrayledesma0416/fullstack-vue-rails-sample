class Session < ApplicationRecord
  validate :not_stale,  on: :update

  belongs_to :user

  scope :expired_sessions, lambda { where(['updated_at < ?', "#{M3::Application.config.m3_session.ttl.days.ago}"]) }

  def self.log(user, session, request)
    Session.create( {
      user_id: user.id,
      service_ticket: session[:service_ticket],
      session_id: session[:session_id],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    })
  end

  def lazy_touch
    touch if touchable?
  end

  def invalidate_ticket_and_destroy(connection = nil)
    begin
      TicketInvalidator.new(self.service_ticket, connection).delete if self.service_ticket
    ensure
      destroy
    end
  end

  def touchable?
    (( self.updated_at || self.created_at )< M3::Application.config.m3_session.ttl_update_interval.hours.ago)
  end
  private :touchable?

  def not_stale
    errors.add(:base, "Session ID is stale.") if stale?
  end
  private :not_stale

  def stale?
   return false if self.new_record?
   ( Date.today - self.updated_at.to_date ) > M3::Application.config.m3_session.ttl
  end
  private :stale?

  class TicketInvalidator
    attr_reader :service_ticket

    def initialize(st, connection = nil)
      @service_ticket = st
      @connection = connection
    end

    def delete
      connection.run_request(
        :delete, "/invalidate_service_ticket/#{service_ticket}", '', {}
      )
    end

    private def connection
      @connection ||= ConnectionHandler.connection(
        basic_auth: [
          Rails.configuration.ua_api_username,
          Rails.configuration.ua_api_password
        ],
        request_type: :json,
        uri: URI(UA_URL)
      )
    end
  end
end
