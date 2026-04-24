describe HelpRequestsPresenter do
  let(:user){ build_stubbed(:student) }
  let(:section){ build_stubbed(:section) }
  let(:help_request_1) { double('HelpRequest', :activity_id => 1) }
  let(:help_request_2) { double('HelpRequest', :activity_id => 2) }
  let(:help_requests) { [help_request_1, help_request_2] }
  let(:grouped_help_requests) { { 1 => [help_request_1], 2 => [help_request_2] } }
  let(:request_info_1) { double('RequestInfoForActivity', :created_at => 1.day.ago) }
  let(:request_info_2) { double('RequestInfoForActivity', :created_at => 2.days.ago) }
  let(:scope) { double('scope', :instructor_respondable => help_requests, :reported_problems => help_requests) }


  before do
    allow(user.help_requests).to receive(:unprocessed).and_return(scope)
    allow(user.help_requests).to receive(:processed).and_return(scope)
    allow(help_requests).to receive_message_chain(:includes, :group_by).and_return(grouped_help_requests)
    allow(scope).to receive(:by_section).and_return(scope)
    allow(HelpRequestsPresenter::RequestInfoForActivity).to receive(:new).with([help_request_1]).and_return(request_info_1)
    allow(HelpRequestsPresenter::RequestInfoForActivity).to receive(:new).with([help_request_2]).and_return(request_info_2)
  end

  describe '#populate' do
    context 'when user has submitted requests' do
      context 'when closed help requests are to be displayed' do
        it 'extracts processed help requests from user' do
          expect(user.help_requests).to receive(:processed).and_return(scope)
          presenter = HelpRequestsPresenter.new(section, user, status_scope = 'closed')
          presenter.populate
        end
      end

      context 'when open help requests are to be displayed' do
        it 'extracts unprocessed help requests from user' do
          expect(user.help_requests).to receive(:unprocessed).and_return(scope)
          presenter = HelpRequestsPresenter.new(section, user, status_scope = 'open')
          presenter.populate
        end
      end

      context 'when no type_scope is specified' do
        it 'looks up only instructor_respondable help requests' do
          expect(scope).to receive(:instructor_respondable).and_return(help_requests)
          expect(scope).not_to receive(:reported_problems)
          presenter = HelpRequestsPresenter.new(section, user, status_scope = 'open')
          presenter.populate
        end
      end

      context 'when type_scope of :reported_problems is specified' do
        it 'looks up only instructor_respondable help requests' do
          expect(scope).to receive(:reported_problems).and_return(help_requests)
          expect(scope).not_to receive(:instructor_respondable)
          presenter = HelpRequestsPresenter.new(section, user, status_scope = 'open', type_scope = :reported_problems)
          presenter.populate
        end
      end

      context 'when type_scope of :instructor_respondable is specified' do
        it 'looks up only instructor_respondable help requests' do
          expect(scope.by_section(section)).to receive(:instructor_respondable).and_return(help_requests)
          expect(scope).not_to receive(:reported_problems)
          presenter = HelpRequestsPresenter.new(section, user, status_scope = 'open', type_scope = :instructor_respondable)
          presenter.populate
        end
      end

      it 'populates request_groups attribute with an array of RequestInfoForActivity objects' do
        expect(HelpRequestsPresenter::RequestInfoForActivity).to receive(:new).at_least(:once)
        presenter = HelpRequestsPresenter.new(section, user)
        presenter.populate
        expect(presenter.request_groups).to eq([request_info_1, request_info_2])
      end
    end
  end

  describe '#help_requests_info' do
    it "returns user's help requests info sorted by creation date" do
      presenter = HelpRequestsPresenter.new(section, user)
      presenter.populate
      expect(presenter.help_requests_info).to eq([request_info_2, request_info_1])
    end
  end
end

describe HelpRequestsPresenter::RequestInfoForActivity do
    let(:activity) { build_stubbed(:activity) }
    let(:help_request) { build_stubbed(:help_request, :created_at => 1.days.ago, :updated_at => 15.minutes.ago.to_date, :activity => activity, :student_comment => "My comment here") }
    let(:review_request) { build_stubbed(:review_request, :created_at => 2.days.ago, :updated_at => Time.now.to_date, :activity => activity, :student_comment => "My comment there") }

    before do
      allow(help_request).to receive(:activity).and_return(activity)
      allow(review_request).to receive(:activity).and_return(activity)
    end

    it "exposes requests' activity" do
      request_info = HelpRequestsPresenter::RequestInfoForActivity.new([help_request])
      expect(request_info.activity).to eq(activity)
      expect(request_info.activity_id).to eq(activity.id)
    end

    describe '#activity_title' do
      it "returns the requests' activity title" do
        expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request]).activity_title).to eq(activity.title)
      end
    end

    describe '#count' do
      context "when there's only one request" do
        it 'returns an empty string' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request]).count).to eq('')
        end
      end

      context 'when there is more than one request' do
        it 'returns the number of help requests in parentheses' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).count).to eq('(2)')
        end
      end
    end

    describe '#anchor' do
      context "when there's only one request" do
        it 'returns the help request#helpable_item_id value for the  associated to the given activity' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request]).anchor).to eq("##{help_request.helpable_item_id}")
        end
      end

      context 'when there is more than one request' do
        it 'returns an empty string' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).anchor).to eq('')
        end
      end
    end

    describe '#request_type' do
      context "when there's only one type of request" do
        it 'returns the help request#helpable_item_id value for the  associated to the given activity' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request]).request_type).to eq('Help request')
        end
      end

      context 'when there is more than one type of request' do
        it 'returns an empty string' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).request_type).to eq('varies')
        end
      end
    end

    describe '#created_at' do
      it 'returns the oldest creation date among present requests' do
        expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).created_at.to_s).to eq(review_request.created_at.to_s)
      end
    end

    describe '#updated_at' do
      it 'returns the latest update date among present requests' do
        expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).updated_at).to eq(review_request.updated_at)
      end
    end

    describe '#comment' do
      context "when there's only one request" do
        it 'returns the comment set for the present help request' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request]).comment).to eq(help_request.student_comment)
        end
      end

      context 'when there is more than one request' do
        it 'returns an empty string' do
          expect(HelpRequestsPresenter::RequestInfoForActivity.new([help_request, review_request]).comment).to eq('varies')
        end
      end
    end
  end
