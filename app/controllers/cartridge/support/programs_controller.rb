module Cartridge
  module Support
    class ProgramsController < ApplicationController
      before_action :require_user
      before_action :require_common_cartridge_creator_role

      def index
        common_cartridge_program_ids = Maestro::PackageContent.with_common_cartridge
                                                              .map(&:program_id)
        @programs = Program.where(maestro_version: 3, id: common_cartridge_program_ids)
                           .order(:title)
      end

      private def require_common_cartridge_creator_role
        unless current_user.is_common_cartridge_creator?
          redirect_to ua_home_path
        end
      end
    end
  end
end
