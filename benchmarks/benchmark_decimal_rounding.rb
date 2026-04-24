require 'benchmark'
require 'bigdecimal'

def to_s_with_round_to(num, places)
  ( (num * 100  * 10**places).round.to_f / 10**places ).to_s
end

def sprintf_with_big_decimal(num)
  ('%.1f' % BigDecimal.new((num* 100).to_s) )
end

num = 0.8915
TIMES = 1000

Benchmark.bmbm do |r|
  r.report("to_s_with_round_to") { TIMES.times { to_s_with_round_to(num, 1) } }
  r.report("sprintf_with_big_decimal") { TIMES.times { sprintf_with_big_decimal(num) } }
end