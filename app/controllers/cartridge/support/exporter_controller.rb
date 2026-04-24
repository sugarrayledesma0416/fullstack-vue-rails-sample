module Cartridge
  module Support
    class ExporterController < ApplicationController
      before_action :require_user
      before_action :require_common_cartridge_creator_role

      def index
        @search = Cartridge::CartridgeSearcher.new(program)
      end

      def export
        if params[:cc_version].present?
          Cartridge::ExporterWorker.perform_async(
            program.id,
            current_user.id,
            params[:cc_version]
          )
          flash[:notice] = "The common cartridge export for #{program.title} " \
                           "version #{params[:cc_version]} has been scheduled."
        end
        redirect_to cartridge_support_program_exporter_path(program_id: program.id)
      end

      private def program
        @program ||= Program.find(params[:program_id])
      end

      private def require_common_cartridge_creator_role
        unless current_user.is_common_cartridge_creator?
          redirect_to ua_home_path
        end
      end
    end
  end
end
