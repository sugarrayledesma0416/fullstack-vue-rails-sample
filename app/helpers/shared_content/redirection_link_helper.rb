module SharedContent
  module RedirectionLinkHelper
    def redirection_link(options = {})
      options = link_defaults.merge(options)
      ActionController::Base.helpers.link_to(
        options[:text],
        options[:path],
        remote: options[:remote],
        class: options[:class],
        method: options[:method],
        **options[:html_options]
      )
    end

    private def link_defaults
      {
        class: 'u-txt-black u-txt-under u-txt-bold',
        html_options: {},
        method: :get,
        path: '#',
        remote: false,
        text: '',
      }
    end
  end
end
