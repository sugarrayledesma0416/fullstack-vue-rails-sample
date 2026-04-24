import CreateCourseModal from './create_course_modal.js';

window.addEventListener('DOMContentLoaded', (event) => {
  let modalElm = document.querySelector('.js-create-course-modal');
  const createCourseModal = new CreateCourseModal(modalElm);
  document.querySelector('.js-create-course').addEventListener('click', (event) => {
    event.preventDefault();
    createCourseModal.open();
  });
});