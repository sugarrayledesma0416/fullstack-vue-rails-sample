require 'tasks/print_decorator'

module Support
  class TaskValidator
    include ::PrintDecorator

    attr_reader :task_name, :required_args, :arg_usage_details

    # Initializes a new instance of the TaskValidator class.
    #
    # @param task_name [String] The name of the task.
    # @param required_args [Array<String>] The required arguments for the task.
    # @param arg_usage_details [Hash] The usage details for each argument.
    # @return [TaskValidator] The new instance of the TaskValidator class with
    #                         dry_run as a required argument.
    def initialize(task_name:, required_args: [], arg_usage_details: {})
      @task_name = task_name
      @required_args = required_args << 'dry_run'
      @arg_usage_details = arg_usage_details
    end

    # Checks the usage of the task. If any required arguments are missing,
    # prints a usage message and exits.
    def check_usage
      if required_args.any? { |arg| ENV[arg].blank? }
        print_usage_message
        exit
      end
    end

    # Checks if the task should be executed in dry-run mode.
    #
    # @return [Boolean] true if the task should be executed in dry-run mode,
    #                   false otherwise.
    def dry_run?
      !execute?
    end

    # Checks if the task should be executed.
    #
    # @return [Boolean] true if the task should be executed, false otherwise.
    def execute?
      # Only execute if the dry-run flag is explicitly false.
      ENV['dry_run'] == 'false'
    end

    # Prints the usage message for the task.
    private def print_usage_message
      msg = "Usage: #{task_name} #{usage_details}"
      print_message(msg, 'H1', 0, 'red')
    end

    # Returns the usage details for the task's required and defined arguments.
    #
    # @return [String] The usage details for the task.
    private def usage_details
      (defined_usage_details + default_usage_details).join(' ')
    end

    # Returns an array of Strings for required args that have usage details
    # defined. Strings are in the form defined by `arg_usage`.
    #
    # @return [Array<String>] The defined usage details for the task.
    private def defined_usage_details
      arg_usage_details.map { |k, v| arg_usage(k, v[:example], v[:default]) }
    end

    # Returns an array of Strings for required args that do not have usage
    # details defined. Strings are in the form defined by `arg_usage`.
    #
    # @return [Array<String>] The default usage details for the task.
    private def default_usage_details
      undefined_args.map do |arg|
        if (arg == 'dry_run')
          arg_usage(arg, 'true|false', 'true')
        else
          arg_usage(arg, 'value')
        end
      end
    end

    # Returns the required args for the task whose usage details are not defined.
    #
    # @return [Array<String>] The required arguments without usage details.
    private def undefined_args
      required_args.select { |arg| !arg_usage_details.keys.include?(arg) }
    end

    # Returns the usage details for an argument in the following forms depending
    # on the parameters provided:
    #   arg=<provided_value> [default: provided_default_value]
    #   arg=<provied_value>
    #   arg=<value> [default: provided_default_value]
    #   arg=<value>
    # For dry_run, returns the usage details in the form:
    #   dry_run=<true|false> [default: true]
    #
    # @param arg [String] The name of the argument.
    # @param value [String, nil] The example value for the argument.
    # @param default_value [String, nil] The default value for the argument.
    # @return [String] The usage details for the argument.
    private def arg_usage(arg, value = nil, default_value = nil)
      value = value.nil? ? 'value' : value
      default_value = default_value.nil? ? '' : " [default: #{default_value}]"

      "#{arg}=<#{value}>#{default_value}"
    end
  end
end
