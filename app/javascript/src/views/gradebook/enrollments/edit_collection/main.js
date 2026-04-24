import StudentRemovalManager from './student_removal_manager.js';
import '~/src/views/roster/roster.scss';

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  const manager = new StudentRemovalManager();
  manager.init();
});
