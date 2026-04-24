# See https://rossta.net/blog/local-ssl-for-rails-5.html
module Capybara
  class Server
    def responsive?
      return false if @server_thread && @server_thread.join(0)

      http = Net::HTTP.new(host, @port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      res = http.get('/__identify__')

      if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
        res.body == @app.object_id.to_s
      end
    rescue SystemCallError
      false
    end
  end
end
