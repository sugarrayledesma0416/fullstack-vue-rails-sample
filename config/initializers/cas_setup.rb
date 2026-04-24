Rails.configuration.after_initialize do
  require 'casclient'
  require 'casclient/frameworks/rails/filter'

   CASClient::Frameworks::Rails::Filter.configure(
    cas_base_url: "#{UA_URL}/",
    validate_url: "#{UA_URL}/proxyValidate",
    enable_single_sign_out: true,
    ticket_store: :active_record_ticket_store
  )
end
