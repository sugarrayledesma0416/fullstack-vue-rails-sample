Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'lesson_xml' => 'LessonXML',
    'lesson_xml_parser' => 'LessonXMLParser',
    'jwt_payload' => 'JWTPayload',
    'vhl_monitor' => 'VHLMonitor',
    # Gradebook engine
    'gradebook_api' => 'GradebookAPI',
    'sql_fragments' => 'SQLFragments',
    'ai' => 'AI'
  )
  autoloader.ignore(Rails.root.join('app', 'lib', 'patches'))
end
