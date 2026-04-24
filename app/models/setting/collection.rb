
class Setting::Collection
  def initialize(user)
    @user = user
  end

  # Retrieves a user's setting.
  # e.g. current_user.setting(Setting::Gradebook::CategoryView)
  # See app/model/setting.rb for allowed names.
  def get(name)
    name = name.to_s
    setting = settings_hash[name]
    value = nil
    if setting
      value = setting.value
    else
      value = Setting.default(name)
    end
    value
  end

  # Sets a setting.
  # e.g. current_user.set(Setting::Gradebook::CategoryView, :units)
  # See app/model/setting.rb for allowed names and values.
  def set(name, value)
    if name.is_a? Symbol
      definition = Setting::Definition.from_symbol(name)
      name = definition if definition
    end
    if name.respond_to?(:sanitize_value)
      value = name.sanitize_value(value)
    end
    name = name.to_s
    setting = settings_hash[name]

    if setting
      setting.value = value
      setting.save!
    else
      setting = Setting.create!(:user_id => @user.id, :name => name, :value => value)
      settings_hash[name] = setting
    end
    setting
  end

  private

  def settings_hash
    @settings_hash ||= Hash[*(@user.settings.map {|setting| [setting.name, setting]}).flatten]
  end
end
