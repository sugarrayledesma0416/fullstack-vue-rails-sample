class Instructor::AnnouncementsController < RequireInstructorController
  include Uploadable::Controller

  before_action :assign_menu_coords
  skip_before_action :assign_course_sections_and_students_from_focus

  def index
    @page_title = 'Announcements'
    @announcements = Announcement.by_section(*current_focus.sections)
  end

  def assign_menu_coords
    @menu_location = 'communication'
  end

  def new
    @page_title = 'Add announcement'
    @announcement = Announcement.new
    @course_name = current_focus.course_name
  end

  def create
    @announcement = current_user.announcements.build(set_announcement_params)
    if upload_is_virus_free? && @announcement.save
      @announcement.upload_file params[:uploaded_file] if params[:uploaded_file].present?
      flash[:notice] = 'The announcement was successfully created.'
      redirect_to instructor_announcements_path(current_program.id)
    else
      @page_title = 'Add announcement'
      set_detected_virus_error_if_detected
      render :new
    end
  end

  def edit
    @page_title = 'Edit announcement'
    @announcement = Announcement.find(params[:id])
    @course_name = current_focus.course_name
  end

  def update
    @announcement = Announcement.find(params[:id])
    announcement_params = set_announcement_params(@announcement)
    if upload_is_virus_free? && @announcement.update(announcement_params)
      @announcement.upload_file params[:uploaded_file] if params[:uploaded_file].present?
      flash[:notice] = 'The announcement was successfully modified.'
      redirect_to instructor_announcements_path(current_program.id)
    else
      @page_title = 'Edit announcement'
      set_detected_virus_error_if_detected
      render :edit
    end
  end

  def destroy
    @announcement = current_user.announcements.where(id: params[:id]).first
    if @announcement
      if @announcement.update(is_archived: true)
        flash[:notice] = "The announcement '#{@announcement.title}' has been deleted."
        redirect_to instructor_announcements_path(current_program.id)
      else
        render :edit
      end
    else
      flash[:error] = "You don't have permission to modify this announcement."
      redirect_to instructor_announcements_path(current_program.id)
    end
  end

  private

  def focused_section_name
    if current_focus.focused_on_only_one_section?
      current_focus.section.name
    else
      "All sections"
    end
  end

  def set_announcement_params(announcement = nil)
    section_attrs = AnnouncementSection::AnnouncementSectionsAttributesBuilder.build(
      current_focus, current_user, announcement
    )
    announcement_params.merge(
      announcement_sections_attributes: section_attrs
    ).tap do |memo|
      if params[:uploaded_file].present?
        memo.merge!(process_uploaded_file(params[:uploaded_file], false))
      end
    end.permit(
      :title,
      :body,
      :external_link_url,
      :external_link_title,
      :file_name,
      :show_on,
      :class_cancelled,
      announcement_sections_attributes: %i[id section_id _destroy]
    )
  end

  def announcement_params
    params.require(:announcement)
  end
end
