module Xapi
  class BasicAuthCredential
    include VhlAwsRecord
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    TIME_TO_LIVE_SEC = 24 * 60 * 60

    set_table_name(prefix_table_name('xapi-basic-auth-credentials'))

    string_attr :credentials, hash_key: true
    string_attr :vhlcentral_guid
    epoch_time_attr :creation_time
    epoch_time_attr :expires_at

    BASE_CREDENTIAL_CHECK_ARGS = {
      table_name: table_name,
      condition_expression: 'expires_at > :current_expires_at',
      update_expression: 'SET expires_at = :new_expires_at',
      # We aren't interested in any attributes, so just ask dynamodb to return nothing
      return_values: 'NONE'
    }.freeze

    # The credentials are valid if they exist in the dynamodb table and
    # if their expiration date if still valid.
    # If so, we extend the expiration date.
    def self.valid_credentials?(username, password)
      credentials = "#{username}:#{password}"
      dynamodb_client.update_item(
        BASE_CREDENTIAL_CHECK_ARGS.merge(
          key: { credentials: credentials },
          expression_attribute_values: {
            ':current_expires_at' => Time.now.utc.to_i,
            ':new_expires_at' => (Time.now.utc + TIME_TO_LIVE_SEC).to_i
          }
        )
      )
      true
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
      # Only consider ConditionalCheckFailedException as invalid credentials.
      false
    end

    def self.generate_credentials(user)
      now = Time.now.utc.to_i
      credentials = "#{SecureRandom.uuid}:#{SecureRandom.uuid}"
      new(
        credentials: credentials,
        creation_time: now,
        expires_at: now + TIME_TO_LIVE_SEC,
        vhlcentral_guid: user.guid
      ).save!
      "Basic #{::Base64.strict_encode64(credentials)}"
    end
  end
end
