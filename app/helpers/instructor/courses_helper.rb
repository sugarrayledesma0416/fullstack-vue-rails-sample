module Instructor::CoursesHelper

  def category_max_attempts(category)
    category.unlimited_attempts? ? 'unlimited' : category.max_attempts.to_s
  end

end
