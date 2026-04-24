describe 'Configuring the Maestro Client' do
  it "accepts configuration parameters for factory namespace and service namespace in a configure block" do
    Maestro.configure do |config|
      config.factory_namespace = Maestro
      config.service_namespace = Maestro::Service
    end
    expect(Maestro.configuration.factory_namespace).to eq(Maestro)
    expect(Maestro.configuration.service_namespace).to eq(Maestro::Service)
  end

  describe 'Maestro Core inheritance' do
    module A
      extend MaestroCore::Setup
    end
    module B
      extend MaestroCore::Setup
    end

    it 'does not override configurations for other modules that inherit the setup' do
      A.configure do |config|
        config.factory_namespace = 'hi'
      end

      B.configure do |config|
        config.factory_namespace = 'blah'
      end

      expect(A.configuration.factory_namespace).to eq('hi')
      expect(B.configuration.factory_namespace).to eq('blah')
    end
  end

end
