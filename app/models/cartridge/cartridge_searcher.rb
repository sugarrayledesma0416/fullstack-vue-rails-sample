module Cartridge
  class CartridgeSearcher
    attr_accessor :program

    def initialize(program)
      self.program = program
    end

    def cartridges_by_version
      @cartridges_by_version ||= CartridgeBuildStatus::VERSIONS.to_h do |version|
        cartridge = CartridgeBuildStatus.where(
          cc_version: version,
          program_id: program.id
        ).last
        # Did the last cartridge creation failed?
        last_failed_cartridge = cartridge if cartridge&.failure?
        cartridge = CartridgeBuildStatus.success.where(
          cc_version: version,
          program_id: program.id
        ).last

        [
          version,
          {
            last_failed_cartridge: last_failed_cartridge,
            cartridge: cartridge
          }
        ]
      end
    end
  end
end
