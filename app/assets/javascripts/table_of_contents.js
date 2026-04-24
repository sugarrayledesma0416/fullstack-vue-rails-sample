//=require content_library

var current_start_rank;
var min_rank;
var max_rank;

var VHL = VHL || {}

VHL.TableOfContents = (function() {
  function bindLessonSelectorChange() {
    /* When selecting a unit/lesson, send the browser
     * to location stored in the option's value attr.
     */
    $('.js-lesson-selector').change(function() {
      window.location.href = $(this).val();
    });
  }

  function displayAssignedActivitiesOnly() {
    return sessionStorage.getItem('show_assigned_activities') === 'assigned';
  }

  /**
   * @private
   * @return {boolean} whether my_drafts is selected (vs all_content or my_content)
   */
  function displayAllDrafts() {
    return sessionStorage.getItem('show_content') === 'my_drafts';
  }

  /**
   * @private
   * @return {boolean} whether all_content is selected (vs all_content or my_content)
   */
  function displayAllShared() {
    return sessionStorage.getItem('show_content') === 'all_content';
  }

  /**
   * @private
   * @return {boolean} whether my_content is selected (vs all_content or my_drafts)
   */
  function displayMyContentOnly() {
    return sessionStorage.getItem('show_content') === 'my_content';
  }

  /**
   * @private
   * shows all shared activities
   */
  function showAllContent() {
    $('.js-other-instructor-activity, .js-shared-activity').each(function() {
      const activityElm = $(this);

      if (displayAssignedActivitiesOnly()) {
        if (!activityElm.hasClass('js-non-assigned-activity')) {
          toggleVisibility(activityElm, false);
        }
      } else {
        toggleVisibility(activityElm, false);
      }
    });
  }

  /**
   * @private
   * shows all draft activities
   */
  function showMyDrafts() {
    $('.js-other-instructor-activity, .js-draft-activity').each(function() {
      const activityElm = $(this);

      if (displayAssignedActivitiesOnly()) {
        if (!activityElm.hasClass('js-non-assigned-activity')) {
          toggleVisibility(activityElm, false);
        }
      } else {
        toggleVisibility(activityElm, false);
      }
    });
  }

  /**
   * @private
   * shows no content message when there is no content to
   * show in the instructor-created activities table
   */
  function toggleNoContentMessage() {
    if (
      $('.js-no-component-content-message')
      .closest('table').find('tr:visible')
      .not(".js-no-component-content-message")
      .length === 1
    ) {
      $('.js-no-component-content-message').removeClass('u-hidden');
    } else {
      $('.js-no-component-content-message').addClass('u-hidden');
    }
  }

  /**
   * @private
   * hides all draft activities
   */
  function hideAllDrafts() {
    $('.js-draft-activity').each(function() {
      toggleVisibility($(this), true);
    });
  }

  /**
   * @private
   * hides all shared activities
   */
  function hideAllShared() {
    $('.js-shared-activity').each(function() {
      toggleVisibility($(this), true);
    });
  }

  /**
   * @private
   * hides other instructor activities
   */
  function hideOtherInstructorsActivities() {
    $('.js-other-instructor-activity').each(function() {
      toggleVisibility($(this), true);
    });
  }

/**
   * @private
   * toggles the visibility of all_content, my_content or my_drafts based
   * on the selector value.
   * when all_content is selected it shows all activities except the ones marked
   * as draft (js-draft-activity).
   * When my_content is selected it shows all activities that are not marked
   * as other instructor(js-other-instructor-activity).
   * When my_drafts is selected it shows only activities marked as draft, whether
   * they are marked as other instructor activity or not
   */
function toggleInstructorCreatedActivityVisibility() {
  const filterSelected = sessionStorage.getItem('show_content');
  const showMyContent = displayMyContentOnly();

  switch (filterSelected) {
    case 'my_drafts':
      showMyDrafts();
      hideAllShared();
      hideOtherInstructorsActivities();
      break;
    case 'all_content':
      showAllContent();
      showMyDrafts();
      break;
    case 'my_content':
      showAllContent();
      showMyDrafts();
      hideOtherInstructorsActivities();
      break;
    default:
      break;
  }

  $('.js-toc-creator').each(function()  {
    toggleVisibility($(this), showMyContent);
  });

  toggleNoContentMessage();
}

  /**
   * toggleUnassignedContentVisibility() sets visibility of all
   * unassigned activities based on the visibility selector value.
   *
   * TODO: "true" is used to hide, and "false" is used to show --
   *       should make this less confusing!
   */
  function toggleUnassignedContentVisibility() {
    const displayAssigned = displayAssignedActivitiesOnly();
    $('.js-non-assigned-activity').each(function()  {
      const activityElm = $(this);
      if (displayMyContentOnly()){
        if (!activityElm.hasClass('js-other-instructor-activity')) {
          toggleVisibility(activityElm, displayAssigned);
        }
      } else if (displayAllShared()) {
        if (!activityElm.hasClass('js-draft-activity')) {
          toggleVisibility(activityElm, displayAssigned);
        }
      } else if (displayAllDrafts()) {
        if (!activityElm.hasClass('js-shared-activity')) {
          toggleVisibility(activityElm, displayAssigned);
        }
      } else {
        toggleVisibility(activityElm, displayAssigned);
      }
    });
    $('.js-no-component-assignments-message').each(function()  {
      const activityElm = $(this);
      toggleVisibility(activityElm, !displayAssigned);

      //Adding / Removing table summary for nothing assigned table.
      const $noAssignmentTableSummary = displayAssigned ? 'Nothing Assigned' : '';
      activityElm.closest('table').attr('summary', $noAssignmentTableSummary);
    });
    const $lastVisibileRowCell = $('.js-table--activities').find('.js-row--activities:visible:last').children();
    $('.js-last-visible-row').removeClass('c-last-visible-row  js-last-visible-row');
    $lastVisibileRowCell.addClass('c-last-visible-row  js-last-visible-row');
    toggleNoContentMessage();
  }

  /**
   * toggleVisibility(item, visible)
   * - Sets u-hidden class to item given the visible value
   * @item {Element} DOM element
   * @visible {Boolean}
   */

  function toggleVisibility(item, visible) {
    item.toggleClass('u-hidden', visible);
  }

  /*
   * initializeVisibilitySelector() sets the default value for the
   * visibility selector based on user type if selector is present
   * (user is enrolled in a course).
   */
  function initializeVisibilitySelector() {
    var selector = $('.js-visibility-selector');
    let contentSelector = $('.js-content-selector');
    var userType = $(selector).data('user-class');
    var sessionValue = sessionStorage.getItem('show_assigned_activities');
    let sessionContentValue = sessionStorage.getItem('show_content');
    var selectorValue;
    let contentValue;

    if (userType !== undefined) {
      if (sessionValue !== null) {
        selectorValue = sessionValue;
      } else {
        selectorValue = (userType === 'Student' ? 'assigned' : 'all');
      }
      if (sessionContentValue === null) {
        contentValue = 'all_content';
        sessionStorage.setItem('show_content', contentValue);
      } else {
        contentValue = sessionContentValue;
      }
      sessionStorage.setItem('show_assigned_activities', selectorValue);
      // new value is applied to the correct option of visibility selector
      selector.val(selectorValue);
      // new value is applied to the correct option of content selector
      contentSelector.val(contentValue);
      toggleUnassignedContentVisibility();
      toggleInstructorCreatedActivityVisibility();
    }
  }
 /**
   * bindMyContentOnly() sets an event listener for the
   * instructor created activities my-content/all-content selector.
   * When selector is set to 'My Content', hides all content not created
   * by the current user
   */
    function bindMyContentOnlyChange() {
      $('.js-content-selector').change(function () {
        const contentToShow = $(this).val();
        sessionStorage.setItem('show_content', contentToShow);
        toggleInstructorCreatedActivityVisibility();
      });
    }

  /*
   * bindVisibilitySelectorChange() sets an event listener
   * for the activity visibility selector.
   * When selector is set to 'Assigned', hides all non-assigned activities.
   */
  function bindVisibilitySelectorChange() {
    $('.js-visibility-selector').change(function () {
      sessionStorage.setItem('show_assigned_activities', $(this).val());
      toggleUnassignedContentVisibility();
    });
  }

  function bindMobileNavToggle() {
    const $disclosure = $('.js-toc-nav-disclosure');
    const $closeBtn = $('.js-toc-nav-close');
    const $clickables = $disclosure.add($closeBtn);
    const $target = $('#' + $disclosure.data('target'));
    // Click either the disclosure or the close button:
    $clickables.on('click', () => {
      const state = $disclosure.hasClass('is-expanded');
      $disclosure
      .toggleClass('is-expanded', !state)
      .attr('aria-expanded', !state);
      $target.toggleClass('is-expanded-target', !state);
    });
  }

  function init() {
    $('a.set_date_link').click(function(event) {
      event.preventDefault();
      VHL.ContentLibrary.assignment_wizard(this);
    });

    initialize_disabled_assignment_link();
    initializeVisibilitySelector();
    toggle_activity_details_on_hover();
    toggle_linked_activity_on_hover();
    show_or_hide_strands();
    super_site_only_dialog();
    student_no_access_hover();
    VHL.Common.gear_click_event();
    bindLessonSelectorChange();
    bindVisibilitySelectorChange();
    bindMyContentOnlyChange();
    bindMobileNavToggle();
    VHL.Checkboxes.makeAccessible();
  }

  function toggle_linked_activity_on_hover() {

    function _makeHoverVisible() {
      $(this).siblings('.remove').removeClass('hidden_helper');
    }

    function _makeHoverHidden() {
      $(this).siblings('.remove').addClass('hidden_helper');
    }

    var config = {
      over: _makeHoverVisible,
      timeout: 250,
      out: _makeHoverHidden
    };

    $('.linked-to-a-course').hoverIntent(config);
  }

  function initialize_disabled_assignment_link() {
    $('.set_date_link').disable_link_toggle({
      meth: 'disable',
      disable: 'You must first select an activity.'
    });
  }



  function show_or_hide_strands() {
    var topics_list = $('.topics');
    var show_strands = topics_list.attr('data-show-strands');
    if (show_strands === 'no') {
      $('ul.topics').hide();
    }
  }

  function student_no_access_hover() {
    let no_access_hover = $('.js-unassignable_activity_msg_student');
    if (no_access_hover.length) {
      $('.unassignable_activity').hover((evt) => {
        $(evt.currentTarget).find('.js-toc-col-activity').append(no_access_hover);
        no_access_hover.toggleClass('hidden_helper', false);
      },
      () => {
        no_access_hover.toggleClass('hidden_helper', true);
      });
    }
  }

  function super_site_only_dialog() {
    $('.ssplus_only_message').click(function() {
      $('#ssplus_dialog').dialog();
      return false;
    });
  }

  function toggle_activity_details_on_hover() {
    /*this needs refactor for efficiency. -Andrea*/
    function _toggle_checkbox(element, check_all) {
      element.toggleClass('show_check', check_all);
      $thisRow = element.parents('tr').toggleClass('highlight_bg', check_all);
      $thisRow = element.parents('li').toggleClass('highlight_bg', check_all);
    }

    function _update_links(klass_tag) {
      if ($(klass_tag).hasClass('show_check')) {
          $('.set_date_link').disable_link_toggle({
            meth: 'enable'
          });
          VHL.Checkboxes._set_ids();
      } else {
          $('.set_date_link').disable_link_toggle({
            meth: 'disable',
            disable: 'You must first select an activity.'
          });
      }
    }

    function _makeHoverVisible() {
      $(this).find('.results_table_hover').removeClass('hidden_helper');
    }

    function _makeHoverHidden() {
     $(this).find('.results_table_hover').addClass('hidden_helper');
    }

    var config = {
      over: _makeHoverVisible,
      timeout: 250,
      out: _makeHoverHidden
    };

    $('tr.assign_hover').hoverIntent(config);
  }

  return {
    init: init
  };

}());
