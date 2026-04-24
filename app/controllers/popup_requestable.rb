module PopupRequestable
  def request_from_popup?
    decoded_url = URI.decode_www_form_component(request.url)

    ['1', 'true'].include?(params[:popup]) || decoded_url.include?('popup=1')
  end

  private def practice_layout
    request_from_popup? ? 'layouts/activity_popup' : 'layouts/activity'
  end
end
