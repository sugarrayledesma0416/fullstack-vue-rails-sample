# encoding: utf-8
describe DataStorable, core: true do
  def setup_store_constant(val)
    M3::Application.configure do
      config.submission_datastore = val
    end
  end
  describe '#build' do
    let(:attempt) { double(Attempt) }
    it 'returns Api data store by default' do
      datastore = described_class.build(attempt)
      expect(datastore.is_a?(ResultsApiDatastore)).to be_truthy
    end

    it 'returns Xml datastore when xml parameter passed' do
      datastore = described_class.build(attempt, 'xml')
      expect(datastore.is_a?(ResultsXmlDatastore)).to be_truthy
    end

    it 'returns Api datastore when api parameter passed' do
      datastore = described_class.build(attempt, 'api')
      expect(datastore.is_a?(ResultsApiDatastore)).to be_truthy
    end
  end
end
