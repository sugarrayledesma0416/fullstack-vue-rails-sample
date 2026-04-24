class ResourceComponentsController < ApplicationController
  before_action :require_user

  load_and_authorize_resource

  def index
    @presenter = ResourceComponentsPresenter.new(params[:program_id]).populate
  end

  def new
    @resource_component = ResourceComponent.new
    render layout: 'full_width_body'
  end

  def create
    @resource_component = ResourceComponent.new(
      resource_component_params.merge(program_id: params[:program_id])
    )
    if @resource_component.save
      flash[:notice] = 'Your component was created successfully.'
      redirect_to action: 'index'
    else
      # :nocov:
      # resource components have no validations so this condition currently
      # cannot ever be reached.
      flash[:error] = 'Could not create component.'
      render action: 'new', layout: 'full_width_body'
      # :nocov:
    end
  end

  def edit
    @resource_component = ResourceComponent.find(params[:id])
    render layout: 'full_width_body'
  end

  def update
    @resource_component = ResourceComponent.find(params[:id])
    if @resource_component.update(resource_component_params)
      flash[:notice] = 'Your changes to the resource component were saved.'
      redirect_to action: 'index'
    else
      # :nocov:
      # resource components have no validations so this condition currently
      # cannot ever be reached.
      flash[:error] = 'Could not update the component'
      render action: 'edit', layout: 'full_width_body'
      # :nocov:
    end
  end

  def destroy
    @resource_component = ResourceComponent.find(params[:id])
    if has_associate_resources?
      flash[:error] = 'Could not delete your component because is ' \
                      'associated with a resource.'
    else
      if @resource_component.destroy
        flash[:notice] = 'Your component was deleted.'
      else
        flash[:error] =  'Could not delete your component.'
      end
    end
    redirect_to action: 'index'
  end

  private

  def has_associate_resources?
    @resource_component.resources.exists?
  end

  def resource_component_params
    params.require(:resource_component).permit(:name)
  end
end
