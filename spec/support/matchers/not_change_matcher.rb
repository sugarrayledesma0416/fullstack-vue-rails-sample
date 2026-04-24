module Matchers
  module NotChangeMatcher
    # Define the negated matcher to be able to test that multiple mutable state
    # did not change.
    # https://relishapp.com/rspec/rspec-expectations/docs/built-in-matchers/change-matcher
    # https://stackoverflow.com/questions/36723893/expect-multiple-not-to-change-expectations-in-rspec/36724913
    RSpec::Matchers.define_negated_matcher :not_change, :change
  end
end
