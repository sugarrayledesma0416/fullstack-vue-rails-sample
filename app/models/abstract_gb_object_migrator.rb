class AbstractGbObjectMigrator
  def initialize(params)
    @params = params.symbolize_keys!
  end

  def migrate_objects
    Kiba.run(AbstractGbObjectMigrator.const_get("Etl::#{model_name}Etl").setup(@params))
  rescue StandardError => e
    VHLMonitor.notify(e)
    raise e
  end

  # Called from a sidekiq job to update a single instance of a GB
  # model from an M3 object
  def update_object
    # params contain M3 model name, action to take, and the M3 ids
    # required to identify the object in the gradebook;
    # after getting the attributes required for the object, it does the same
    # work as the ETL import migration process. Either adds or updates
    # a GB model or deletes it.
    @m3_model_name = @params[:model_name]
    @action = @params[:action]
    gb_model_type =
      case @m3_model_name
      when 'Enrollment' then GradebookEngine::SectionUser
      when 'Concept' then GradebookEngine::Strand
      else
        "GradebookEngine::#{@m3_model_name}".constantize
      end

    # Converts a class like GradebookEngine::ModelName to 'ModelName'. For
    # gradebook models nested within the namespace of a module, converts
    # GradebookEngine::Namespace::ModelName to 'Namespace::ModelName'
    gb_model_name = gb_model_type.to_s.split('::')[1..-1].join('::')

    gb_import_model = "Etl::GradebookImport::#{gb_model_name}".constantize.new(
      gb_model_type, @action, attributes_for_action
    )
    # if the record is deleted, the following method will return nil.
    # that is a signal to halt processing of this record
    # (which is extremely important when called during ETL process)
    result = gb_import_model.get_or_delete_record
    begin
      result&.save!
      # sometimes the instance gets added to the db by another sidekiq process
      # between the time of the lookup and the save that occurs here;
      # rescue, recover and log this case because we don't want to generate a Rollbar
    rescue ActiveRecord::RecordNotUnique => e
      gb_import_model.log_etl_error(
        'database-write-error',
        e,
        result.attributes,
        result.class.name
      )
    end
  end

  def attributes_for_action
    if @action == 'delete'
      # everything we need is in the params but need them to be strings not symbols
      @params.stringify_keys
    else
      m3_obj = m3_model_name.constantize.unscoped.find(@params[:id])
      attributes_for_gb_update(m3_obj)
    end
  end

  # if necessary, subclasses can merge in attributes
  # from related objects by overriding this method
  # @see GbAssignmentMigrator, GbLessonMigrator
  def attributes_for_gb_update(m3_obj)
    m3_obj.attributes
  end

  def m3_model_name
    @m3_model_name
  end
end
