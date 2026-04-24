shared_examples_for "an action that assigns a return link" do
  let(:focus) { double(Focus).as_null_object }
  let(:focus) { double(Focus).as_null_object }

  before { allow(Focus).to receive(:new).and_return(focus) }

  context "when there is no return link stored in the session," do
    it "assigns a default return_link" do
      session[:activity_return] = nil
      do_request
      expect(assigns[:return_label]).to eq('Go to Dashboard')
      expect(assigns[:return_url]).not_to be_nil
    end
  end

  context "when there is a return link stored in the session," do
    before do
      session[:activity_return] = {'label' => 'valid_label', 'url' => 'valid_url'}
    end

    it "assigns the label of the return link in the session to return_label" do
      do_request
      expect(assigns[:return_label]).to eql 'valid_label'
    end

    it "assigns the url of the return link in the session to return_url" do
      do_request
      expect(assigns[:return_url]).to eql 'valid_url'
    end
  end

end

shared_examples_for "an action that validates and assigns return_to" do
  let(:referrer_path) { "/gradebook/#{@program.id}" }
  let(:referrer) { "http://testdomain.com#{referrer_path}" }

  before do
    allow(controller.request).to receive(:referrer).and_return(referrer)
  end

  it "defaults to gradebook top level if passed a blank return_to param" do
    do_request(:return_to => nil)
    expect(assigns[:return_to]).to eql gradebook_path(@program)
    do_request(:return_to => '')
    expect(assigns[:return_to]).to eql gradebook_path(@program)
  end

  it "defaults to the referrer value if it's from the gradebook" do
    do_request(:return_to => '')
    expect(assigns[:return_to]).to eql referrer_path
  end

  it "assigns return_to from params" do
    expected_return_to = '/some/valid/return_to/url'
    do_request(:return_to => expected_return_to)
    expect(assigns[:return_to]).to eql expected_return_to
  end
end

