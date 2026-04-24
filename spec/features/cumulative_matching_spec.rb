feature 'Cumulative Matching', test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program, :vista_online_learning => true) }
  let(:course) { create(:course, :owner => instructor, :program => program) }
  let(:section) { create(:section, :course => course, :instructor => instructor) }
  let(:activity) { create_cumulative_matching_activity(program) }
  let(:media_item_stub) { build_stubbed(:media_item) }

  before do
    allow(MediaItem).to receive(:find).and_return(media_item_stub)
    allow(media_item_stub).to receive(:public_filename).and_return('/correct.mp3')
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
    visit section_activity_path(0, activity)
  end

  scenario 'I can see drop targets and label tiles with their positions set', :js => true do
    # var stage is defined in the script, but we could easily just define a stage attribute on the canvas element, find that element id, and
    # access stage that way

    # this is one example of one of the things we can do once we have the stage.  We can descend into the elements on the stage, find
    # them by index or by name, and inspect their contents, their x and y position, whether they are contained within or overlap other
    # elements, etc.

    # Can't ask for a specific position in the spectation because these are being set randomly
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('drop_target_137024').x))).to be > 0
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('drop_target_137024').y))).to be > 0
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('label_tile_137024').x))).to be > 0
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('label_tile_137024').y))).to be > 0
  end

  scenario 'I can click a drop target and the matching label tile and have them marked as correct and disabled', :js => true do
    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('drop_target_137024').dispatchEvent('click')))

    # clicked element should be highlighted
    should_be('highlighted', 'drop_target_137024')
    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('label_tile_137024').dispatchEvent('click')))

    # matching elements are marked as completed and unhighlighted
    should_be('completed', 'label_tile_137024')
    should_not_be('highlighted', 'drop_target_137024')
    should_not_be('highlighted', 'label_tile_137024')

    # additional click events should not make the elements higlighted
    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('drop_target_137024').dispatchEvent('click')))
    should_not_be('highlighted', 'drop_target_137024')

    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('label_tile_137024').dispatchEvent('click')))
    should_not_be('highlighted', 'label_tile_137024')
  end

  scenario 'I can click a drop target and not matching label tile and have them unhighlighted and still available for selection', :js => true do
    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('drop_target_137024').dispatchEvent('click')))

    # clicked wrong label tile, drop target should stay highlighted and label tile should be unhighlighted
    page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('label_tile_137025').dispatchEvent('click')))
    should_be('highlighted', 'drop_target_137024')
    should_not_be('highlighted', 'label_tile_137025')
    should_not_be('completed', 'drop_target_137024')
    should_not_be('completed', 'label_tile_137025')
  end


  scenario 'I see the a tag with a congratulations message', :js => true do
    pending "Fix this test"
    expect(page).to have_selector('[data-content-type="decision_options"]', :text => 'Congratulations on completing the activity. You can try it again with another set of words. Try it again')
    expect(page).to have_selector('[data-content-type="retry"]', :text => 'Try it again')
  end

  def should_be(status, element)
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('#{element}').#{status}))).to be_truthy
  end

  def should_not_be(status, element)
    expect(page.evaluate_script(%(VHL.CumulativeMatching.stage.getChildByName('#{element}').#{status}))).to be_falsey
  end

end
