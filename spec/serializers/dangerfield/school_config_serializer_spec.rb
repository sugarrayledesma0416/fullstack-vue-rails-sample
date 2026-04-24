RSpec.describe Dangerfield::SchoolConfigSerializer do
  subject(:dangerfield_serializer) { school_config.dangerfield_serializer }

  let(:school_config) { build_stubbed(:school_config) }

  it 'does not serialize school_id attribute' do
    expect(JSON.parse(dangerfield_serializer.to_json)).not_to have_key('school_id')
  end

  it 'does not serialize web_token attribute' do
    expect(JSON.parse(dangerfield_serializer.to_json)).not_to have_key('web_token')
  end

  it 'does not serialize institute_short_name attribute' do
    expect(JSON.parse(dangerfield_serializer.to_json)).not_to have_key('institute_short_name')
  end

  it 'serializes correctly' do
    excluded_attributes = %i[school_id web_token institute_short_name]

    expect(JSON.parse(dangerfield_serializer.to_json))
      .to eq(school_config.as_json(except: excluded_attributes))
  end
end
