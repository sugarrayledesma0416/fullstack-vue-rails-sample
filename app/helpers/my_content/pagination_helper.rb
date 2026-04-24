module MyContent::PaginationHelper
  def pagination(collection, options = {})
    return if collection.total_pages <= 1

    content_tag :div, class: 'c-pagination__container' do
      links = []

      # link to first page
      if collection.current_page > 1
        links << link_to(url_for(request.query_parameters.merge(page: 1))) do
          content_tag(:span) do
            content_tag('music-icon-chevron-left-double'.to_sym, nil)
          end
        end
      end

      links << will_paginate(collection, pagination_options(options))

      # link to last page
      if collection.current_page < collection.total_pages
        links << link_to(url_for(request.query_parameters.merge(page: collection.total_pages))) do
          content_tag(:span) do
            content_tag('music-icon-chevron-right-double'.to_sym, nil)
          end
        end
      end

      safe_join(links, ' ')
    end
  end

  private def pagination_options(options)
    options.merge(
      inner_window: 1,
      outer_window: 0,
      previous_label: pagination_icon('music-icon-chevron-left'),
      next_label: pagination_icon('music-icon-chevron-right')
    )
  end

  private def pagination_icon(icon_name)
    raw("<span>#{content_tag(icon_name.to_sym, nil)}</span>")
  end
end
