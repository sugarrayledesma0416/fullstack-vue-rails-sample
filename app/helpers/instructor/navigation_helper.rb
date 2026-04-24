module Instructor::NavigationHelper

  def navigation_link_unless_current(link_title, link_url)
    link_to_unless_current(link_title, link_url){ |link| content_tag 'span', link, :class => 'current'}
  end
  
end
