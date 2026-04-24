$(document).ready(function() {
  VHL.Dashboard.init();
});

$(document).on('keydown', '.js-main-course-section', function(e) {
  if (e.keyCode === 13 || e.keyCode === 32) {
    if ($(e.target).is('.js-main-course-section')) {
      e.preventDefault();
      e.stopPropagation();
      $(this).find('.js-section-name').trigger('click');
      return false;
    }
  }
});

VHL = VHL || {};

VHL.Dashboard = (function() {

  var dashboardFocus = {};
  var sectionAverages = {
    overall: {},
    section_and_categories: {}
  };
  let draggableElements = [];

  function init() {
    bindGearMenuLinks();
    bindGearMenus();
    bindCourseNavigationMobile();
    bindWidgetLinks();
    bindCourseSectionLinks();
    filterVisibleSections();
    dashboardFocus = $('#focus_indicator').data('jsFocus') || { course: null, section: null };
    getAveragesForFocusedCourseOrSection();
    _showAssistiveMessage(document.querySelector(`.js-course-navigation-wrapper[data-course-id='${dashboardFocus.course}']`));

    // Check viewport width to configure drag and drop for course list.
    if (window.innerWidth >= 900) {
      draggableElements = createDragAndDropCourses();
    } else if(draggableElements.length > 0) {
      draggableElements.forEach(function(draggableElement) {
        draggableElement.cleanup();
      });
    }
  }

  /**
   * Set course focus with the new order
   * @param {Array} courseOrder 
   */
  function sortFocus(courseOrder) {
    $('#focus_list').append($('#focus_list > dl').detach().sort(function(a, b) {
      const id1 = $(a).data('focus-course-id');
      const id2 = $(b).data('focus-course-id');
      return _.indexOf(courseOrder, id1) - _.indexOf(courseOrder, id2);
    }));
  }
  
  /**
   * Bind gear menus click events.
   */
  function bindGearMenus() {
    $('body').not($(".js-gear-wrapper")).on('click', function () {
      closeAllGearMenus();
    });

    $('.js-gear-wrapper').on('click touchend', function (event) {
      event.stopPropagation();
      closeAllGearMenus($(this));
      showGearMenu($(this));
    });
  }

  /**
   * Bind touchend event to the gear menu links.
   *
   * NOTE: For iPad devices, the touchend event propagation was not stopped, resulting
	 * in the execution of the gear icon's parent events. As a result, the links inside
   * the gear icon menu were unresponsive.
   * This was fully tested on an iPad device so it could work on other mobile devices
   * but is not tested.
   */
  function bindGearMenuLinks() {
    /*
     * The the gear menu in the course side has an special case. A parent element
     * creates a Drag and Drop object that implements its own touch events so we need
     * to stop the propagation of those events too. For this we use the cleanup()
     * method.
     */
    $('.js-gear-menu-link', '.js-course-navigation-wrapper').on('touchend', function(event){
      event.stopPropagation();
      draggableElements.forEach(function(draggableElement) {
        draggableElement.cleanup();
      });
    });

    $('.js-gear-menu-link', '.js-section-wrapper').on('touchend', function(event){
      event.stopPropagation();
    });
  }

  /**
   * Show/Hide gear menus for courses and sections.
   * @param {HTMLElement} gearMenu - Gear menu html element.
   * @param {Boolean} isOpen - Flag to indicate whether open/close gear menu. 
   */
  function showGearMenu(gearMenu, isOpen = false) {
    const label = gearMenu.find(".js-gear");
    const subMenu = gearMenu.children(".js-gear-menu");
    const showMenu = isOpen ? !isOpen : label.attr('aria-expanded') == 'false';
    if (showMenu) {
      label.attr('aria-expanded', 'true');
      subMenu.attr('data-visually-hidden', 'false');
    }
    else {
      label.attr('aria-expanded', 'false');
      subMenu.attr('data-visually-hidden', 'true');
    }
  }

  /**
   * Create drag & drop instances for each courses list by school.
   */
  function createDragAndDropCourses() {
    let coursesBySchool = $('.js-courses-by-school');
    let draggableElements = [];
    if (coursesBySchool.length > 0) {
      draggableElements = [...coursesBySchool].map((courseList) => {
        return new VHL.Music.V1.DragAndDrop(
          $(courseList).find('.js-course-navigation-wrapper'),
          $(courseList).find('.js-courses-by-school-target'),
          function () { },
          $(courseList),
          function ($draggable, $target) {
            sortCourses($draggable, $target);
          }
        );
      });
    }

    return draggableElements;
  }

  /**
   * Callback to update user setting with course order
   * when the instructor moves something
   * @param {HTMLElement} $draggable - Selected/moved course items.
   * @param {HTMLElement} $target - Container of $draggable 
   */
  function sortCourses($draggable, $target) {
    const course_order = $.map($('.js-course-navigation-wrapper'), function (elm) {
      return $(elm).data('course-id');
    });

    $.ajax({
      url: '/setting/sort_courses.json',
      type: 'POST',
      data: {
        "course_order": course_order.join(","),
        "program_id": VHL.Common.program_id()
      }
    });
    sortFocus(course_order);
  }

  /**
   * Close all gear menus for sections and courses
   * @param {HTMLElement} gearMenu - gear menu html element.
   */
  function closeAllGearMenus(gearMenu = null ) {
    $('.js-gear-wrapper').not(gearMenu).each(function () {
      showGearMenu($(this), true);
    });
  }

  /**
   * Bind event to extra button for mobile navigation.
   */
  function bindCourseNavigationMobile() {
    $('.js-courses-navigation-mobile').on('click touchend', function (event) {
      event.preventDefault();
      let courseSectionWrappers = $('.js-wrapper-mobile');
      [...courseSectionWrappers].forEach((wrapper) => {
        if ($(wrapper).hasClass('is-hidden')) {
          $(wrapper).addClass('is-visible');
          $(wrapper).removeClass('is-hidden');
        } else {
          $(wrapper).removeClass('is-visible');
          $(wrapper).addClass('is-hidden');
        }
      });
    })
  }

  /**
   * Bind click events for section widgets.
   */
  function bindWidgetLinks() {
    // Set the Widget Link based on whether it is open or closed.
    $('.js-widget').click(function(e) {

      $(this).find('a').each(function () {
        let sectionId = $(this).parents('.js-section-wrapper').attr('data-section-id');
        VHL.focus.update_focus_via_ajax($('.js-section-name-' + sectionId), true);
        location.href = $(this).attr('href');
      });
      e.preventDefault();
    });

    $('.js-block-enrollment-section-link').click(function() {
      blockStudentEnrollment($(this));
    });
  }

  /**
   * Bind events for student enrollment modal buttons & make ajax call to toggle 
   * between block/unblock student enrollemnt
   * @param {HTMLElement} enrollmentToggle - HTML element for toggle student enrollment.
   */
  function blockStudentEnrollment(enrollmentToggle) {
    const sectionOpen = enrollmentToggle.data('open-to-students');
    const sectionId = enrollmentToggle.data('section-id');
    const courseId = enrollmentToggle.data('course-id');
    const programId = enrollmentToggle.data('program-id');
    const dialogContainer = $('.js-block-enrollment-section-' + sectionId + '-modal');
    const acceptButton = dialogContainer.find('.js-accept-button');
    const cancelButton = dialogContainer.find('.js-cancel-button');

    acceptButton.off('click');
    cancelButton.off('click');

    acceptButton.click(function () {
      dialogContainer.vhlModal('close');
      $.ajax({ 
        type: 'PUT',
        url: '/instructor/' + programId + '/courses/' + courseId + '/sections/' + sectionId + '.json',
        data: { section: { id: sectionId, open_to_students: !sectionOpen } },
        dataType: 'json',
        success: function (response) {
          enrollmentToggle.data('open-to-students', response.open_to_students)
          updateConfirmModal(response);
        }
      });
    });

    cancelButton.click(function () {
      dialogContainer.addClass('u-hidden');
      enrollmentToggle.prop('checked', sectionOpen ? true : '');
    });
    dialogContainer.vhlModal('open');
  }

  /**
   * Update modal enrollment according new blocked/unblocked state.
   * @param {JSON} section - Data section when student enrollment is updated. 
   */
  function updateConfirmModal(section) {
    const enrollmentStatus = section.open_to_students ? 'open' : 'closed';
    let enrollmentQuestion = 'allow students to enroll?';
    const dialogContainer = $('.js-block-enrollment-section-' + section.id + '-modal');
    if (enrollmentStatus === 'open') {
      enrollmentQuestion = 'prevent further student enrollment?'
    }
    dialogContainer.find('.js-modal-title-status').html(capitalize(enrollmentStatus));
    dialogContainer.find('.js-modal-message-status').html(enrollmentStatus);
    dialogContainer.find('.js-modal-message-question').html(enrollmentQuestion);
  }

  /**
   * Show assistive message for screenreader when course changes.
   */
  function _showAssistiveMessage(courseContainer) {
    if(courseContainer){
      const assistiveContainer = document.querySelector('.js-assistive-course-msg');

      if(courseContainer.querySelector('.js-course-name')){
        const courseName = courseContainer.querySelector('.js-course-name').dataset.courseName;
        assistiveContainer.textContent = `Course selected: ${courseName}`;
      }
    }
  }

  /**
   * Bind event to show courses & sections.
   */
  function bindCourseSectionLinks() {
    // Toggle Courses
    $('.js-courses-by-school .js-course-navigation-wrapper').on('click touchend', function(e) {
      $('.js-dashboard-accordion').hide();
      toggleCourse(this);
      _showAssistiveMessage(this);
      e.preventDefault();
    });

    // Toggle Sections from Right Navigation
    $('.js-main-course-section .js-section-name').click(function(e) {
      e.preventDefault();
      dashboardFocus.section = $(this).data('sectionId');
      toggleSection(this, true);
    });

    // Delete courses or section from gear menu
    $('.js-delete-link').on('click', function() {
      const itemType = $(this).data('link-type');
      const itemId = $(this).data('item-id');
      const dialogContainer = $('.js-' + itemType + '-' + itemId + '-modal');
      const deleteForm = $('.js-delete-' + itemType + '-' + itemId);
      const acceptButton = dialogContainer.find('.js-accept-button');
      const cancelButton = dialogContainer.find('.js-cancel-button');

      acceptButton.off('click');
      cancelButton.off('click');

      acceptButton.on('click touchend', function(event) {
        event.stopPropagation();
        dialogContainer.vhlModal('close');
        deleteForm.submit();
      });

      cancelButton.on('click touchend', function() {
        dialogContainer.vhlModal('close');
        return false;
      });

      dialogContainer.vhlModal('open');
      return false;
    });
  }

  /**
   * Capitalize a text
   * @param {String} string - Text to capitalize
   * @returns {String} Capitalized text.
   */
  function capitalize(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
  }

  /**
   * Filter & toggle section to show current section. 
   */
  function filterVisibleSections() {
    // These hide the other sections so that only the currently focused one is visible.
    $('.js-dashboard-accordion .js-course-content').hide().filter('.expanded').show();
    $('.js-dashboard-accordion .js-section-name').filter('.expanded').each(function() {
      toggleSection(this, false);
    });

    $('#closed_courses .js-course-content').hide().filter('.expanded').show();
    $('#closed_courses .js-section-name').filter('.expanded').each(function() {
      toggleSection(this, false);
    });
  }

  /**
   * Set view & update course focus.
   * @param {HTMLElement} sectionClicked - Section selected
   * @param {Boolean} updateFocusFlag - Flag indicating whether to update course focus
   * @param {Boolean} refresh - Flag indicating the type of course focus
   */
  function toggleSection(sectionClicked, updateFocusFlag, refresh) {
    closeAllGearMenus();

    // Hide the scheduled release text from the partial when viewing by section
    $('.js-due-date-scheduled').hide();
    const sectionId = 'section_' + $(sectionClicked).attr('data-section-id');

    if ($('.js-widget-container-' + sectionId + '-detail').attr('aria-expanded') == 'true') {
      hideSections();
      VHL.focus.update_focus_via_ajax($(sectionClicked).parents('.js-course-info').find('.js-course-id'));
    } else {
      hideSections();
      showSection(sectionClicked);

      // Hides Dashboard Accordion on Proper Reload, Forces Proper Reload
      if (updateFocusFlag) {
        if (refresh) {
          VHL.focus.update_focus(sectionClicked);
          $('.js-dashboard-accordion').hide();
        } else {
          VHL.focus.update_focus_via_ajax(sectionClicked, false, getAveragesForFocusedCourseOrSection);
        }
      }
    }
  }

  /**
   * Prepare view to show other course & update course focus.
   * @param {HTMLElement} courseClicked - Course item from course list.
   */
  function toggleCourse(courseClicked) {
    closeAllGearMenus();

    // Show the scheduled release text from the partial when viewing by course
    $('.js-due-date-scheduled').show();

    hideSections();
    getAveragesForFocusedCourseOrSection();
    if (screen.width < 900) {
      VHL.focus.update_focus(courseClicked);
    } else {
      VHL.focus.update_focus_via_ajax(courseClicked);
    } 
  }

  /**
   * Close all visible sections.
   */
  function hideSections() {
    $('.js-section-wrapper-detail')
      .addClass('u-hidden')
      .attr('aria-expanded', false);
    $('.js-section-wrapper-summary')
      .removeClass('is-active');
  }

  /**
   * Set element to show a selected section
   * @param {HTMLElement} sectionClicked - Section selected
   */
  function showSection(sectionClicked) {
    const sectionId = 'section_' + $(sectionClicked).attr('data-section-id');
    const widgetContainer = $('.js-widget-container-' + sectionId + '-detail' + ' .js-widget');
    const widgetTables = $('.js-' + sectionId + '-wrapper .js-section-widget-table');
    widgetContainer.each(function(index, element) {
      const widgetInfo = $(widgetTables[index]);
      $(element).after(widgetInfo);
    });

    $('.js-widget-container-' + sectionId + '-detail')
      .removeClass('u-hidden')
      .attr('aria-expanded', true);
    $('.js-widget-container-' + sectionId + '-summary')
      .addClass('is-active');
  }
 
  /**
   * Construct section or section-categories average endpoint URL.
   * @param {String} sectionId - Section id
   * @param {String} endpoint - Endpoint of average type.
   * @returns 
   */
  function endpointUrl(sectionId, endpoint) {
    const base = `/instructor/dashboard/${VHL.Common.program_id()}`;
    return `${base}/${endpoint}/${sectionId}`;
  }

  function isSectionAverageHidden(sectionId) {
    return !(document.querySelector(
      `.js-dashboard-section-${sectionId}[data-show-section-average="true"]`
    ));  
  }

  /** Populate DOM with section-average data;
   *  get it from endpoint if we don't already have it.
   * @param {Number} sectionId - Section id.
   * @param {*} successCallback - Callback for success result.
   * @param {*} isSynchronous - Flag to indicate if ajax call is synchronous.
   */
  function getSectionAverage(sectionId, successCallback, isSynchronous) {
    if (isSectionAverageHidden(sectionId)) { return; }
    if (sectionAverages.overall[sectionId]) {
      successCallback(sectionAverages.overall[sectionId]);
    } else {
      $.ajax({
        url: endpointUrl(sectionId, 'section_average'),
        async: !isSynchronous,
        success: function(data) {
          sectionAverages.overall[data.section_id] = data.results;
          successCallback(data.results);
        }
      });
    }
  }

  /** Populate DOM with section-and-category-average data;
   *  get it from endpoint if we don't already have it.
   *  isSychronous = true will make the ajax a synchronous call.
   *  When making a focus change between sections of the same course,
   *  the call to VHL.focus.update_focus_via_ajax will wait for this
   *  function to complete before setting the focus solving a race
   *  condition involving the browser's session cookie.
   * @param {Number} section_id - Section id
   * @param {Function} success_callback - Function to call for success response.
   * @param {Boolean} isSynchronous - Flag to indicate if ajax call is synchronous.
   */
  function getSectionAndCategoryAverages(section_id, success_callback, isSynchronous) {
    if (sectionAverages.section_and_categories[section_id]) {
      success_callback(sectionAverages.section_and_categories[section_id]);
    } else {
      $.ajax({
        url: endpointUrl(section_id, 'section_and_category_averages'),
        async: !isSynchronous,
        success: function (data) {
          sectionAverages.section_and_categories[data.section_id] = data.results;
          success_callback(data.results);
        }
      });
    }
  }

  /**
   * Callback to populate DOM with section-average data.
   * @param {Number} sectionId - Section id
   * @param {String} average - Average result to show
   */
  function populateSectionAverage(sectionId, average) {
    $('.js-section-' + sectionId + '-average').text(average);
    $(`.js-section-average-pulser-${sectionId}`).remove();
  }

  /**
   * Callback to populate DOM with section-category-average data.
   * @param {Number} sectionId - Section id
   * @param {Object} categoryAverages - Category average and id
   */
  function populateSectionCategoryAverages(sectionId, categoryAverages) {
    _.each(categoryAverages, function (idx, categoryId, value) {
      const selector = '.js-section-' + sectionId + '-category-' + categoryId + '-average';
      $(selector).text(value[categoryId]);
    });
  }

  /**
   * Callback to populate DOM with section-and-category-average data.
   * @param {Number} sectionId - Section id
   * @param {Object} response - data response to get average and category average
   */
  function populateSectionAndCategoryAverages(sectionId, response) {
    populateSectionAverage(sectionId, response.average);
    populateSectionCategoryAverages(sectionId, response.category_averages);
  }

  /** 
   * Pull section IDs from the DOM for the course in focus.
   */ 
  function focusedCourseSectionIds() {
    const section_elms = $('.js-course-info-' + dashboardFocus.course + '-wrapper .js-section-wrapper');
    return _.map(section_elms, function(elm) { return $(elm).data('section-id'); });
  }

  /**
   * Get section averages for course in focus.
   */
  function getCourseSectionAverages() {
    _.each(focusedCourseSectionIds(), function(sectionId) {
      if (isSectionAverageHidden(sectionId)) { return; }
      getSectionAverage(sectionId, function(response) {
        populateSectionAverage(sectionId, response.average);
      }, false);
    });
  }

  /** 
   * Get course-section or section/section-category averages,
   * depending on what's in focus.
   */
  function getAveragesForFocusedCourseOrSection() {
    if (!_.isEmpty(dashboardFocus)) {
      if (_.isNull(dashboardFocus.section)) {
        getCourseSectionAverages();
      } else {
        let section_id = dashboardFocus.section;
        getCourseSectionAverages();
        if (isSectionAverageHidden(section_id)) { return; }
        getSectionAndCategoryAverages(section_id, function(response) {
          populateSectionAndCategoryAverages(section_id, response);
        }, true);
      }
    }
  }

  return {
    init: init
  };

}());

