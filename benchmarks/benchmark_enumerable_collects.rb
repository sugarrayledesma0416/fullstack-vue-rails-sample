require "benchmark"
require 'lib/patches/enumerable'
require 'rubygems'
require "active_support/inflector"

# Adjust parameters below for your typical use case.

foo = [0..100000].fill{|n|'bar'}
n = 100_000

Benchmark.bmbm do |bench|
  
  bench.report "foo.collect(&:length)" do
    n.times { foo.collect(&:length)}
  end

  bench.report "foo.collect_lengths" do
    n.times { foo.collect_length }
  end

end
