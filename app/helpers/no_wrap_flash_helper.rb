module NoWrapFlashHelper
  CONTROLLERS_WITH_NO_WRAP = %w[created_activities].freeze

  def no_wrap_class_for_flash
    CONTROLLERS_WITH_NO_WRAP.include?(controller_name) ? 'u-txt-nowrap' : ''
  end
end
