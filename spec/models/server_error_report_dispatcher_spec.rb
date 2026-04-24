describe ServerErrorReportDispatcher do
  let(:user) { build_stubbed(:student) }
  let(:server_error_params) do
    { user_id:           user.id,
      error_id:          'rollbar.exception_uuid',
      http_referer:      'HTTP_REFERER',
      ip_address:        'REMOTE_ADDR',
      user_agent_string: 'HTTP_USER_AGENT',
      operating_system:  'windows',
      browser_name:      'chrome',
      browser_version:   '54.3'
    }
  end

  describe '#payload' do
    it 'sets created_at and updated_at if not provided' do
      server_error = ServerErrorReportDispatcher.new(server_error_params)

      expect(server_error.payload[:created_at]).to be_a(Time)
      expect(server_error.payload[:updated_at]).to be_a(Time)
    end

    it 'uses the values for created_at and updated_at when provided' do
      created = 1.hour.ago
      updated = 59.minutes.ago
      server_error_params.merge!(created_at: created, updated_at: updated)
      server_error = ServerErrorReportDispatcher.new(server_error_params)

      expect(server_error.payload[:created_at]).to eq created
      expect(server_error.payload[:updated_at]).to eq updated
    end

    it 'does not update created_at when submitting an error form' do
      server_error_params = {id: 'error_id', user_comment: "my comment"}
      server_error = ServerErrorReportDispatcher.new(server_error_params)

      expect(server_error.payload[:created_at]).to be_nil
      expect(server_error.payload[:updated_at]).to be_a(Time)
    end

    it 'provides method calls for expected params' do
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      server_error.expected_params.each do |param|
        expect { server_error.send(param) }.to_not raise_error
      end
    end

    it 'creates a payload that includes all expected param values' do
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      server_error.expected_params.each do |param|
        expect(server_error.payload[param]).to eq server_error_params[param]
      end
    end
  end

  describe '#user' do
    it 'Returns the user if the user exists' do
      saved_user = create(:user)
      server_error_params[:user_id] = saved_user.id
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      expect(server_error.user).to eq(saved_user)
    end

    it 'Returns nil if the user id option does not reference an existing user' do
      invalid_user_id = User.count.to_i + 1
      server_error_params[:user_id] = invalid_user_id
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      expect(server_error.user).to be_nil
    end

    it 'Returns nil if not initialized with a user_id option' do
      server_error_params.delete(:user_id)
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      expect(server_error.user).to be_nil
    end

    it 'Returns nil if the user_id option is nil' do
      server_error_params[:user_id] = nil
      server_error = ServerErrorReportDispatcher.new(server_error_params)
      expect(server_error.user).to be_nil
    end

  end
end
