# if Rails.version.to_s < '5.0'
#   BigDecimal.define_singleton_method(:new) do |*args, **kwargs|
#     BigDecimal(*args, **kwargs)
#   end
# else
#   puts "Monkeypatch for BigDecimal.new in #{__FILE__} no longer needed"
# end
