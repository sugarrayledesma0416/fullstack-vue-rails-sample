
class MediaItemsController < ApplicationController
  include CartridgeViewable

  before_action :require_user, only: :svg_content

  def show
    @media_item = MediaItem.find(params[:id])
    layout = false
    layout = 'popup_no_header_with_style' if @media_item.media_type == 'video'

    render :action => 'show', :layout => layout
  end

  def svg_content
    media_item = MediaItem.find(params[:id])

    render xml: media_item.svg_content || '<info>No Content</info>'
  rescue ActiveRecord::RecordNotFound
    render xml: '<error>Media Not Found</error>', status: 404
  rescue StandardError => e
    VHLMonitor.notify(e, rack_env: request.env)
    head 500
  end
end
