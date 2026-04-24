require 'rspec/core/formatters/base_formatter'
require 'rspec/core/formatters/console_codes'

# Output all `purpose` and `step` messages
# How to use it:
# rspec --format VhlDocumentationFormatter spec/some_spec.rb
class VhlDocumentationFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self,
    :example_group_started, :example_group_finished,
    :example_started, :example_passed, :example_pending, :example_failed,
    :dump_failures,
    :purpose_open_block, :purpose_close_block,
    :step, :step_open_block, :step_close_block

  def initialize(*args)
    super(args)
    @group_level = 0
  end

  def example_group_started(notification)
    puts if @group_level == 0
    puts example_group_started_output(notification.group)
    inc_indentation
  end

  def example_group_finished(_notification)
    dec_indentation
  end

  def example_started(notification)
    puts example_started_output(notification.example)
    inc_indentation
  end

  def example_passed(passed)
    dec_indentation
    puts passed_output(passed.example)
  end

  def example_pending(pending)
    dec_indentation
    puts pending_output(pending.example,
                        pending.example.execution_result.pending_message)
  end

  def example_failed(failure)
    dec_indentation
    puts failure_output(failure.example)
  end

  def purpose_open_block(notification)
    puts purpose_output(notification.message)
    inc_indentation
  end

  def purpose_close_block(notification)
    dec_indentation
  end

  def step(notification)
    puts step_output(notification.message)
  end

  def step_open_block(notification)
    puts step_output(notification.message)
    inc_indentation
  end

  def step_close_block(notification)
    dec_indentation
  end

  def dump_failures(notification)
    return if notification.failure_notifications.empty?
    puts notification.fully_formatted_failed_examples
  end

private
  def inc_indentation
    @group_level += 1
  end

  def dec_indentation
    @group_level -= 1 if @group_level > 0
  end

  private def example_group_started_output(group)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{group.description.strip}", :bold)
  end

  private def example_started_output(example)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{example.description.strip}", :bold)
  end

  def passed_output(example)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{example.description.strip} " \
                                               "(PASSED)", :success)
  end

  def pending_output(example, message)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{example.description.strip} " \
                                               "(PENDING: #{message})", :pending)
  end

  def failure_output(example)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{example.description.strip} " \
                                               "(FAILED)", :failure)
  end

  def purpose_output(message)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{message}", :yellow)
  end

  def step_output(message)
    RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{message}", :white)
  end

  def current_indentation
    '  ' * @group_level
  end
end
