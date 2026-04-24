module CustomMatchers
  UUID_VALUE_REG_EXP = \
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b/.freeze
  UUID_REG_EXP = /^#{UUID_VALUE_REG_EXP}$/.freeze

  RSpec::Matchers.define :be_a_uuid do |_expected|
    match do |actual|
      UUID_REG_EXP.match(actual)
    end
  end
end
