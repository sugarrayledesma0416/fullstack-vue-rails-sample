require 'rails_helper'

describe UnleashContextSetup do
  controller do
    include UnleashContextSetup

    def index
      render plain: 'empty method'
    end
  end

  let(:user_id) { 123 }
  let(:program) { instance_double(Program, id: 456, language_code: 'es') }
  let(:unleash_context) { instance_double(Unleash::Context) }

  before do
    session[:user_id] = user_id
    allow(controller).to receive(:current_program).and_return(program)
    # Don't stub these methods as they're used internaly by Rails
    # and we need to test the actual values passed to Unleash::Context.new
  end

  it 'creates an Unleash context with the correct parameters' do
    # Use allow instead of expect to avoid strict argument matching
    # This way we can verify the context is created without worrying about exact session IDs
    allow(Unleash::Context).to receive(:new).and_return(unleash_context)

    get :index

    expect(assigns(:unleash_context)).to eq(unleash_context)
    # Verify Unleash::Context was initialized with a hash containing the expected keys
    expect(Unleash::Context).to have_received(:new).with(
      hash_including(
        userId: user_id,
        properties: hash_including(
          programId: program.id.to_s,
          languageCode: program.language_code
        )
      )
    )
  end

  context 'when current_program is nil' do
    before do
      allow(controller).to receive(:current_program).and_return(nil)
    end

    it 'creates an Unleash context with nil program_id and language_code' do
      allow(Unleash::Context).to receive(:new).and_return(unleash_context)

      get :index

      expect(assigns(:unleash_context)).to eq(unleash_context)
      # Verify Unleash::Context was initialized with a hash containing the expected keys
      expect(Unleash::Context).to have_received(:new).with(
        hash_including(
          userId: user_id,
          properties: {}
        )
      )
    end
  end

  context 'when @current_program instance variable is not set' do
    before do
      allow(controller).to receive(:current_program).and_return(nil)
      # Ensure the instance variable is not set
      controller.instance_variable_set(:@current_program, nil)
    end

    it 'creates an Unleash context with nil program data' do
      allow(Unleash::Context).to receive(:new).and_return(unleash_context)

      get :index

      expect(assigns(:unleash_context)).to eq(unleash_context)
      expect(Unleash::Context).to have_received(:new).with(
        hash_including(
          userId: user_id,
          properties: {}
        )
      )
    end
  end

  context 'when @current_program instance variable is set' do
    before do
      allow(controller).to receive(:current_program).and_return(program)
      # Set the instance variable to simulate it being loaded
      controller.instance_variable_set(:@current_program, program)
    end

    it 'creates an Unleash context with the program data' do
      allow(Unleash::Context).to receive(:new).and_return(unleash_context)

      get :index

      expect(assigns(:unleash_context)).to eq(unleash_context)
      expect(Unleash::Context).to have_received(:new).with(
        hash_including(
          userId: user_id,
          properties: hash_including(
            programId: program.id.to_s,
            languageCode: program.language_code
          )
        )
      )
    end
  end

  it 'includes the concern in controllers that include it' do
    expect(controller.class.included_modules).to include(UnleashContextSetup)
  end

  it 'adds the set_unleash_context before_action' do
    before_actions = controller.class._process_action_callbacks.select { |cb| cb.kind == :before }
    before_action_names = before_actions.map(&:filter)

    expect(before_action_names).to include(:set_unleash_context)
  end
end
