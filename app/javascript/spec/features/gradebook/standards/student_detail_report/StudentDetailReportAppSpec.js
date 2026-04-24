import { shallowMount } from '@vue/test-utils';
/* eslint-disable-next-line max-len */
import StudentDetailReportApp from 'features/gradebook/standards/student_detail_report/StudentDetailReportApp';
import { createPinia, setActivePinia } from 'pinia';

const props = {
  availableSets: '{"CCSS":[{"id":38,"display_name":"CCSS"}],"FL B.E.S.T.":[{"id":32,"display_name":"FL B.E.S.T."}],"Texas ELPs":[{"id":44,"display_name":"Texas ELPs"}],"Texas TEKS":[{"id":45,"display_name":"Texas TEKS"},{"id":33,"display_name":"Texas TEKS"}],"WIDA":[{"id":31,"display_name":"WIDA"},{"id":39,"display_name":"WIDA"}]}',
  config: '{"cumulative_average": 95.0}',
  errorIconPath: 'path/to/error/icon',
  gradeCategoriesUrl: '/gradebook/370/courses/38/sections/53/standards/31/student_detail_report/24/grade_categories/',
  reviewPath: 'review/path',
  rosterPath: 'Roster path',
  rosterStudentList: '[ {"id":24,"first_name":"Brando","last_name":"Kunde","username":"vhl_1_student","email":"vhl_1_student@vistahigherlearning.com","crypted_password":null,"password_salt":null,"persistence_token":null,"single_access_token":null,"perishable_token":null,"login_count":0,"failed_login_count":0,"last_request_at":null,"current_login_at":null,"last_login_at":null,"current_login_ip":null,"last_login_ip":null,"year_of_birth":2010,"secret_question":null,"secret_answer":null,"first_dashboard_viewed_at":"2024-06-26T22:32:36-04:00","created_at":"2015-10-16T16:24:43-04:00","updated_at":"2024-06-26T18:32:36-04:00","student_id":"8675309","time_zone":null,"preferred_time_zone":null,"temp_password":false,"slx_contact_id":null,"fake":false,"display_email":false,"archived":false,"registration_window_open":true,"pronto_activated":false,"pronto_activated_at":null,"salesforce_id":null,"active":true,"gender":null,"guid":"24","sync_token":0,"request_id":null},{"id":26,"first_name":"Elmira","last_name":"Mills","username":"vhl_3_student","email":"vhl_3_student@vistahigherlearning.com","crypted_password":null,"password_salt":null,"persistence_token":null,"single_access_token":null,"perishable_token":null,"login_count":0,"failed_login_count":0,"last_request_at":null,"current_login_at":null,"last_login_at":null,"current_login_ip":null,"last_login_ip":null,"year_of_birth":2010,"secret_question":null,"secret_answer":null,"first_dashboard_viewed_at":"2024-06-27T14:34:09-04:00","created_at":"2015-10-16T16:24:45-04:00","updated_at":"2024-06-27T10:34:09-04:00","student_id":"8675309","time_zone":null,"preferred_time_zone":null,"temp_password":false,"slx_contact_id":null,"fake":false,"display_email":false,"archived":false,"registration_window_open":true,"pronto_activated":false,"pronto_activated_at":null,"salesforce_id":null,"active":true,"gender":null,"guid":"26","sync_token":0,"request_id":null}]',
  selectedStandardGuid: null,
  standardId: '18',
  standardsAssigningUrl: 'assingning/url',
  standardSet: '31',
  standardsLandingPagePath: '/gradebook/370/courses/39/sections/54/standards/landing_page',
  studentId: '24',
  studentName: 'Brando Kunde',
  successIconPath: 'path/to/success/icon',
  unitSelected: null,
  unitSelectedFromSectionReport: '{"id": "2965", "name": "Unit 1"}',
};

const pinia = createPinia();
setActivePinia(pinia);

function getWrapper() {
  return shallowMount(
    StudentDetailReportApp,
    {
      global: { plugins: [pinia] },
      props: props,
    });
}

describe(
  'StudentDetailReportAppSpec',
  () => {
    let wrapper;
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('Check if standard id exist', () => {
      expect(wrapper.vm.standardSet).not.toBeNull();
    });

    it('Shows the student name', ()=> {
      expect(wrapper.find('.test-student-name').exists()).toBeTruthy();
    });
  }
);
