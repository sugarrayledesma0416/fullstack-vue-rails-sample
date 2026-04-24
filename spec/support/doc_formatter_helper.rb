def purpose(message)
  begin
    RSpec.configuration.reporter.publish(:purpose_open_block, message: message)
    raise ArgumentError, 'A `purpose` requires a block.' unless block_given?
    yield
  ensure
    RSpec.configuration.reporter.publish(:purpose_close_block)
  end
end

def step(message)
  if block_given?
    begin
      RSpec.configuration.reporter.publish(:step_open_block, message: message)
      yield
    ensure
      RSpec.configuration.reporter.publish(:step_close_block)
    end
  else
    RSpec.configuration.reporter.publish(:step, message: message)
  end
end

def xpurpose(message); end
def xstep(message); end
