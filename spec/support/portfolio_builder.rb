require 'rails_helper'

module PortfolioBuilder
  def stub_portfolio_request(request_type, stub_response)
    stub_request(:post, %r{http://.*/webservice/rest/server.php}).with do |request|
      body_params = URI.decode_www_form(request.body)
      param_value = body_params.find { |key, _| key == 'wsfunction' }&.last
      param_value == request_type
    end.to_return(
      status: 200,
      body: stub_response
    )
  end

  def stub_bulk_upload_artifacts_request(request_type, stub_response)
    stub_request(:post, %r{http://.*/webservice/rest/server.php})
    .with(headers: {'accept' => 'application/json'})
    .to_return(
      status: 200,
      body: stub_response
    )
  end
end
