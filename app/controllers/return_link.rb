# extend your controller by adding:
# include ReturnLink
# then either set an :assign_return_link before_action
# or call assign_return_link method within your controller action

module ReturnLink
  def assign_return_link
    if session[:activity_return]
      @return_label = session[:activity_return].with_indifferent_access[:label]
      if params[:return_to]
        @return_url = params[:return_to]
        add_query_strings('start_strand', 'start_topic', 'display_lesson', 'toc_location')
        session[:activity_return]['url'] = @return_url
      else
        @return_url = session[:activity_return].with_indifferent_access[:url]
      end
    else
      @return_url = BestDefaultPath.best_default_path(
        current_user, current_program, current_section, session
      )
      @return_label = 'Go to Dashboard'
    end
  end

  def set_return_info(label)
    session[:activity_return] = { 'label' => label, 'url' => yield }
  end

  def path_options
    params_for_instructor_navigation.inject({}) do |memo, key|
      memo[key] = params[key] if params[key].present?
      memo
    end
  end

  def params_for_instructor_navigation
    base_params = [:display_lesson, :toc_location, :start_unit]
    if params['all_units'].present? && params['all_units'] == 'true'
      base_params << 'all_units'.to_sym
    end
    base_params
  end
  private :params_for_instructor_navigation

  def add_query_strings(*params_options)
    url = URI(@return_url)
    query_params = URI.decode_www_form(url.query || '')
    params_options.each{ |param| query_params << [param, params[param.to_s]] if params[param.to_s] }
    url.query = URI.encode_www_form(query_params) unless query_params.empty?
    @return_url = url.to_s
  end
  private :add_query_strings
end
