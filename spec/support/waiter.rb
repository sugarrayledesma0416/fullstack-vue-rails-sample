class Waiter
  def wait(max_wait_time = Capybara.default_max_wait_time)
    @max_wait_time = max_wait_time
    start = Time.now
    loop do
      break if yield
      timeout?(start) && timeout! || sleep(0.01)
    end
  end

  def timeout?(start)
    Time.now - start > @max_wait_time
  end

  def timeout!
    raise Timeout::Error, 'timeout while waiting for block to return true'
  end
end
