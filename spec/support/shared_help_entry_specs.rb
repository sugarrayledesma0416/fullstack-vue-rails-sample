shared_examples_for "an action that assigns contextual help" do

  it "should find and assign a contextual help url" do
    @help_entry = build_stubbed(:help_entry)
    allow(HelpEntry).to receive(:where).and_return([@help_entry])
    do_request
    expect(assigns(:contextual_help_url)).to eql @help_entry.url
  end
end
