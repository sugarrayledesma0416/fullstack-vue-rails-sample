feature 'Program to program mapping', js: true, chrome: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers

  scenario 'Program to program mapping' do
    step 'I log in as a tech producer'
    step 'Visit the programs configuration page'
    step 'Click on the Update M3 configuration link'

    purpose 'I can view a program to program mapping form' do
      step 'Select a source program'
      step 'I see lessons and strands for the source program'
      step 'I see input fields for the destination strands'
    end

    purpose 'I can automatically map the programs' do
      step 'Click on the "map to destination" button'
      step 'I can see destination strands corresponding to each source strand'
      step 'I can see a message for a strand that was not mapped automatically'
      step 'I can edit a single destination strand'
    end

    purpose 'I can create a program to program mapping' do
      step 'Choose a lesson/strand option for the destination'
      step 'Click on the "submit" button'
    end
  end
end
