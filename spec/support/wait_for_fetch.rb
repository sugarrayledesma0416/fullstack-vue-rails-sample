module WaitForFetch
  def decorate_fetch
    page.execute_script <<~JAVASCRIPT
      // Exit early if fetch is already redefined on page
      if (window.fetch_instances !== undefined) { return; }

      window.fetch_instances = 0;

      const realFetch = fetch;

      fetch = (url, options) => {
        let promise = realFetch(url, options);
        window.fetch_instances++;
        return new Promise((resolve, reject) => {
          promise.then((data) => {
            window.fetch_instances--;
            resolve(data);
          });
        });
      };
   JAVASCRIPT
  end

  def wait_for_fetch
    decorate_fetch

    yield

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_fetch_requests?
    end
  end

  def finished_all_fetch_requests?
    page.evaluate_script('window.fetch_instances').zero?
  end
end
