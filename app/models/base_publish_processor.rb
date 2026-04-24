#  encoding: utf-8

module BasePublishProcessor

  attr_accessor :request, :action, :errors, :status, :model_to_publish, :desired_id, :exception_backtrace
  attr_writer   :object_to_publish

  def initialize(model_to_publish, params)
    self.request = params
    self.errors = []
    self.status = :unprocessable_entity
    self.model_to_publish = model_to_publish
    self.desired_id = nil
    self.exception_backtrace = nil
  end

  def filtered_params
    request.reject{|key, value| !valid_attributes.include? key.to_sym }
  end
  private :filtered_params

  def process_request
    begin
      validate_params
      perform
    rescue StandardError => e
      # Don't let errors we care about get silently eaten in test runs
      if Rails.env.test?
        # But ignore the error we throw on purpose in specific tests, to
        # not clutter up the test output.
        if !defined?(BasePublishTestError) || !e.is_a?(BasePublishTestError)
          puts e.inspect
        end
      end
      e.message << " - Submitted Parameters: #{request}"
      e.message << " - Error line: #{e.backtrace[0]}"
      Rails.logger.error(e)
      Rails.logger.error(e.backtrace[0])
      VHLMonitor.notify(e)
      self.errors << e.message
      self.exception_backtrace = e.backtrace
      self.status = :unprocessable_entity
    end
    self
  end

  def message
    status_message = 'success'
    if errors.any?
      status_message = errors.join(', ')
    end

    { 'action' => action.to_s, 'message_text' => status_message }.tap do | message_hash |
      message_hash['backtrace'] = exception_backtrace if exception_backtrace.present?
    end
  end

  def perform
    unless errors.present?
      create_or_update_publishable
      set_status_and_errors
    end
  end
  private :perform

  def object_to_publish
    return @object_to_publish if defined?(@object_to_publish)
    self.desired_id ||= request.delete('id')
    @object_to_publish = model_to_publish.find_by_id(desired_id)
  end

  def create_or_update_publishable
    if object_to_publish.present?
      self.action = :update
      object_to_publish.update(filtered_params)
    else
      self.action = :create
      self.object_to_publish = model_to_publish.new(filtered_params)
      object_to_publish.id = desired_id if desired_id
      object_to_publish.save
    end
  end
  private :create_or_update_publishable

  def set_status_and_errors
    if errors.empty? && object_to_publish.errors.empty?
      self.status = :ok
    elsif object_to_publish.errors.any?
      self.errors.concat(object_to_publish.errors.full_messages)
    end
  end
  private :set_status_and_errors

  def validate_params
    required_attributes.each do |attribute|
      if request[attribute.to_s].blank?
        self.errors << "Data field '#{attribute}' for #{model_to_publish} cannot be blank.\nSupplied params: #{request}"
      end
    end
  end
  private :validate_params

  def required_attributes
    self.class::REQUIRED_ATTRIBUTES
  end
  private :required_attributes

  def valid_attributes
    self.class::VALID_ATTRIBUTES
  end
  private :valid_attributes
end
