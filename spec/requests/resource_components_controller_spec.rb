require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe ResourceComponentsController do
  let(:program) { create(:program) }
  let(:user) { create(:user) }
  let(:original_attrs) { { name: 'original name' } }
  let(:resource_editor_role) { Role.create!(name: Role::RESOURCE_EDITOR) }

  describe 'POST /create' do
    let(:target_path) { resource_components_path(program_id: program.id) }

    def do_request
      post(target_path, params: { resource_component: original_attrs })
    end

    include_examples 'require logged in user'

    it 'denies access to users without a resource editor role' do
      log_in_user(user)
      do_request
      expect(response).to redirect_to '/403'
    end

    context 'with a logged in resource editor,' do
      before do
        user.roles << resource_editor_role
        log_in_user(user)
      end

      it 'requires a root key :resource_component in the params' do
        expect { post(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: resource_component/
        )
      end

      it 'creates a new resource component record with valid params' do
        do_request

        expect(response).to redirect_to(
          resource_components_path(program_id: program.id)
        )

        resource_component = ResourceComponent.last
        expect(resource_component).to have_attributes(original_attrs)

        expect(flash[:notice]).to match(/created successfully/)
      end
    end
  end

  describe 'PUT /update' do
    let(:resource_component) { create(:resource_component, original_attrs) }
    let(:target_path) do
      resource_component_path(
        id: resource_component.id,
        program_id: program.id
      )
    end
    let(:new_attrs) { { name: 'new name' } }

    def do_request
      put(target_path, params: { resource_component: new_attrs })
    end

    include_examples 'require logged in user'

    it 'denies access to users without a resource editor role' do
      log_in_user(user)
      do_request
      expect(response).to redirect_to '/403'
    end

    context 'with a logged in resource editor,' do
      before do
        user.roles << resource_editor_role
        log_in_user(user)
      end

      it 'requires a root key :resource_component in the params' do
        expect { put(target_path) }.to raise_error(
          ActionController::ParameterMissing,
          /param is missing or the value is empty: resource_component/
        )
      end

      it 'creates a new resource component record with valid params' do
        do_request

        expect(response).to redirect_to(
          resource_components_path(program_id: program.id)
        )

        resource_component.reload
        expect(resource_component).to have_attributes(new_attrs)

        expect(flash[:notice]).to match(/changes.*were saved/)
      end
    end
  end
end
