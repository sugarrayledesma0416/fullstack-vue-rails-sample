class StandardSetsController < ApplicationController
  include HttpBasicAuthHelper
  include StandardsBySets
  before_action :http_basic_authenticate

  def index
    respond_to do |format|
      format.json do
        standard_sets = StandardSet.all.select(:id, :name)
        return render status: :ok, body: standard_sets.to_json
      end
    end
  end

  def standards_by_sets
    respond_to do |format|
      format.json do
        # This is intended to be used as an internal endpoint via CMS,
        # as there are no limits in place as to how many set ids may be passed.
        return render status: :ok, body: standards_by_sets_payload.to_json
      end
    end
  end

  def grouped_by_display_name
    respond_to do |format|
      format.json do
        standard_sets_by_display_name = StandardSet.select(
          :display_name,
          :vendor_guid
        ).group_by(&:display_name)
        return render status: :ok, body: standard_sets_by_display_name.to_json
      end
    end
  end

  private def standards_by_sets_params
    params.require(:set_ids)
  end
end
