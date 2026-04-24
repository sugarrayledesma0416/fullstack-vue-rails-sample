#  encoding: utf-8

class LinkedMediaItemStub

  attr_accessor :activity_id, :media_item, :media_item_id, :line, :desired_media_type,
                :status, :desired_media_item_id, :warnings, :spec, :preview_attrs

  def initialize(params)
    @activity_id = params[:activity_id] if params[:activity_id]
    @media_item_id = params[:media_id] if params[:media_id]
    @media_item = params[:media_item] if params[:media_item]
    @line = params[:line] if params[:line]
    @desired_media_type = params[:desired_media_type] if params[:desired_media_type]
    @status = params[:status] if params[:status]
    @desired_media_item_id = params[:desired_media_item_id] if params[:desired_media_item_id]
    @warnings = params[:warnings] if params[:warnings]
    @spec = params[:spec] if params[:spec]
    @preview_attrs = params[:preview_attrs] if params[:preview_attrs]
  end

  def json_attributes
    %i[activity_id media_item media_item_id line desired_media_type status desired_media_item_id warnings spec preview_attrs]
  end

  def to_hash
    {
      'MediaLink' => json_attributes.each_with_object({}) do |attr, memo|
                        memo[attr.to_s] = self.send(attr)
                      end
    }
  end

  def open?
    true
  end
end
