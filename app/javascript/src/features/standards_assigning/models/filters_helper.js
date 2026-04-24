import { ref } from 'vue';

const matchingContentCount = ref(null);

/**
 * Counts the number of matching content items and updates the matchingContentCount value.
 * @param {Ref<number>} matchingContentCount - The reference to the count of matching content items.
 */
function updateMatchingContentCount(matchingContentCount) {
  const visibleItems = document.querySelectorAll('.aligned-items:not(.u-hidden)');
  matchingContentCount.value = visibleItems.length;
}

/**
 * Shows the selected items by removing the 'u-hidden' class.
 * @param {string} selector - The selector of the items to show.
 */
function showItems(selector) {
  const items = document.querySelectorAll(selector);
  items.forEach((item) => item.classList.remove('u-hidden'));
}

/**
 * Hides the items not selected by adding the 'u-hidden' class.
 * @param {string} selector - The selector of the items to hide.
 */
function hideItems(selector) {
  const items = document.querySelectorAll(selector);
  items.forEach((item) => item.classList.add('u-hidden'));
}

/**
 * Handles the change of status and content type by showing or hiding items accordingly.
 * @param {string} newStatus - The new status ('Assigned', 'Unassigned', or 'All').
 * @param {string} newContentType - The new content type
 * ('Activity', 'Assessment', 'Teacher Edition' or 'All').
*/
function handleFilterChange(newStatus, newContentType) {
  switch (newContentType) {
  case 'All':
    handleItemsForAllContentType(newStatus);
    break;
  case 'Activity':
    handleItemsForActivityContentType(newStatus);
    break;
  case 'Assessment':
    handleItemsForAssessmentContentType(newStatus);
    break;
  case 'Teacher Edition':
    showItems('.c-ereader-item');
    hideItems('.c-activity-item');
    hideItems('.c-assessment-item');
  }
  updateMatchingContentCount(matchingContentCount);
}

/**
 * Handles the items for the 'All' content type.
 * @param {string} newStatus - The new status ('Assigned', 'Unassigned', or 'All').
 */
function handleItemsForAllContentType(newStatus) {
  switch (newStatus) {
  case 'All':
    showItems('.c-activity-item');
    showItems('.c-assessment-item');
    showItems('.c-ereader-item');
    break;
  case 'Assigned':
    showItems('.c-assigned-item');
    hideItems('.c-unassigned-item');
    break;
  case 'Unassigned':
    showItems('.c-unassigned-item');
    hideItems('.c-assigned-item');
    break;
  }
}

/**
 * Handles the items for the 'Activity' content type.
 * @param {string} newStatus - The new status ('Assigned', 'Unassigned', or 'All').
 */
function handleItemsForActivityContentType(newStatus) {
  switch (newStatus) {
  case 'All':
    showItems('.c-activity-item');
    hideItems('.c-assessment-item');
    hideItems('.c-ereader-item');
    break;
  case 'Assigned':
    showItems('.c-assigned-item');
    hideItems('.c-unassigned-item');
    hideItems('.c-assessment-item');
    hideItems('.c-ereader-item');
    break;
  case 'Unassigned':
    showItems('.c-unassigned-item');
    hideItems('.c-assigned-item');
    hideItems('.c-assessment-item');
    hideItems('.c-ereader-item');
    break;
  }
}

/**
 * Handles the items for the 'Assessment' content type.
 * @param {string} newStatus - The new status ('Assigned', 'Unassigned', or 'All').
 */
function handleItemsForAssessmentContentType(newStatus) {
  switch (newStatus) {
  case 'All':
    showItems('.c-assessment-item');
    hideItems('.c-activity-item');
    hideItems('.c-ereader-item');
    break;
  case 'Assigned':
    showItems('.c-assigned-item');
    hideItems('.c-unassigned-item');
    hideItems('.c-activity-item');
    hideItems('.c-ereader-item');
    break;
  case 'Unassigned':
    showItems('.c-unassigned-item');
    hideItems('.c-assigned-item');
    hideItems('.c-activity-item');
    hideItems('.c-ereader-item');
    break;
  }
}

export {
  handleFilterChange,
  matchingContentCount,
  updateMatchingContentCount,
};
