module WaitForAjax
  def wait_for_ajax(wait_time = nil)
    Timeout.timeout(wait_time || Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def wait_for_lms_fetch
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_lms_fetch_requests?
    end
  end

  def finished_all_ajax_requests?
    page.evaluate_script('jQuery.active').zero?
  end

  def finished_all_lms_fetch_requests?
    page.evaluate_script('window.lmsFetchActive').zero?
  end
end
