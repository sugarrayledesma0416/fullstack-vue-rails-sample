describe PartnerChatPresenter do
  let(:user) { build_stubbed(:student) }
  let(:collaborator) { build_stubbed(:student) }
  let(:partner_chat_recording) { double('PartnerChatRecording', :user => user, :partner => collaborator, :partner_practice => false) }
  let(:presenter) { PartnerChatPresenter.new([user, collaborator], [partner_chat_recording]) }

  describe "#original_user" do
    #for this test, we ask both the invitor and the invitee who the invitor is,
    #and for it to pass, both should identify the same user as the invitor
    it "returns the user referenced by the PartnerChatRecording user_id field" do
      presenter = PartnerChatPresenter.new([partner_chat_recording])
      expect(presenter.original_user(user)).to eql user
      expect(presenter.original_user(collaborator)).to eql user
    end
  end

  describe "#partner_is_practicing?" do
    it "returns false if collaborator is same as current student" do
      presenter = PartnerChatPresenter.new([partner_chat_recording])
      expect(presenter.partner_is_practicing?(user, user)).to be_falsey
    end

    context" when collaborator is not same as current student" do
      #this is built around the assumption that only non practicing students can submit
      #hence only partners can be practicing.
      it "return true when collaborator is practicing " do
        allow(partner_chat_recording).to receive(:partner_practice).and_return(true)
        presenter = PartnerChatPresenter.new([partner_chat_recording])
        expect(presenter.partner_is_practicing?(collaborator, user)).to be_truthy
      end

      it "return false when collaborator is not practicing " do
        allow(partner_chat_recording).to receive(:partner_practice).and_return(false)
        presenter = PartnerChatPresenter.new([partner_chat_recording])
        expect(presenter.partner_is_practicing?(collaborator, user)).to be_falsey
      end
    end
  end

  describe "#original_partner" do
    #for this test, we ask both the invitor and the invitee who the invitee is,
    #and for it to pass, both should identify the same user as the invitee
    it "returns the user referenced by the PartnerChatRecording partner_id field" do
      presenter = PartnerChatPresenter.new([partner_chat_recording])
      expect(presenter.original_partner(user)).to eql collaborator
      expect(presenter.original_partner(collaborator)).to eql collaborator
    end
  end

  describe "#sort_students" do
    let(:user_2) { build_stubbed(:student) }
    let(:collaborator_2) { build_stubbed(:student) }
    let(:partner_chat_recording_2) { double('PartnerChatRecording', :user => user_2, :partner => collaborator_2,
                                          :partner_practice => false) }
    let(:presenter) { PartnerChatPresenter.new([user, collaborator, user_2, collaborator_2], [partner_chat_recording, partner_chat_recording_2]) }

    it "sorts students by placing all users first, and all partners after" do
        presenter = PartnerChatPresenter.new([partner_chat_recording, partner_chat_recording_2])
        expect(presenter.sort_students([collaborator, collaborator_2, user, user_2])).to eql [user, user_2, collaborator, collaborator_2]
    end
  end
end
