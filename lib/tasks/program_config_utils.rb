# Provides utility methods for working with program configurations.
module ProgramConfigUtils
  include ::PrintDecorator

  # Copies an existing program configuration and does not raise errors when
  # validations fail.
  #
  # @param program_config [ProgramConfig] The program configuration to copy.
  # @param manager_username [String] The username of the manager who authorized the copy.
  # @return [ProgramConfig] The copied program configuration.
  def copy(program_config:, manager_username:)
    begin
      ProgramConfig.create(
        program_id: program_config.program_id,
        datastore_json: program_config.datastore_json,
        creator_id: creator(username: manager_username).id
      )
    end
  end

  # Retrieves an authorized program configuration record creator based on username.
  # If no authorized creator exists, the method prints an error message and exits.
  #
  # @param username [String] The username of the proposed creator.
  # @return [User] The creator of the program configuration.
  private def creator(username:)
    return @creator if @creator&.username == username

    @creator = authorized_manager(username:)

    return @creator unless @creator.nil?

    error = "Invalid User: '#{username}' is not allowed to change program config. " \
      "The #{Role::PROGRAM_CONFIG_MANAGER} role is required."
    print_message(error, 'H1', 0, 'red')
    exit
  end

  # Retrieves an active authorized manager or nothing based on the username.
  #
  # @param username [String] The username of the manager.
  # @return [User] The authorized manager or nil if not found.
  private def authorized_manager(username:)
    User.joins(:roles)
        .find_by(
          username:,
          roles: { name: Role::PROGRAM_CONFIG_MANAGER },
          active: true
        )
  end
end
