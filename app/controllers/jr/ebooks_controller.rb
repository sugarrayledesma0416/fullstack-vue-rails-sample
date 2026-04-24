module Jr
  class EbooksController < ::EbooksController
    layout 'music_v1/default'

    def index
      super
      @menu_location = 'content'
      @page_title = 'eBook'
    end
  end
end
