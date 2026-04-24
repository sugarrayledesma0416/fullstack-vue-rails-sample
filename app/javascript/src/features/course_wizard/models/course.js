import { reject } from 'shared/utils';

/**
 * @typedef {
 *  import('features/course_wizard/services/course_serializer.js').CategoryObject
 * } CategoryObject
 */

/**
 * Course Class
 */
class Course {
  /**
   * Initialize Course
   * @constructor
   */
  constructor() {
    this.aiVirtualChatLevel = false;
    this.allowIndividualAssign = false;
    this.allowMultipleLessonsOnDates = false;
    this.allowsHelpRequests = true;
    this.allowsReviewRequests = true;
    this.breakGroupAcrossDates = false;
    this.breakStrandAcrossDates = false;
    this.categories = [];
    this.chatLevel = 'partner_chat';
    this.classDays = [];
    this.courseOwnerUserId = null;
    this.copyCreatedActivitiesFromPreviousCourse = false;
    this.copySharedActivitiesFromPreviousCourse = false;
    this.components = [];
    this.courseLibraryFrom = null;
    this.currentStep = '';
    this.displayOnDashboard = null;
    this.enableVocabTutorialTranslations = false;
    this.endDate = '';
    this.firstUnitId = 1;
    this.isTemplate = false;
    this.lastUnitId = 6;
    this.level = null;
    this.ltiRosterLinked = '';
    this.name = '';
    this.namePlaceholder = 'New course';
    this.oneRosterLinked = '';
    this.pathType = null;
    this.potentialInstructors = [];
    this.possibleClassDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    this.removedCategories = [];
    this.sections = [{}];
    this.selectedLearningTrack = '';
    this.shareToGoogleClassroom = true;
    this.showEstimatedTimes = true;
    this.startDate = '';
    this.standardSetIds = [];
  }

  /**
   * returns display course name
   * @return {string}
   */
  get displayName() {
    return this.name && this.name.length > 0 ? this.name : this.namePlaceholder;
  }

  /**
   * returns if a standard set group is selected or not.
   * A group is selected if at least one of its standard set is selected in the course.
   * @param {Object} group
   * @return {boolean}
   */
  isStandardSetGroupSelected(group) {
    return this.standardSetIds.find((id) => group.ids.includes(id)) !== undefined;
  }

  /**
   * removes the category from the course.
   * @param {CategoryObject} categoryToBeRemoved
   */
  removeCategory(categoryToBeRemoved) {
    this.categories = reject(this.categories, (cat) => {
      return categoryToBeRemoved === cat;
    });

    if (categoryToBeRemoved.id) {
      categoryToBeRemoved._destroy = true;
      this.removedCategories.push(categoryToBeRemoved);
    }
    this.updateRank();
  }

  /**
   * @private
   * Updates the rank of the category.
   */
  updateRank() {
    for (const categoryIndex in this.categories) {
      if (Object.prototype.hasOwnProperty.call(this.categories, categoryIndex)) {
        this.categories[categoryIndex].rank = parseInt(categoryIndex) + 1;
      }
    }
  }
}

export default Course;
