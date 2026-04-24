# encoding: utf-8

feature 'Reference activity with glosses', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, :vista_online_learning => true) }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:activity) { create_reference_activity_with_glosses(program) }

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    visit section_activity_path(0, activity)
  end

  scenario 'as a user I can see glosses in a reference activity', js: true do

    within("[data-gloss]", text: 'proteger') do
      expect(page).to have_selector('span', text: 'protect')
    end
    within("[data-gloss]", text: 'bahía') do
      expect(page).to have_selector('span', text: 'bay')
    end
    within("[data-gloss]", text: 'siglo') do
      expect(page).to have_selector('span', text: 'century')
    end
    within("[data-gloss]", text: 'nació') do
      expect(page).to have_selector('span', text: 'was born')
    end
    within("[data-gloss]", text: 'estrellas') do
      expect(page).to have_selector('span', text: 'stars')
    end
    within("[data-gloss]", text: 'mundo') do
      expect(page).to have_selector('span', text: 'world')
    end
    within("[data-gloss]", text: 'científicos') do
      expect(page).to have_selector('span', text: 'scientists')
    end
    within("[data-gloss]", text: 'Tierra') do
      expect(page).to have_selector('span', text: 'earth')
    end
    within("[data-gloss]", text: 'Luna') do
      expect(page).to have_selector('span', text: 'moon')
    end
    within("[data-gloss]", text: 'pasó a ser') do
      expect(page).to have_selector('span', text: 'became')
    end
    within("[data-gloss]", text: 'después de') do
      expect(page).to have_selector('span', text: 'after')
    end
    within("[data-gloss]", text: 'guerra') do
      expect(page).to have_selector('span', text: 'war')
    end
    within("[data-gloss]", text: 'se hizo') do
      expect(page).to have_selector('span', text: 'became')
    end
    within("[data-gloss]", text: 'ciudadanos') do
      expect(page).to have_selector('span', text: 'citizens')
    end
    within("[data-gloss]", text: 'desde') do
      expect(page).to have_selector('span', text: 'since')
    end
    within("[data-gloss]", text: 'pagan impuestos') do
      expect(page).to have_selector('span', text: 'pay taxes')
    end
    within("[data-gloss]", text: 'volverse') do
      expect(page).to have_selector('span', text: 'to become')
    end

    within("[data-gloss]", text: 'son') do
      expect(page).to have_selector('span', text: 'Cuban musical genre')
    end
    expect(page).to have_selector('.gloss-hover', text: 'Cuban musical genre', count: 1)

    within("[data-gloss]", text: 'emisiones') do
      expect(page).to have_selector('span', text: 'alien signals')
    end
    expect(page).to have_selector('.gloss-hover', text: 'alien signals', count: 1)
  end

end
