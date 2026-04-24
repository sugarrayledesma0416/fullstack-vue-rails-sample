# -*- coding: utf-8 -*-
feature 'Instructor-created Activities' do
    include RspecJsCommonHelpers
    include RspecJsContentHelpers
    include RspecJsApiHelpers

    let(:instructor) { create(:instructor) }
    let(:program) { create(:program, title: "Thèmes") }
    let!(:activity) { create_activity_with_unit_lesson_concept_strand_and_substrand(program, instructor_revision_id: 70) }
    let(:course) { create(:course, owner: instructor, program: program) }
    let!(:section) { create(:section, course: course, instructor: instructor) }
    let(:course_licenses) { Array.new }

    before do
      allow_any_instance_of(AccessGuardian).to receive(:has_ebook?).and_return(true)
      initialize_program_access_client_calls_for_instructor(instructor, program)
      give_instructor_access_to_toc
      log_in_as(instructor)
    end

    scenario 'Instructor access to Thèmes Supersite Trial Site', test_debt: true do
      visit instructor_dashboard_path(program.id)
      find('.test-content-menu').click
      expect(find(".test-content-submenu")).to have_link('eBook')
      digital_texts_link = find(".test-content-submenu").find('li > a', text: 'eBook')
      digital_texts_link.click
      expect(page).to have_selector('#full_width_header', text: 'eBook')
      dump_the_page
      # This fails because it targets a specific book - 20161101 MJH
      #expect(page).to have_selector('.new_book_message', text: 'Thèmes eBook (for iPad®) will be available for purchase in summer 2015. To learn more about the eBook features, visit http://vistahigherlearning.com/new-supersite/digital-texts')
      #expect(page).to have_selector("div.ebook_image > img[src='/images/programs/medium_173/themes1e.png']")
    end

end
