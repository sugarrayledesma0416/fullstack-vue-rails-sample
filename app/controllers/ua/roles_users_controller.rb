module Ua
  class RolesUsersController < Ua::ActiveResourceController

    def create
      respond_to do |format|
        format.json do
          user = ::User.find_by_guid(params[:user_guid])
          raise "no user found with guid '#{params[:user_guid]}'" unless user
          raise "role_name cannot be blank" if params[:role_name].blank?

          role = Role.find_by_name(params[:role_name])
          role ||= Role.new(name: params[:role_name])
          user.roles << role

          render json: { user_guid: user.guid, role_name: params[:role_name] }
        end
      end
    end

  end
end
