class Gradebook::EnrollmentsController < RequireInstructorController

  include HasHelp
  before_action :contextual_help_url
  before_action :assign_view_type
  after_action :drop_student_from_portfolio, only: %i[update_collection]
  after_action :enroll_students_to_portfolio, only: %i[undrop_collection]

  def edit_collection
    @page_header = "Drop students"
    @page_title = "Roster"
    @return_to = vhl_return_to_sanitizer(params[:return_to])
    @droppable_students_presenter = DroppableStudentsPresenter.new(@students, @sections)
    @page_description = view_context.pluralize(@droppable_students_presenter.droppable_students_info.length, 'student')
    @no_app_shell = true
    @hide_header = true
    render layout: 'application_v3'
  end

  def update_collection
    @return_to = vhl_return_to_sanitizer(params[:return_to])
    @selected_student_info = params[:selected_student_info]

    if @selected_student_info.present?
      @drop_students = drop_students(@selected_student_info)
      redirect_to @return_to
    else
      flash.now[:error] = 'You must select at least one student.'
      @page_header = "Drop students"
      @page_title = "Roster"
      @droppable_students_presenter = DroppableStudentsPresenter.new(@students, @sections)
      @page_description = view_context.pluralize(@droppable_students_presenter.droppable_students_info.length, 'student')
      @no_app_shell = true
      @hide_header = true
      render :edit_collection, layout: 'application_v3'
    end
  end

  def undrop_collection
    @return_to = vhl_return_to_sanitizer(params[:return_to])

    if params[:dropped_student_info_key]
      dropped_student_info = info_cache.cache_get(params['dropped_student_info_key'])
      if dropped_student_info.present?
        @undropped_students = undo_drop_students(JSON.parse(dropped_student_info))
      else
        flash[:error] = 'Undo time period has expired.'
      end
    else
      flash[:error] = "Undo dropped students failed."
    end
    redirect_to(@return_to)
  end

  private

  def assign_view_type
    @view_type = (params[:view_type]) ? (params[:view_type]) : ("Gradebook")
  end

  def undo_drop_students(students)
    undropped_students = []
    undropped_failed_students = []

    recovered_seats = undo_revoke_site_license_seat(
      students,
      @course.school.guid,
      @course.school.find_district_guid
    )

    if recovered_seats['errors'].present?
      students_without_seat = recovered_seats['errors'].first.keys.map(&:to_i)
      rejected_students, students = students.partition do |student|
        students_without_seat.include?(student.id)
      end

      undropped_failed_students.concat(students)
    end

    students.each do |student_info|
      enrollment = Enrollment.undrop_student(
        student_info['user_id'],
        student_info['section_id']
      )

      if enrollment && enrollment.enrolled?
        undropped_students << enrollment.user_id
        student_info['course_id'] = @course.id
      else
        undropped_failed_students << student_info['user_id']
      end
    end

    unless undropped_students.empty? && recovered_seats['errors'].empty?
      flash[:notice_partial] = {
        partial: '/gradebook/undropped_students_flash_notice',
        locals: {
          undropped_student_count: undropped_students.count
        }
      }
    end

    unless undropped_failed_students.empty?
      flash[:error_partial] = {
        partial: '/gradebook/undropped_students_flash_error',
        locals: {
          undropped_failed_student_count: undropped_failed_students.count
        }
      }
    end
    undropped_students
  end

  def drop_students(students_info)
    return if students_info.blank?
    dropped_students = []
    dropped_student_info = []
    drop_student_failed_list = []
    school_guid = @course.school.guid
    district_guid = @course.school.find_district_guid

    students_info.each do |student_info|
      student_info = JSON.parse(student_info)
      # it shouldn't be possible to submit students with blocked
      # enrollments but we're going to filter them out anyway.
      unless student_info['blocked']
        enrollment = Enrollment.drop_student(
          student_info['user_id'],
          student_info['section_id']
        )
      end

      if enrollment && enrollment.dropped?
        dropped_students << enrollment.user_id
        student_info['course_guid'] = @course.guid
        student_info['section_guid'] = enrollment.section.guid
        student_info['user_guid'] = enrollment.user.guid
        dropped_student_info << student_info
      else
        drop_student_failed_list << student_info
      end
    end

    removed_seats = revoke_site_license_seat(dropped_student_info, district_guid)

    unless dropped_students.empty? && removed_seats['errors'].blank?
      info_key = SecureRandom.hex(16)
      info_cache.cache_put(
        info_key,
        dropped_student_info.to_json,
        5.minutes.to_i # 5 minute TTL
      )

      flash[:notice_partial] = {
        partial: '/gradebook/dropped_students_flash',
        locals: {
          dropped_student_count: dropped_students.count,
          dropped_student_info_key: info_key,
          section_name: @sections[0].name,
          return_to: params[:return_to]
        }
      }
    end

    unless drop_student_failed_list.empty?
      undo_revoke_site_license_seat(
        drop_student_failed_list,
        school_guid, district_guid
      )
      failed_students = User.find(drop_student_failed_list.map { |list| list['user_id'] })
      flash[:error_partial] = {
        partial: '/gradebook/dropped_students_flash_error',
        locals: {
          drop_student_failed_count: failed_students.count
        }
      }
    end

    dropped_student_info
  end

  def revoke_site_license_seat(dropped_students_info, district_guid)
    Maestro::User.revoke_site_license_seat(
      dropped_students_info,
      params[:program_id], district_guid
    )
  end
  private :revoke_site_license_seat

  def undo_revoke_site_license_seat(undo_students_info, school_guid, district_guid)
    Maestro::User.undo_revoke_site_license_seat(
      undo_students_info,
      params[:program_id],
      school_guid, district_guid
    )
  end
  private :undo_revoke_site_license_seat

  private def info_cache
    @info_cache ||= CacheManager.new('dropped_student_info')
  end

  private def drop_student_from_portfolio
    return if @drop_students.blank?

    section = Section.find(@drop_students[0]['section_id'])
    return unless section.course.course_share_to_portfolio?

    Portfolio::UnenrollStudentWorker.perform_async(
      @drop_students[0]['section_id'],
      @drop_students.pluck('user_id')
    )
  end

  private def enroll_students_to_portfolio
    return unless @undropped_students.present? && @sections.present?

    section = @sections.first
    return unless section.course.course_share_to_portfolio?

    Portfolio::EnrollStudentWorker.perform_async(
      section.id,
      User.find(@undropped_students).pluck('username')
    )
  end
end
