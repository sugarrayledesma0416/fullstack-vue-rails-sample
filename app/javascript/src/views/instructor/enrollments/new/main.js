import '~/src/views/instructor/enrollments/tables.scss';
import '~/src/views/instructor/enrollments/new/add_students.scss';
import { StudentEnrollmentManager } from './student_enrollment_manager';

document.addEventListener('DOMContentLoaded', () => { 
  new StudentEnrollmentManager();
});
