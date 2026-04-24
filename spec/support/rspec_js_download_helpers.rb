module RspecJsDownloadHelpers
  TIMEOUT = 10
  PATH    = Rails.root.join('tmp/downloads')

  def self.included(includer)
    includer.around(:each, downloads: true) do |example|
      clear_downloads
      example.run
      clear_downloads
    end
  end

  def downloaded_files
    Dir[PATH.join('*')].sort_by { |file| File.mtime(file) }
  end

  def last_downloaded_file
    downloaded_files.last
  end

  def last_download_content(read_args = {})
    wait_for_download
    File.read(last_downloaded_file, **read_args)
  end

  def enable_headless_downloads
    # This hackery is needed because by default chrome doesn't allow
    # file downloads in headless mode. See:
    # https://bugs.chromium.org/p/chromium/issues/detail?id=696481#c89
    if Capybara.javascript_driver == :headless_chrome
      bridge = Capybara.current_session.driver.browser.send(:bridge)

      bridge.http.call(
        :post, "/session/#{bridge.session_id}/chromium/send_command",
        cmd: 'Page.setDownloadBehavior',
        params: { behavior: 'allow', downloadPath: PATH.to_s }
      )
    end
    yield
    # Need to clear downloads in headless mode because chrome won't allow
    # multiple downloads with the same name.
    clear_downloads if Capybara.javascript_driver == :headless_chrome
  end

  private def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
    # Ensure that if the same spec downloads multiple files, downloaded?
    # doesn't always return true after the first file is downloaded.
    @download_count = downloaded_files.size
  end

  private def downloaded?
    !downloading? && downloaded_files.size > @download_count
  end

  private def downloading?
    downloaded_files.grep(/\.crdownload$/).any?
  end

  def clear_downloads
    FileUtils.rm_f(downloaded_files)
    @download_count = 0
  end
end
