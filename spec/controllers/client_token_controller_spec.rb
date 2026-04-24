describe ClientTokenController do
  let(:user) { create(:user) }
  let(:section) { create(:section_with_course) }
  let(:token) { double('ApiToken', secret: 'secret', jid: 'foo@bar.com') }

  describe '#new' do
    it 'creates a new client token' do
      expect(Maestro::ApiToken).to receive(:fetch).with(user.guid, section.course.guid).and_return(token)
      get :new, params: { id: user.id, section_id: section.id, format: :json }
    end

    context 'when section id is zero' do
      it 'uses section zero' do
        expect(Maestro::ApiToken).to receive(:fetch).with(user.guid, 0).and_return(token)
        get :new, params: { id: user.id, section_id: 0, format: :json }
      end
    end

    context 'when section id is not zero' do
      it 'finds the section' do
        expect(Maestro::ApiToken).to receive(:fetch).with(
          user.guid,
          section.course.guid
        ).and_return(token)
        expect(Section).to receive(:find).with(section.id.to_s).and_return(section)
        get :new, params: {
          id: user.id,
          section_id: section.id.to_s,
          format: :json
        }
      end
    end

    context 'when a valid token is returned' do
      it 'returns token and jid as json' do
        allow(Maestro::ApiToken).to receive(:fetch).and_return(token)
        get :new, params: { id: user.id, section_id: section.id, format: :json }
        expect(response.body).to eq({ password: token.secret, jid: token.jid }.to_json)
      end
    end

    context 'when a nil token is returned' do
      it 'returns 403' do
        token = double('ApiToken', secret: nil)
        allow(Maestro::ApiToken).to receive(:fetch).and_return(token)
        get :new, params: { id: user.id, section_id: section.id, format: :json }
        expect(response.status).to eq(403)
      end
    end
  end
end
