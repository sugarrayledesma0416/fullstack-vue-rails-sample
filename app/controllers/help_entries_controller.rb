class HelpEntriesController < ApplicationController

  before_action :require_user
  load_and_authorize_resource

  def index
    @help_entries = HelpEntry.order('page ASC')
  end

  def new
    @help_entry = HelpEntry.new
  end

  def create
    help_entry_params = params[:help_entry].merge({:created_by => current_user})
    @help_entry = HelpEntry.new(help_entry_params)
    if @help_entry.save
      flash[:notice] = 'Help entry successfully created.'
      redirect_to help_entries_path
    else
      flash.now[:error] = 'Could not create help entry.'
      render :new
    end
  end

  def edit
    @help_entry = HelpEntry.find(params[:id])
  end

  def update
    @help_entry = HelpEntry.find(params[:id])
    if @help_entry.update(params[:help_entry])
      flash[:notice] = 'Successfully updated help entry.'
      redirect_to(help_entries_path)
    else
      flash.now[:error] = 'Could not update help entry.'
      render :edit
    end
  end

  def destroy
    help_entry = HelpEntry.find(params[:id])

    if help_entry.destroy
      flash[:notice] = 'Help entry successfully deleted.'
    else
      flash[:error] = 'Could not delete help entry.'
    end

    redirect_to help_entries_path
  end
end
