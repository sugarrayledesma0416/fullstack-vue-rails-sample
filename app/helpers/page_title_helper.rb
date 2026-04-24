# frozen_string_literal: true

module PageTitleHelper
  SITE_TITLE = 'VHL Central'

  PAGE_TITLE_FORMAT = {
    as_suffix: 'suffix',
    as_prefix: 'prefix',
    as_replacement: 'replacement'
  }.freeze

  def create_page_title(title, format: PAGE_TITLE_FORMAT[:as_suffix])
    title_string = strip_tags title.to_s

    result = case format
             when PAGE_TITLE_FORMAT[:as_prefix]
               "#{title_string} | #{PageTitleHelper::SITE_TITLE}"
             when PAGE_TITLE_FORMAT[:as_replacement]
               title_string
             else
               "#{PageTitleHelper::SITE_TITLE} | #{title_string}"
             end

    result
  end
end
