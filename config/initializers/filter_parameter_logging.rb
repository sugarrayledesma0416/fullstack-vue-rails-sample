# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.configuration.filter_parameters += %i[
  current_password
  password
  password_confirmation
]
