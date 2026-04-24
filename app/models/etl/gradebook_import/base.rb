module Etl
  module GradebookImport
    class Base
      include EtlLogger
      include StringSanitizer
      def common_fields
        %w(created_at updated_at)
      end

      def model_attr_names
        %w(created_at updated_at)
      end

      def initialize(model_type, model_action, new_attrs)
        @model_type = model_type
        @model_action = model_action
        @new_attrs = new_attrs
      end

      private def current_record
        return @current_record if defined?(@current_record)
        @current_record = find_existing
      end

      def special_attribute_handling
        # empty implementation, overridden by child classes if needed
      end

      def get_or_delete_record
        if @model_action == 'delete'
          handle_record_deletion
          return
        end
        # lookup any existing record
        current_record if @model_action == 'add_update'
        # if object is not found OR this is an import
        # then we need to create a new record
        @current_record = @model_type.new if current_record.nil? || @model_action == 'import'
        special_attribute_handling
        assign_attrs
        current_record
      end

      def find_existing
        # not using "find(<id>) because it will throw an
        # ActiveRecord::RecordNotFound exception and
        # not finding an existing instance is not an error condition
        @model_type.where(id:@new_attrs['id']).first
      end

      def assign_attrs
        model_attrs_list = @new_attrs.slice(*model_attr_names)
        model_attrs_list.each do |k, v|
          @current_record[k] = v
        end
      end

      # if subclass has different attrs than id
      # required for deletion than it needs to override this method
      def handle_record_deletion
        symbol_keys_hash = @new_attrs.deep_symbolize_keys
        @model_type.delete(symbol_keys_hash)
        log_deletion_event(symbol_keys_hash)
      end

      # logs the model type and the key/values
      # that identify the instance that was deleted
      def log_deletion_event(symbol_keys_hash)
        identifying_values = symbol_keys_hash.slice(*@model_type.identity_fields)
        log_etl_info('delete-record',
                     "#{identifying_values}",
                     @model_type.name
                    )
      end
    end
  end
end
