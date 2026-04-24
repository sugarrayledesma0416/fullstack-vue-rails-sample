module Steppable
  
  attr_writer :current_step

  def current_step
    @current_step || steps.first
  end

  def next_step  
    steps[steps.index(current_step)+1] || steps.first 
  end
  
  def previous_step  
    steps[steps.index(current_step)-1]
  end    

  def first_step?  
    current_step == steps.first  
  end
  
  def last_step?  
    current_step == steps.last  
  end

  def step_class(step)
    return 'current' if step == current_step
    return 'complete' if steps.index(step) < steps.index(current_step)
    ''
  end
  
  def current_step?(step)
    current_step == step
  end

end