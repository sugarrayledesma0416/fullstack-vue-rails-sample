
module DemoData

  DEFAULT_MASTER_RECIPE = 'current_master_recipe.rb'
  @fixtures = Array.new
  @recipes  = Array.new

  def self.callable?
    true
  end

  def self.load(master_recipe = DEFAULT_MASTER_RECIPE)

    master_recipe_file = File.join(recipes_dir, master_recipe)
    return unless File.exist?(master_recipe_file)

    load_all_recipes

  end

  def recipe_for(recipe_name)

  end

  private

  def self.recipes_dir
    Rails.root.join('demo_data', 'recipes')
  end

  def self.load_all_recipes
    Dir[File.join(recipes_dir,'*_recipe.rb')].each {|recipe_file| require recipe_file}
  end

end
