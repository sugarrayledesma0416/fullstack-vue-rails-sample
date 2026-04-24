describe Student::AssessmentAccessController do
  let(:generator) { double('PasswordAttemptValidator').as_null_object }

  def do_request(password)
    post :unlock_assessment, params: { assessment_password: 'test', activity_id: '1', section_id: '1' }
  end

  describe '#unlock_assessment' do
    before do
      @user = build_stubbed(:user)
      fake_login(@user)
      request.env['HTTP_REFERER'] = 'where_i_came_from'
      allow(controller).to receive(:current_user).and_return(@user)
      allow(generator).to receive(:log_password_attempt)
      allow(PasswordAttemptValidator).to receive(:new).and_return(generator)
    end

    it 'creates a password attempt generator' do
      expect(PasswordAttemptValidator).to receive(:new).with(@user, '1', '1', 'test').and_return(generator)
      do_request('password')
    end

    it 'logs the password attempt' do
      expect(generator).to receive(:log_password_attempt)
      do_request('password')
    end

    context 'with correct password' do
      before do
        allow(generator).to receive(:correct?).and_return(true)
      end

      it 'adds params[:activity_id] to unlocked assessments hash' do
        do_request('password')
        expect(controller.session[:unlocked_assessments]).to include(1)
      end

      it 'reloads the page' do
        do_request('password')
        expect(response.parsed_body['success']).to be_truthy
      end
    end

    context 'with incorrect password' do
      it 'reloads the page with a flash error message' do
        allow(generator).to receive(:correct?).and_return(false)
        do_request('wrong_password')
        expect(
          response.parsed_body['error']
        ).to eql 'The password you entered is incorrect.'
      end
    end
  end
end
