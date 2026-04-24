class InstitutionAdmin::ExternalItemTemplatesController < RequireInstructorController
  include TemplateFocusable

  before_action :show_templates_return_bar

  def index
    section_id = params[:section_id]
    program_id = params[:program_id]
    @presenter = InstitutionAdminExternalItemsPresenter.new(section_id, program_id)

    @external_items_by_lesson = @presenter.external_items_by_lesson
  end

  def create
    section = Section.find(params[:section_id])
    course = section.course
    attrs = params.permit(
      :category_id,
      :due_date,
      :lesson_id,
      :points_possible,
      :section_id,
      :title
    ).merge(course: course)

    @external_item = GradebookEngine::ExternalItem.new(attrs)
    if @external_item.save
      flash[:notice] = 'Item successfully added.'
      render json: { status: :ok }
    else
      flash[:error] = 'Failed to save item.'
      render json: { status: :unprocessable_entity }
    end
  end

  def update
    section = Section.find(params[:section_id])
    course = section.course
    attrs = params.permit(
      :category_id,
      :due_date,
      :lesson_id,
      :points_possible,
      :section_id,
      :title
    ).merge(course: course)

    external_item = GradebookEngine::ExternalItem.find(
      params[:id], params[:section_id]
    )
    if external_item.update(attrs)
      flash[:notice] = 'Item successfully edited.'
      render json: { status: :ok }
    else
      flash.now[:error] = 'Failed to save item.'
      render json: { status: :unprocessable_entity }
    end
  end

  def delete
    external_item = GradebookEngine::ExternalItem.find(
      params[:id], params[:section_id]
    )
    external_item.destroy
    flash[:notice] = 'Item successfully deleted.'
    render json: { status: :ok }
  end
end
