class ResourceRefinements

  URL_PARAMS = {:unit      => 'start_unit_id',
                :lesson    => 'lesson_id',
                :component => 'component_id'}
  MULTI_UNIT_RANK = 99999

  def initialize(finder, program, url_params = {})
    @program = program
    @finder = finder
    @url_params = url_params
    @units_options = {}
    @lessons_options = {}
    @components_options = {}
    @visible_units_ids = @program.visible_units_and_resource_units(url_params[:can_see_unreleased_units]).collect(&:id)
    populate_category_options
  end

  def refinement_categories
    categories = []
    categories << { 'units' => @program.unit_label }
    categories << { 'lessons' => @program.lesson_label } if @program.two_tier?
    categories << { 'components' => 'Component' }
    categories
  end

  def category_options(category_type)
   case category_type
    when "units" then units_category_options
    when "lessons" then @lessons_options
    when "components" then @components_options
   end
  end

  def refinements_description
    params = self.class.currently_applied_filters(@url_params)
    return 'Browse Resources' if params.empty?
    descriptions = []
    if params[:start_unit_id]
      if multi_unit_option_enabled?
        descriptions << @program.multi_unit_resource_label
      else
        unit_name = Unit.find_by_id( params[:start_unit_id] ).display_name
        if unit_name == "No Unit" || unit_name == "No Lesson"
          descriptions << "General Resources"
        else
          descriptions << unit_name
        end
      end
    end

    if params[:lesson_id]
      descriptions << Lesson.find_by_id( params[:lesson_id] ).display_name
    end

    if params[:component_id]
      descriptions << ResourceComponent.find_by_id( params[:component_id] ).name
    else
      descriptions << 'All Components'
    end

    descriptions.join(' | ')
  end

  def self.currently_applied_filters(url_params)
    valid_params = URL_PARAMS.invert
    current_params = {}
    url_params.each_pair{ |url_key, value| current_params[url_key.to_sym] = value if valid_params[url_key.to_s].present? }
    current_params
  end

  private

  def units_category_options
    @units_options.empty? ? { 0 => {:count => '', :display_name => 'not applicable', :show_link => false} } : @units_options
  end

  # TODO - refactor
  def url_params_for_category(category_symbol, value)
    params_array = []
    current_url_params(category_symbol).each_pair do |symbol_key, url_value|
      if url_value.is_a? Array
        url_value.each{ |inner_value| params_array << "#{URL_PARAMS[symbol_key]}[]=#{inner_value}" }
      else
        params_array << "#{URL_PARAMS[symbol_key]}=#{url_value}"
      end
    end
    if value.is_a? Array
      value.each{ |inner_value| params_array << "#{URL_PARAMS[category_symbol]}[]=#{inner_value}" }
    else
      params_array << "#{URL_PARAMS[category_symbol]}=#{value}"
    end
    params_array.join('&')
  end

  def populate_category_options
    process_parent_component_options
    process_unit_options
    if @program.two_tier?
      process_lesson_options
    end
  end

  def resource_unit_id(resource)
    if @url_params[:start_unit_id] && !multi_unit_option_enabled?
      return @url_params[:start_unit_id].to_i
    else
      return resource.start_unit_id
    end
  end

  def process_unit_options
    @finder.grouped_by_unit_type.each do |resource|
        # Process multi-lesson finder
        if resource.end_unit_id.present?
          setup_multi_unit_option
        else
          next unless @visible_units_ids.include?(resource.start_unit_id)
          key = resource.unit.rank
          @units_options[key] = {}
          @units_options[key][:count] = resource.resource_unit_count
          @units_options[key][:link_params] = "?#{url_params_for_category(:unit, resource_unit_id(resource))}"
          @units_options[key][:display_name] = resource.unit.display_name
          @units_options[key][:show_link] = (@url_params[:start_unit_id].to_s != resource_unit_id(resource).to_s)
        end
      end
  end

  def setup_multi_unit_option
    @units_options[MULTI_UNIT_RANK] ||= {}
    @units_options[MULTI_UNIT_RANK][:count] ||= 0
    @units_options[MULTI_UNIT_RANK][:count] += 1
    @units_options[MULTI_UNIT_RANK][:link_params] ||= "?#{url_params_for_category(:unit, @program.units_and_resource_units.collect(&:id))}"
    @units_options[MULTI_UNIT_RANK][:display_name] ||= @program.multi_unit_resource_label
    @units_options[MULTI_UNIT_RANK][:show_link] ||= !multi_unit_option_enabled?
  end

  def multi_unit_option_enabled?
    @url_params[:start_unit_id].is_a? Array
  end

  def current_url_params(remove_param)
    params = @url_params.dup
    params = params.reject{ |req_param, req_param_val |  !URL_PARAMS.values.include?(req_param.to_s)}
    params = params.reject{ |param, value| param.to_sym == URL_PARAMS[remove_param].to_sym }.symbolize_keys
    params.inject({}){|memo, (req_param, req_val)| memo[URL_PARAMS.key(req_param.to_s)] = req_val; memo }
  end

  def process_lesson_options
    @finder.grouped_by_lesson.each do |resource|
      key = resource.lesson_id
      @lessons_options[key] = {}
      @lessons_options[key][:count] = resource.resource_lesson_count
      @lessons_options[key][:link_params] = "?#{url_params_for_category(:lesson, key)}"
      @lessons_options[key][:display_name] = resource.lesson.name
      @lessons_options[key][:show_link] = (@url_params[:lesson_id] != resource.lesson_id)
    end
  end

  def process_parent_component_options
    @finder.grouped_by_component.each do |resource|
      key = resource.resource_component.name
      @components_options[key] = {}
      @components_options[key][:count] = resource.resource_component_count
      @components_options[key][:link_params] = "?#{url_params_for_category(:component, resource.resource_component_id)}"
      @components_options[key][:display_name] = key
      # Don't show a link to the component if it is currently selected
      @components_options[key][:show_link] = (@url_params[:component_id] != resource.resource_component_id)
    end
  end
end
