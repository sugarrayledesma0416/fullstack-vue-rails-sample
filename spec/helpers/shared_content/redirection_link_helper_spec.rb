describe SharedContent::RedirectionLinkHelper do
  describe '#redirection_link' do
    it 'returns a default link with default options' do
      expect(helper.redirection_link).to eq(helper.link_to('', '#',
                                                           class: 'u-txt-black u-txt-under u-txt-bold', method: :get))
    end

    it 'allows custom text and path' do
      link = helper.redirection_link(text: 'Click here', path: '/custom_path')
      expect(link).to eq(helper.link_to('Click here', '/custom_path',
                                        class: 'u-txt-black u-txt-under u-txt-bold', method: :get))
    end

    it 'allows overriding the link class and method' do
      link = helper.redirection_link(class: 'new-class', method: :post)
      expect(link).to eq(helper.link_to('', '#', class: 'new-class', method: :post))
    end
  end
end
