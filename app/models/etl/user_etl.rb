require 'etl'

module Etl
  module UserEtl
    def setup(params)
      Kiba.parse do
        source UserSource, params
        transform ExportTransform, params
        destination RecordDestination, model: 'User', action: params[:action]
      end
    end

    module_function :setup
    class UserSource
      def initialize(args)
        section_id = args[:section_id]
        user_ids = ::Enrollment.by_section(section_id).where(state: ['enrolled', 're-enrolled', 'marked_complete']).pluck('user_id')
        @users = ::User.where(id: user_ids)
      end

      def each
        @users.each do |user|
          yield user
        end
      end
    end
  end
end
