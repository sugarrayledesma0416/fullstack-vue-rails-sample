require 'rack/handler/webrick'
require 'webrick/https'

# Helper class to start a WEBrick server with SSL for running
# Capybara with SSL.
# See https://rossta.net/blog/local-ssl-for-rails-5.html
class SslServer
  TEST_CERTIFICATE = File.join(__dir__, 'capybara.crt').freeze
  TEST_PRIVATE_KEY = File.join(__dir__, 'capybara.key').freeze

  def initialize
    @certificate = OpenSSL::X509::Certificate.new File.read TEST_CERTIFICATE
    @key = OpenSSL::PKey::RSA.new File.read TEST_PRIVATE_KEY
  end

  def run(app, port)
    Rack::Handler::WEBrick.run(
      app,
      Port: port,
      AccessLog: [],
      Logger: WEBrick::Log.new(nil, 0),
      SSLEnable: true,
      SSLCertificate: @certificate,
      SSLPrivateKey: @key
    )
  end
end
