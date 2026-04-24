class EbooksController < ApplicationController
  before_action :require_user
  before_action :require_program_access
  before_action :set_current_program
  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :set_page_header
  before_action :archived_program_redirect

  def set_page_header
    @page_header = 'eBook'
  end

  def index
    @menu_location = 'content'
    with_ebook_access do
      @presenter = EbooksPresenter.new(current_program.id)
    end
  end

  def go_to_vitalsource
    with_ebook_access do |expires_on|
      api_response = Vitalsource.request_sso_url(current_user,
                                                 params[:id],
                                                 current_program.id,
                                                 expires_on)
      if api_response.is_a?(Hash)
        report_api_error(api_response)
        redirect_to ebooks_path(current_program, current_section)
      else
        redirect_to api_response
      end
    end
  end

  private def demo_user?
    access_guardian.has_unexpired_demo_access? || current_user.fake
  end
  helper_method :demo_user?

  private def report_api_error(api_response)
    VHLMonitor.error('Vitalsource Bookshelf API error', response: api_response)
    Rails.logger.fatal('Vitalsource Bookshelf API ' \
                       "Error: #{api_response.inspect}")
    flash[:error] = "Error code: #{api_response[:error_code]}"
  end

  private def with_ebook_access
    if access_guardian.has_ebook?
      expiration_date = access_guardian.ebook_expiration_date
      yield expiration_date
    else
      flash[:error] = 'You do not have access to the eBook.'
      redirect_to BestDefaultPath.best_default_path(
        current_user, current_program, current_section, session
      )
    end
  end
end
