describe Instructor::NavigationHelper do
  include Instructor::NavigationHelper
  describe "#navigation_link_unless_current" do
    context "when the user is viewing the specified url," do
      it "should return the specified link_title without hyperlinking it", test_debt: true do
        pending "adam - need to figure out how to test link_to_unless_current"

        allow(template).to receive(:current_page?).and_return(false) # for the main nav links
        allow(template).to receive(:current_page?).with('/some/page').and_return(true) #for the breadcrumbs
        link_title = 'abcd'
        link_url   = '/some/page'
        result = navigation_link_unless_current(link_title, link_url)
        expect(result).not_to have_tag('a[href=?]', link_url)
        expect(result).to have_tag('span', link_title)
      end
    end

    context "when the user is not viewing the specified url," do
      it "should return a link to the specified url", test_debt: true do
        pending "adam - need to figure out how to test link_to_unless_current"
        link_title = 'abcd'
        link_url   = '/some/page'
        result = navigation_link_unless_current(link_title, link_url)
        expect(result).to have_tag('a[href=?]', link_url)
      end
    end

  end

end
