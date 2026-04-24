class ConnectionHandler

  # Provides an http connection
  # Params hash keys:
  # - uri: URL to connect to. Required param.
  # - basic_auth: specify array of username, password to use basic auth
  # - request_type: content type of request, as a symbol, typically :json
  # - connection_options: hash of additional options for Faraday connection.
  def self.connection(params = {})
    # allow self-signed certs in dev env only
    ssl_verification = Rails.env.development? ? false : true

    Faraday.new(url: params[:uri], ssl: { verify: ssl_verification }) do |conn|
      conn.request params[:request_type] unless params[:request_type].blank?
      conn.options.merge(params[:connection_options]) unless params[:connection_options].blank?
      conn.response :json, content_type: /\bjson$/
      if params[:basic_auth]
        conn.basic_auth(*params[:basic_auth])
      end
      conn.adapter Faraday.default_adapter
    end
  end
end
