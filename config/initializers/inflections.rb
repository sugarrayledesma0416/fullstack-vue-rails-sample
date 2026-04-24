# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'has', 'have'
  inflect.irregular 'is', 'were'
  inflect.irregular 'was', 'were'
  inflect.irregular 'are', 'were'
  inflect.irregular 'Lección', 'Lecciones'
  inflect.irregular 'Unidad', 'Unidades'
  inflect.irregular 'Lektion', 'Lektionen'
  inflect.irregular 'Lezione', 'Lezioni'
  inflect.uncountable %w[Kapitel Unità]
  inflect.acronym 'AI'
end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
