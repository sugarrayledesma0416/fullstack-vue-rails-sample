describe 'PasswordAttemptValidator' do
  describe "#correct?" do
    context 'when the password is correct' do
      it 'returns true' do
        generator = PasswordAttemptValidator.new(nil, 0, 0, 'test')
        allow(generator).to receive(:stored_password).and_return('test')
        expect(generator).to be_correct
      end
    end

    context 'when the password is incorrect' do
      it 'returns false' do
        generator = PasswordAttemptValidator.new(nil, 0, 0, 'test')
        allow(generator).to receive(:stored_password).and_return('bad_password')
        expect(generator).not_to be_correct
      end
    end
  end

  describe '#log_password_attempt' do
    before(:each) do
      @generator = PasswordAttemptValidator.new(nil, 0, 0, 'test')
      allow(@generator).to receive(:stored_password).and_return('test')
    end

    context 'when an attempt exists' do
      it 'logs a password attempt' do
        attempt = Attempt.new
        attempt.id = 1
        allow(@generator).to receive(:attempt).and_return(attempt)

        expect(PasswordAttempt).to receive(:create).with({
          :attempt_id => 1,
          :correct => true,
          :password => 'test'
        })
        @generator.log_password_attempt
      end
    end

    context 'when an attempt does not exist' do
      it 'does not log a password attempt' do
        attempt = Attempt.new
        attempt.id = 0
        allow(@generator).to receive(:attempt).and_return(attempt)

        expect(PasswordAttempt).not_to receive(:create)
        @generator.log_password_attempt
      end
    end
  end
end
