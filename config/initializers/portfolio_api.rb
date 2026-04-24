config_file_path = Rails.root.join('config', 'portfolio_server.yml')

Rails.configuration.portfolio =
  if File.exist?(config_file_path)
    Rails.application.config_for(:portfolio_server)
  else
    {}
  end

if Rails.env.test?
  Rails.configuration.portfolio = {
    admin_web_token: 'test-token',
    domain_url: 'http://test.com'
  }
end
