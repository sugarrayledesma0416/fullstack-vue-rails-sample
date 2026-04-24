namespace :institution_admin do
  namespace :enterprise_2_0 do
    desc 'Migrate course templates to new format'
    task :migrate_templates => :environment do
      moved_sections = {}
      Course.unscoped.where('start_date > ?', Date.new(2024, 12, 31)).where(is_template: true).each do |course|

        # course templates only have section templates
        Dangerfield::Gatekeeper.instance.disabled = false
        course.sections.each do |section_template|
          ActiveRecord::Base.transaction do
            sections = Section.where(source_template_id: section_template.id)
            new_course = course.dup
            # generate new guid
            new_course.guid = SecureRandom.uuid
            new_course.name = "#{section_template.name} - #{course.name}"
            new_course.is_enterprise = true
            new_course.is_template = false
            new_course.save!

            section_template.class_days = class_days(section_template)
            section_template.course_id = new_course.id
            section_template.is_enterprise = true
            section_template.save

            moved_section_ids = []
            sections.each do |section|
              section.update!(course_id: new_course.id)
              moved_section_ids << section.id
            end

            moved_sections[new_course.id] = {
              section_ids: sections.pluck(:id),
              old_course_id: course.id,
              enterprise_section_id: section_template.id
            }
          rescue StandardError => e
            puts "Error migrating course template #{course.id} and section template #{section_template.id}:\n #{e.message}"
            next
          end

        end
        Dangerfield::Gatekeeper.instance.disabled = true
      end
      p "Summary of Coures Migrated"
      moved_sections.each do |new_course_id, hash|
        p "Created new enterprise course #{ new_course_id } and enterprise section #{hash[:enterprise_section_id]}"
        p "from course template #{ hash[:old_course_id] }"
        p "    Sections: #{ hash[:section_ids].join(',') }"
        p "----------------------------------------"
      end
    end
  end
end

def class_days(section)
  return section.class_days if section.class_days.present?

  if section.name.include?('MW ')
    '1,3'
  elsif section.name.include?('MWF ')
    '1,3,5'
  elsif section.name.include?('TR ')
    '2,4'
  elsif section.name.include?('TTH ')
    '2,4'
  else
    '1,2,3,4,5'
  end
end