import { metaTagContent } from 'shared/utils.js';

/**
 * Class representing Http service of section wizard.
 */
class SectionHttp {
  /**
   * Instantiate the SectionHttp class.
   */
  constructor() {
    this.instAdmin = metaTagContent('VHL.in_institution_admin') === 'true';
    this.schoolId = metaTagContent('VHL.course_school_id');
  }

  /**
   * Redirect the application to create another section for the course.
   */
  createAnotherSection() {
    const params = this.parseUrl();
    window.location = `/instructor/${params.program_id}/courses/${params.course_id}/sections/new`;
  }

  /**
   * Extract program id and course id from URL.
   * @return {Object} - An object that contains programId and courseId.
   */
  parseUrl() {
    const regex = this.instAdmin ?
      /\/institution_admin\/([0-9]+)\/courses\/([0-9]+)\/section_templates\/(new|([0-9]+\/edit))/ :
      /\/instructor\/([0-9]+)\/courses\/([0-9]+)\/sections\/(new|([0-9]+\/edit))/;

    const results = regex.exec(window.location);
    return { programId: results[1], courseId: results[2] };
  }

  /**
   * Redirect the application to the dashboard page.
   */
  returnToDashboard() {
    const params = this.parseUrl();
    window.location = this.instAdmin ?
      `/institution_admin/templates/${params.programId}?` +
      `school_id=${this.schoolId}&template_id=${params.courseId}` :
      `/instructor/dashboard/${params.programId}`;
  }
}

export default SectionHttp;
