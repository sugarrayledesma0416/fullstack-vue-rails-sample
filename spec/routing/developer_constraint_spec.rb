describe DeveloperConstraint do
  let(:user) { create(:user).tap { |user| user.roles << Role.create!(name: Role::DEVELOPER) } }

  describe '#matches?' do
    context 'when the user is a developer' do
      it 'returns true' do
        session = { cas_user: user.username }
        request = instance_double(ActionDispatch::Request, session:)
        constraint = described_class.new

        expect(constraint.matches?(request)).to be(true)
      end
    end

    context 'when the user is not a developer' do
      it 'returns false' do
        session = { cas_user: 'non_developer' }
        request = instance_double(ActionDispatch::Request, session:)
        constraint = described_class.new

        expect(constraint).not_to be_matches(request)
      end
    end

    context 'when the user is not logged in' do
      it 'returns false' do
        request = instance_double(ActionDispatch::Request, session: {})
        constraint = described_class.new

        expect(constraint).not_to be_matches(request)
      end
    end
  end
end
