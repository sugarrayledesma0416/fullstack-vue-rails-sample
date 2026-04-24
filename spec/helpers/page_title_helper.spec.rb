describe PageTitleHelper do
  include PageTitleHelper

  describe '#create_page_title' do
    it 'Adds the provided title as a suffix by default.' do
      custom_title = 'foo'
      result = "#{PageTitleHelper::SITE_TITLE} | #{custom_title}"
      expect(create_page_title(custom_title)).to eq(result)
    end

    it 'Adds the provided title as a suffix if specified.' do
      custom_title = 'foo'
      format = PageTitleHelper::PAGE_TITLE_FORMAT[:as_suffix]
      result = "#{PageTitleHelper::SITE_TITLE} | #{custom_title}"
      expect(create_page_title(custom_title, format: format)).to eq(result)
    end

    it 'Adds the provided title as a prefix if specified.' do
      custom_title = 'foo'
      format = PageTitleHelper::PAGE_TITLE_FORMAT[:as_prefix]
      result = "#{custom_title} | #{PageTitleHelper::SITE_TITLE}"
      expect(create_page_title(custom_title, format: format)).to eq(result)
    end

    it 'Replaces the default title with the provided title if specified.' do
      custom_title = 'foo'
      format = PageTitleHelper::PAGE_TITLE_FORMAT[:as_replacement]
      expect(create_page_title(custom_title, format: format)).to eq(custom_title)
    end

    it 'Removes all html tags from the title.' do
      custom_title_with_tags = '<b>foo</b>'
      custom_title = 'foo'
      format = PageTitleHelper::PAGE_TITLE_FORMAT[:as_prefix]
      result = "#{custom_title} | #{PageTitleHelper::SITE_TITLE}"
      expect(create_page_title(custom_title_with_tags, format: format)).to eq(result)
    end
  end
end
