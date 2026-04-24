import { isObjEmpty } from 'shared/utils';

/**
 * Class to render courses by school.
 */
export class SchoolSelectorDropdowns {
  /**
   * @constructor
   */
  constructor() {
    this.schoolSelectorDropdown = document.querySelector('.js-school-dropdown');
    this.coursesBySchool = document.querySelectorAll('.js-courses-by-school');

    const programMetaTag = document.querySelector('meta[name="VHL.program_id"]');
    this.stashKey = 'instructorDashLastSchoolSelected';
    const localContent = JSON.parse(localStorage.getItem(this.stashKey));
    this.stashedSchoolData = isObjEmpty(localContent) ? {} : localContent;
    this.programId = programMetaTag.getAttribute('content');

    const savedSchoolId = this.stashedSchoolData[this.programId];

    if (savedSchoolId && savedSchoolId !== this.currentSchoolID) {
      this.currentSchoolID = savedSchoolId;
      Array.from(this.schoolSelectorDropdown.options).forEach(
        (option) => {
          if (option.value == savedSchoolId) {
            option.selected = true;
          }
        }
      );
    }
    if (this.currentSchoolID === undefined) {
      this.currentSchoolID = this.schoolSelectorDropdown.value;
    }
  }

  /**
   * Add events to the DOM elements.
   */
  _assignEvents() {
    this.schoolSelectorDropdown.addEventListener('change', () => {
      this.currentSchoolID = this.schoolSelectorDropdown.value;

      this.stashedSchoolData[this.programId] = this.currentSchoolID;
      localStorage.setItem(this.stashKey, JSON.stringify(this.stashedSchoolData));

      this._moveActiveSchoolID();
      this._hideCursesBySchool();
      this._showCoursesBySchool(true);
      this._showAssistiveMessage();
    });
  }

  /**
  * Show assistive message for screenreader when school changes.
  */
  _showAssistiveMessage() {
    const assistiveContainer = document.querySelector('.js-assistive-school-msg');
    const schoolOption = [...this.schoolSelectorDropdown.options]
      .find((option) => option.value == this.schoolSelectorDropdown.value);
    assistiveContainer.textContent = `School selected: ${schoolOption.dataset.schoolName}`;
  }

  /**
   * Show all courses by school.
   * @param {boolean} schoolChanged - Whether called due to a new
   * school being chosen from the dropdown menu.
   */
  _showCoursesBySchool(schoolChanged) {
    this.coursesBySchool.forEach((element) => {
      const schoolID = element.dataset.schoolId;
      if (schoolID === this.currentSchoolID) {
        this._hasACourseActive(element, schoolChanged);
        element.classList.remove('u-dis-none');
      }
    });
  }

  /**
   * Hide all courses.
   */
  _hideCursesBySchool() {
    this.coursesBySchool.forEach((element) => {
      element.classList.add('u-dis-none');
    });
  }

  /**
   * Move active course ID when changing schools.  This allows for selecting of the
   * course add button by appcues, our tour guide vendor.
   */
  _moveActiveSchoolID() {
    const previouslySelectedSchoolDiv = document.getElementById('active-course-add');
    previouslySelectedSchoolDiv.removeAttribute('id');
    const selector = '.js-courses-by-school[data-school-id="' + this.currentSchoolID + '"]';
    const currentSchoolCoursesDiv = document.querySelector(selector);

    currentSchoolCoursesDiv.setAttribute('id', 'active-course-add');
  }


  /**
   * Check if the first course is active, if not, set it active by default.
   * @param {HTMLElement} course
   */
  _selectCourseByDefault(course) {
    const firstCourseOnList = course.querySelector('.js-course-name');
    if (firstCourseOnList) {
      VHL.focus.update_focus(firstCourseOnList);
    }
  }

  /**
   * Check id the courses by school list if there is an active course, if not set a default course.
   * @param {Array<HTMLElement>} courseList
   * @param {boolean} schoolChanged - Whether called due to a new
   * school being chosen from the dropdown menu.
   */
  _hasACourseActive(courseList, schoolChanged) {
    let isCourseActiveFlag = false;
    const courseListInformation = courseList.querySelectorAll('.js-course-information');
    if (courseListInformation.length > 0) {
      courseListInformation.forEach((element) => {
        if (element.classList.contains('is-active')) {
          isCourseActiveFlag = true;
        }
      });
      if (!isCourseActiveFlag || schoolChanged) {
        this._selectCourseByDefault(courseListInformation[0]);
      }
    } else {
      this._renderNoCoursesAndSections();
    }
  }

  /**
   * Render no courses & no sections view and focus.
   */
  _renderNoCoursesAndSections() {
    const focusButtonElm = document.querySelector('.js-focus-indicator-button');
    if (focusButtonElm) {
      const accordionElm = document.querySelector('.js-dashboard-accordion');
      accordionElm.innerHTML = `
        <div class="c-sections-wrapper__no-section">
          <p class="c-heading--page-title  u-txt-bold">No sections yet </p>
          <p>Before you can create sections you will first have to add a course.
        </div>`;

      focusButtonElm.innerHTML = `
        <span class="c-course-focus__none  focus_indicator_no_course">No course selected</span>
        <span class="c-icon  c-icon--sm  c-icon--circle-arrow-down"></span>`;
    }
  }

  /**
   * Init School select functionality.
   */
  init() {
    this._assignEvents();
    this._showCoursesBySchool(false);
    this._showAssistiveMessage();
  }
}
