module Jr
  class ContentController < ApplicationController
    before_action :require_user

    layout 'music_v1/default'

    def show
      @menu_location = 'content'
      @page_header = 'Content'
      @vtext_linker = VtextLinker.new(current_program, current_user, session:)
    end
  end
end
