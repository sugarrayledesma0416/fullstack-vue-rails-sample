describe SectionOptionsSerializer do
  let(:section){build_stubbed(:section_with_course)}
  let(:user) { build_stubbed(:user) }

  it 'renders the correct json' do
    section_options = SectionOptions.new(user, section)
    expected = {
      additional_info: section_options.additional_info,
      allow_enrollment_lock: true,
      autorostering_linked: false,
      assignments_present: false,
      class_days: section_options.class_days,
      course: section_options.course,
      days_to_show_assignment_due_date: section.days_to_show_assignment_due_date,
      due_time_ampm: section_options.due_time_ampm,
      due_time_hour: section_options.due_time_hour,
      due_time_min: section_options.due_time_min,
      hide_owner_name: section.hide_owner_name,
      id: section_options.id,
      instructor: section_options.instructor,
      instructor_creator_roles: section_options.instructor_creator_roles,
      instructor_roles: section_options.instructor_roles,
      latest_section_id: section_options.latest_section_id,
      lti_roster_linked: false,
      name: section_options.name,
      one_roster_linked: false,
      open_to_students: true,
      previous_sections: section_options.previous_sections_info,
      section_instructors: section_options.section_instructors,
      time_zone: section_options.time_zone
    }
    expect(SectionOptionsSerializer.new(section_options).as_json).to eq expected
  end
end
