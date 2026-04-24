import { reject } from 'shared/utils';

/**
 * Returns an object containing section template attributes
 * @param {Object} section - Section Object.
 * @return {Object} - that contains section template attributes.
 */
const sectionTemplateStats = function(section) {
  return {
    trackName: section.selectedTrackName,
    firstUnit: section.calendar.firstUnitId,
    lastUnit: section.calendar.lastUnitId,
    droppedStrands: droppedStrands(section),
    microphoneActivities: section.includeMicrophoneActivities,
    instructorGradedActivities: section.includeInstructorGradedActivities,
    partnerActivities: section.includePartnerActivities,
  };
};

/**
 * This dispatches stats for sections created.
 */
function sendSectionStats() {
  const sectiondispatcher = new VHL.CarlinDispatch.Logstash('new_section');
  sectiondispatcher.dispatch('section');
}

/**
 * Dispatches stat indicating what type of template was applied to the section
 * @param {Object} stats - object containing section template attributes from sectionTemplateStats
 * @param {string} templateType - "learning_track_template" or "previous_section_template"
 */
const sendSectionTemplateStats = function(stats, templateType) {
  const ltDispatcher = new VHL.CarlinDispatch.Logstash(templateType);
  ltDispatcher.dispatch('section', stats);
};

/**
 * @private
 * Returns array of strand names unchecked in the UI.
 * @param {Object} section - Section Object.
 * @return {Array.<string>} - strands name.
 */
const droppedStrands = function(section) {
  const dropped = reject(section.strands, function(item) {
    return item.selected === true;
  });

  return dropped.map(function(item) {
    return item.name;
  });
};

export { sectionTemplateStats, sendSectionStats, sendSectionTemplateStats };
