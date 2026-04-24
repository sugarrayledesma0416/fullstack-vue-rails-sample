class SectionLearningTrackSerializer < ActiveModel::Serializer
  attributes :activities, :course_package_ids, :description, :strands,
             :first_unit_id, :last_unit_id, :units, :categories,
             :insufficient_license_groups

  def categories
    object.categories.inject({}) do |memo, pair|
      k, v = pair
      json = CategorySerializer.new(v).as_json
      # HACK: Don't specify scoring ruleset attributes in learning
      # tracks.
      json.delete(:current_scoring_ruleset)
      memo[k] = json
      memo
    end
  end
end
