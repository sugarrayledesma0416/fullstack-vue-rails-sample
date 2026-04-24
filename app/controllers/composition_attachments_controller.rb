class CompositionAttachmentsController < ApplicationController
  include CartridgeViewable

  before_action :require_user, except: :file_types
  before_action :assign_composition_attachment, only: :show
  before_action :restrict_composition_download_to_owner, only: :show

  def create
    attacher = CompositionAttacher.new(
      current_user,
      current_section,
      params[:qqfile],
      params[:previous_attachment_id]
    )
    attacher.upload
    # Due to the way IE handles document.domain in the iframes that
    # FineUploader uses, we have to do a somewhat ugly
    # hack for IE versions earlier than 10.0
    if internet_explorer_less_than_version_10?
      base_response = attacher.response.to_json
      ie_compatibility_hack = "<script>document.domain='vhlcentral.com';</script>".html_safe
      render(
        plain: ('<pre>' + base_response + '</pre>' + ie_compatibility_hack),
        content_type: Mime[:html]
      )
    else
      render json: attacher.response
    end
  end

  def show
    redirect_to @composition_attachment.signed_url
  end

  def destroy
    composition_attachment = CompositionAttachment.find(params[:id])
    if composition_attachment.destroy_by_user(current_user)
      render json: { success: true }, content_type: Mime[:text]
    else
      error = 'You cannot remove this file because it was uploaded by someone else.'
      render json: { success: false, reason: error }, status: 401, content_type: Mime[:text]
    end
  end

  def file_types
    @allowed_file_types = FileType.allowed
    render layout: 'popup_no_header_with_style'
  end

  private def restrict_composition_download_to_owner
    return if @composition_attachment.downloadable_by?(current_user, current_section)

    render plain: 'Download Denied.', status: 401
  end

  private def assign_composition_attachment
    @composition_attachment = CompositionAttachment.find(params[:id])
  end

  def internet_explorer_less_than_version_10?
    # request.user_agent lacks information to determinate correctly if the
    # browser is IE11 so we use the navigator.userAgent value obtained
    # from the browser.
    agent = UserAgent.parse(params['navigator_user_agent'])
    agent.browser == 'Internet Explorer' && agent.version < UserAgent::Version.new('10.0')
  end
  private :internet_explorer_less_than_version_10?
end
