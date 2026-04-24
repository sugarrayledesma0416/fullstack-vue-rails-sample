class FindCourse
  extend LightService::Action
  expects :course_id
  promises :course

  ALLOWED_COURSE_SCOPES = %i(enterprise)

  executed do |context|
    course = self.course_group(context).find_by(id: context.course_id)

    if course.present?
      context.course = course
      next context
    else
      context.fail!('Unable to find course.')
    end
  end

  def self.course_group(context)
    return Course if context[:course_scope].nil? || ALLOWED_COURSE_SCOPES.exclude?(context[:course_scope])

    Course.public_send(context[:course_scope])
  end
end
