class Ua::ProgramsController < Ua::ActiveResourceController
  def update
    respond_to do |format|
      format.json do
        program = Program.find_by_id(params[:id])

        if program
          program.attributes = permitted_params
        else
          program = Program.new(permitted_params)
          program.id = params[:id]
        end

        if program.save
          render json: program
        else
          # :nocov:
          # This branch cannot be reached because Program model has no
          # validations.
          render json: program.errors, status: :unprocessable_entity
          # :nocov:
        end
      end
    end
  end

  def permitted_params
    params.permit(*Program.column_names.reject { |col| col == 'id' })
  end
end
