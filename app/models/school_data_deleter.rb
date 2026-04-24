class SchoolDataDeleter
  attr_reader :school_id

  def initialize(school_id)
    @school_id = school_id
  end

  def delete_school_data
    # Users must be deleted *before* courses because the school-scoped
    # user data deletion relies upon course and section records to
    # associate various other records with a school.
    delete_users
    delete_courses
    delete_shared_library_activities
    delete_school_users
    delete_gradebook_school_data
    delete_lossless_recordings
  end

  def delete_courses
    Course.where(school_id: school_id).pluck(:id).each do |course_id|
      CourseDataDeleter.new(course_id).delete_course_data
    end
  end

  def delete_school_users
    SchoolUser.where(school_id: school_id).destroy_all
  end

  def delete_shared_library_activities
    SharedLibraryActivity.where(school_id: school_id).destroy_all
  end

  def delete_users
    SchoolUser.where(school_id: school_id).pluck(:user_id).each do |user_id|
      UserDataDeleter.new(user_id, school_id: school_id).delete_user_data
    end
  end

  def delete_gradebook_school_data
    GradebookEngine::GradebookAPI.delete_school_data(school_id)
  end

  def delete_lossless_recordings
    unless Lossless::Client.new.delete_school_data(school_id)
      raise "failed to delete lossless recordings for school #{school_id}"
    end
  end
end
