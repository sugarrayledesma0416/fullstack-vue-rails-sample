class UserSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # called from ua
  def remote_destroy
    CASClient::Frameworks::Rails::Filter.filter(self)
    head :ok
  end

  # CASClient wants to render a text response while we prefer
  # an empty response.
  # https://github.com/rubycas/rubycas-client/blob/7b67c8f1b5515ee4e28479d640d2da0a5aadfbe0/lib/casclient/frameworks/rails/filter.rb#L33
  # Overriding `render` on this controller will consume the gem's response silently.
  def render(*args); end
end
