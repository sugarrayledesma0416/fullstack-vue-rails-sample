describe MyContent::PaginationHelper do
  describe '#pagination' do
    let(:collection) { double('collection') }

    before do
      allow(collection).to receive(:total_pages).and_return(10)
      allow(collection).to receive(:current_page).and_return(5)

      allow(helper).to receive(:request).and_return(ActionDispatch::TestRequest.create)
      allow(helper.request).to receive(:query_parameters).and_return({})
      allow(helper).to receive(:url_for).and_return('/path')
    end

    it 'returns nil if total_pages is 1 or less' do
      allow(collection).to receive(:total_pages).and_return(1)
      expect(helper.pagination(collection)).to be_nil
    end

    it 'includes link to first page when current page is greater than 1' do
      allow(collection).to receive(:current_page).and_return(2)
      rendered = helper.pagination(collection)
      expect(rendered).to have_css('span music-icon-chevron-left-double')
    end

    it 'does not include link to first page when current page is 1' do
      allow(collection).to receive(:current_page).and_return(1)
      rendered = helper.pagination(collection)
      expect(rendered).not_to have_css('span music-icon-chevron-left-double')
    end

    it 'includes link to last page when current page is less than total pages' do
      allow(collection).to receive(:current_page).and_return(5)
      rendered = helper.pagination(collection)
      expect(rendered).to have_css('span music-icon-chevron-right-double')
    end

    it 'does not include link to last page when current page is the last one' do
      allow(collection).to receive(:current_page).and_return(10)
      rendered = helper.pagination(collection)
      expect(rendered).not_to have_css('span music-icon-chevron-right-double')
    end

    it 'joins the links with a space separator' do
      result = helper.pagination(collection)
      expect(result).to include('music-icon-chevron-left-double')
      expect(result).to include('music-icon-chevron-right-double')
      expect(result).to include('music-icon-chevron-left')
      expect(result).to include('music-icon-chevron-right')
    end
  end
end
