class Setting::Definition
  def self.inherited(base)
    build_to_s(base)
    register_symbol(base)
  end

  def self.get_default(name)
    @@defaults[name.to_s]
  end

  def self.from_symbol(symbol)
    @@symbol_hash[symbol]
  end

  # Pass through ActiveRecord validations to Setting class.
  def self.method_missing(method_name, *args)
    if method_name.to_s =~ /^validates_(.*)$/
      definition_name = self.to_s # need to evaluate this before we define the proc, or self will be the wrong thing when proc runs
      validation_condition = Proc.new { |setting|  setting.name == definition_name }
      params = nil
      if args.last.is_a? Hash
        params = args.last
      else
        params = {}
        args.push params
      end
      params.merge!(:if => validation_condition)

      case method_name
      when :validates_inclusion_of
        params.merge!(:message => "'%{value}' is not a valid '#{self.to_s}'.")
      end
      Setting.send(method_name, *args)
    else
      super
    end
  end

  # Shorthand to creating a validation requiring value be one of the defined constants.
  def self.validates_inclusion_in_constants
    constant_values = constants.map{|constant_name| const_get constant_name}
    validates_inclusion_of :value, :in => constant_values
  end

  # Dereference a symbol using the constants defined.
  def self.sanitize_value(value)

    return value unless value.is_a? Symbol

    constant_name = value.upcase
    if constants.include? constant_name
      value = const_get(constant_name)
    end

    value
  end

  private

  # Builds a to_s function that matches our criteria.
  # e.g. Setting::Gradebook::CategoryView.to_s => 'gradebook__category_view'
  def self.build_to_s(base)
    base_class_names = base.to_s.split("::")
    base_class_names.shift if base_class_names.first == "Setting"
    setting_name = base_class_names.map{|class_name| class_name.underscore}.join("__")

    base.instance_eval(<<-EOT, __FILE__, __LINE__)
      def self.to_s
        "#{setting_name}"
      end
    EOT
  end

  def self.register_symbol(base)
    symbol = base.to_s.to_sym
    @@symbol_hash ||= {}
    @@symbol_hash[symbol] = base
  end

  def self.default(value)
    @@defaults ||= {}
    @@defaults[self.to_s] = value
  end
end
