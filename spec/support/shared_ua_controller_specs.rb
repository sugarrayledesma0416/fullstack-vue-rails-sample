
shared_examples_for "an active resource controller action that rescues and reports errors" do
  before(:each) do
    allow(VHLMonitor).to receive(:notify)
  end

  context "when an exception is raised while processing the request," do

    before(:each) do
      @error = StandardError.new('something horrible happened just now')
      expect(@controller).to receive(:respond_to).and_raise(@error)
    end

    it "should not raise the exception" do
      expect{do_request}.not_to raise_error
    end

    it "should notify VHLMonitor of the exception" do
      expect(VHLMonitor).to receive(:notify).with(@error)
      do_request
    end

    it "should return the error message and a filtered stacktrace" do
      internal_rails_calls  = ['/gems/activerecord/abstract_adapter.rb:227:in `log\'',
                               '/gems/activerecord/mysql_adapter.rb:324:in `execute\'' ]
      interesting_app_calls = ['app/controllers/application_controller.rb:265:in `create_maestro2_session\'',
                               'app/controllers/home_controller.rb:17:in `front\'']

      allow(@error).to receive(:backtrace).and_return(internal_rails_calls + interesting_app_calls)
      do_request

      expect(response.body).to include "\"message\":\"#{@error.message}\""

      interesting_app_calls.each do | backtrace_line |
        expect(response.body).to include backtrace_line
      end
      internal_rails_calls.each do | backtrace_line |
        expect(response.body).not_to include backtrace_line
      end
    end

    it "should respond with an ActiveResource::ServerError status code" do
      do_request
      expect(response.response_code).to eq(503)
      expect(response.status).to eq(503)
    end
  end
end
