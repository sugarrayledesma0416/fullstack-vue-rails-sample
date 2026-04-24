# coding:utf-8
describe Ua::RolesUsersController do
  describe '#create' do
    before do
      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)

      allow(VHLMonitor).to receive(:notify)

      @user = build_stubbed(:user)
      @role = double(Role)
      allow(::User).to receive(:find_by_guid).and_return(@user)

      allow(Role).to receive(:find_by_name).and_return(@role)
      allow(@user.roles).to receive(:<<)

      @role_name = 'valid_role_name'
      @valid_params = { 'user_guid' => @user.guid, 'role_name' => @role_name, :format => :json }
    end

    def do_request(params = {})
      post :create, params: @valid_params.merge(params)
    end

    it_should_behave_like 'an active resource controller action that rescues and reports errors'

    context 'when invalid params are specified,' do
      it 'should respond with an ActiveResource::ServerError status code if no user exists with specified user_id' do
        allow(::User).to receive(:find_by_guid).and_return(nil)
        do_request
        message = "no user found with guid '#{@user.guid}'"
        expect(response.body).to include "\"message\":\"#{message}\""
        expect(response.status).to eq(503)
      end

      it 'should respond with an ActiveResource::ServerError status code if role name is nil' do
        do_request('role_name' => nil)
        message = 'role_name cannot be blank'
        expect(response.body).to include "\"message\":\"#{message}\""
        expect(response.status).to eq(503)
      end

      it 'should respond with an ActiveResource::ServerError status code if role name is blank' do
        do_request('role_name' => '')
        message = 'role_name cannot be blank'
        expect(response.body).to include "\"message\":\"#{message}\""
        expect(response.status).to eq(503)
      end
    end

    context 'when valid params are specified,' do
      it 'looks for the role with the specified name' do
        expect(Role).to receive(:find_by_name).with(@role_name).and_return(@role)
        do_request
      end

      context 'when a role already exists with the specified name' do
        it 'grants the user that role' do
          allow(Role).to receive(:find_by_name).and_return(@role)
          expect(@user.roles).to receive(:<<).with(@role)
          do_request
        end
      end

      context 'when no role already exists with the specified name' do
        it 'creates and grants the user the role' do
          allow(Role).to receive(:find_by_name).and_return(nil)
          expect(Role).to receive(:new).with(name: @role_name).and_return(@role)
          expect(@user.roles).to receive(:<<).with(@role)
          do_request
        end
      end
    end
  end
end
