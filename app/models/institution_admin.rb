class InstitutionAdmin < Instructor
  has_many :created_courses, class_name: 'Course',
                             foreign_key: 'creator_guid',
                             primary_key: 'guid'

  has_many :admin_schools,
           -> { distinct },
           source: :school,
           through: :school_program_admin_users

  def admin_for_school?(school)
    admin_schools.include?(school)
  end

  def admin_school_programs(school)
    Program.joins(:school_program_admin_users)
           .where(school_program_admin_users: { school_id: school.id,
                                                user_id: id })
           .order('programs.title ASC')
  end

  def admin_district_programs(district)
    district.schools.flat_map do |school|
        admin_school_programs(school).to_a
    end.uniq
  end

  def access_to_admin_school_and_program?(school, program)
    admin_school_programs(school).map(&:id).include? (program.id)
  end
end
