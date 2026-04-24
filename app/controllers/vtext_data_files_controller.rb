class VtextDataFilesController < ApplicationController
  before_action :require_user
  before_action :initialize_generator

  def index
  end

  def create
    if Program.exists?(id: params[:program_id])
      @data_generator = VtextDataGenerator.new(params[:program_id])
      send_data(
        @data_generator.generate,
        type: 'text/csv; charset=windows-1252; header=present',
        disposition: "attachment; filename=#{@data_generator.file_name}"
      )
    else
      flash[:error] = "The program with ID #{params[:program_id]} does not exist."
      render :index
    end
  end

  private def initialize_generator
    authorize! :vtext_generate, VtextDataFilesController
  end
end
