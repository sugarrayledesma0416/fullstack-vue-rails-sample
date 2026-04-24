
class Bank
	attr_accessor :concept, :assigned_count, :assigned_minutes, :assessment
	
	def initialize
	  @assigned_count = 0
	  @assigned_minutes = 0
    @assessment = nil # one assessement bank will have only ONE assessment
  end
	  
end
