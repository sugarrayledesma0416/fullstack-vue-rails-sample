module CartridgeViewable
  extend ActiveSupport::Concern

  private def restrict_cartridge_user?
    current_user
  end
end
