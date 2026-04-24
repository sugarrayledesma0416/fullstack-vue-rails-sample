require 'vitalsource'

describe Vitalsource do
  describe '.request_sso_url' do
    let(:user) { build_stubbed(:user) }
    let(:book_id) { '978-1-76007-191' }
    let(:program_id) { build_stubbed(:program).id }
    let(:expires) { 1.year.from_now.to_date }
    let(:access_token) { 'abcdefg' }
    let(:sso_url) { 'https://bookshelf.sso.site/sso_url' }

    let(:reference_user) { double(described_class::ReferenceUser) }
    let(:license) { double(described_class::License) }
    let(:redirect) { double(described_class::Redirect, sso_url: sso_url) }

    before do
      allow(described_class::ReferenceUser).to receive(:new) { reference_user }
      allow(described_class::License).to receive(:new) { license }
      allow(described_class::Redirect).to receive(:new) { redirect }
      allow(reference_user).to receive(:access_token).and_yield(access_token)
      allow(license).to receive(:ensure_access).and_yield
    end

    it 'instantiates a ReferenceUser for the specified user' do
      expect(described_class::ReferenceUser).to receive(:new)
        .with(user) { reference_user }

      described_class.request_sso_url(user, book_id, program_id, expires)
    end

    it 'requests an access token from the ReferenceUser instance' do
      expect(reference_user).to receive(:access_token).and_yield(access_token)

      described_class.request_sso_url(user, book_id, program_id, expires)
    end

    context 'when the ReferenceUser instance does not yield an access token' do
      it 'returns without instantiating a License' do
        allow(reference_user).to receive(:access_token).and_return(nil)
        expect(described_class::License).not_to receive(:new)

        described_class.request_sso_url(user, book_id, program_id, expires)
      end
    end

    context 'when the ReferenceUser instance yields an access token' do
      it 'instantiates a License with that access token and ' \
         'the specified book id and ebook license expiration date' do
        expect(described_class::License).to receive(:new)
          .with(access_token, book_id, expires) { license }

        described_class.request_sso_url(user, book_id, program_id, expires)
      end

      it 'tells the License instance to ensure the correct user access' do
        expect(license).to receive(:ensure_access).and_yield

        described_class.request_sso_url(user, book_id, program_id, expires)
      end

      context 'when the License instance does not yield' do
        it 'returns without insantiating a Redirect' do
          allow(license).to receive(:ensure_access).and_return(nil)
          expect(described_class::Redirect).not_to receive(:new)

          described_class.request_sso_url(user, book_id, program_id, expires)
        end

        it 'does not create a record of a vitalsource redemption' do
          allow(license).to receive(:ensure_access).and_return(nil)

          expect do
            described_class.request_sso_url(user, book_id, program_id, expires)
          end.not_to change(VitalsourceRedemption, :count)
        end
      end

      context 'when the License instance yields' do
        it 'creates a record of a vitalsource redemption for the user and program' do
          expect do
            described_class.request_sso_url(user, book_id, program_id, expires)
          end.to change(VitalsourceRedemption, :count).by(1)
          record = VitalsourceRedemption.last
          expect(record.user_id).to eq(user.id)
          expect(record.program_id).to eq(program_id)
        end

        it 'instantiates a Redirect with the access token and book id' do
          expect(described_class::Redirect).to receive(:new)
            .with(access_token, book_id) { redirect }

          described_class.request_sso_url(user, book_id, program_id, expires)
        end

        it 'requests and returns an SSO Url from the Redirect' do
          expect(redirect).to receive(:sso_url) { sso_url }

          result = described_class.request_sso_url(user, book_id, program_id, expires)

          expect(result).to eq(sso_url)
        end
      end
    end
  end
end
