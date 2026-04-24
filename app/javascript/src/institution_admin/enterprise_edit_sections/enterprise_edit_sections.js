import { postToEndpoint } from '../../shared/ajax_utils.js';

export default class EnterpriseEditSections {
  constructor() {
    this.instructorsSubform = document.querySelector('.js-additional-instructors-subform');
    this.instructorsCreateSubform = document.querySelector('.js-create-additional-instructors-subform');
    this.submitSectionData = this.submitSectionData.bind(this);
    this.submitSectionCreateData = this.submitSectionCreateData.bind(this);
    this.submitRedirectUrl = undefined;
  }
  
  initializeButtons() {
    this.initializeEditForm()
    this.initializeCancelButton();
  }

  initializeCreateForm() {
    this.initializeSubmitCreateButton();
    this.initializeAddInstructorCreatebutton();
    this.additionalInstructorsCount = 0;
    this.initializeCreateSectionName();
    this.initializeInstructorsCreateSubform();
  }

  initializeEditForm() {
    this.initializeSubmitButton();
    this.initializeAddInstructorbutton();
  }

  buildEditForm(sectionData) {
    this.additionalInstructorsCount = 0;
    this.sectionData = sectionData;
    this.populateFields();
    this.initializeInstructorsSubform();
  }

  openEditModal(sectionData) {
    this.buildEditForm(sectionData);
    this.openModal();
  }

  openModal() {
    document.querySelector('.js-edit-section-settings').showModal();
  }

  populateFields(){
    const sectionIdField = document.querySelector('.js-section-id');
    const sectionNameField = document.querySelector('.js-section-name-field');
    const sectionOwnerField = document.querySelector('.js-section-owner-field');
    const sectionOwnerVisibleCheckbox = document.querySelector('.js-section-owner-visible-checkbox');
    const sectionOpenCheckbox = document.querySelector('.js-section-open-checkbox');
    const sectionDaysToShowAssignmentDueDate = document.querySelector('.js-section-days-to-show-assignment-due-date');
    const sectionDueDateHour = document.querySelector('.js-section-due-date-hour');
    const sectionDueDateMin = document.querySelector('.js-section-due-date-min');
    const sectionDueDateAMPM = document.querySelector('.js-section-due-date-ampm');
    const sectionTimeZone = document.querySelector('.js-section-time-zone');

    sectionIdField.value = this.sectionData.section;
    sectionNameField.value = this.sectionData.name;
    sectionNameField.dispatchEvent(new Event('focus'));
    sectionOwnerField.value =
      `${this.sectionData.instructor.name} (${this.sectionData.instructor.email})`;
    sectionOwnerVisibleCheckbox.checked = !this.sectionData.hide_owner_name;
    sectionOpenCheckbox.checked = this.sectionData.open_to_students;
    sectionDaysToShowAssignmentDueDate.value =
      this.sectionData.days_to_show_assignment_due_date || '';
    sectionDaysToShowAssignmentDueDate.dispatchEvent(new Event('change'));
    sectionDueDateHour.value = this.sectionData.due_time.hours;
    sectionDueDateHour.dispatchEvent(new Event('change'));
    sectionDueDateMin.value = this.sectionData.due_time.minutes;
    sectionDueDateMin.dispatchEvent(new Event('change'));
    sectionDueDateAMPM.value = this.sectionData.due_time.ampm;
    sectionDueDateAMPM.dispatchEvent(new Event('change'));
    sectionTimeZone.value = this.sectionData.time_zone;
    sectionTimeZone.dispatchEvent(new Event('change'));
  }

  initializeCreateSectionName() {
    const sectionNameField = document.querySelector('.js-create-section-name-field');
    const saveButton = document.querySelector('.js-create-section-submit');
    sectionNameField.addEventListener('input', () => {
      saveButton.disabled = !sectionNameField.value.trim();
    });
  }

  initializeAddInstructorbutton() {
    const addInstructorButton = document.querySelector('.js-add-instructor');
    addInstructorButton.addEventListener('click', () => {
      this.addInstructorWithButton();
    })
  }

  initializeAddInstructorCreatebutton() {
    const addInstructorButton = document.querySelector('.js-create-add-instructor');
    addInstructorButton.addEventListener('click', () => {
      this.addInstructorWithCreateButton();
    })
  }

  initializeSubmitButton() {
    const form = document.querySelector('.js-edit-section-form');
    form.addEventListener('submit', (event) =>{
      event.preventDefault();
      this.submitSectionData();
    });
  };

  initializeSubmitCreateButton() {
    const form = document.querySelector('.js-create-section-form');
    form.addEventListener('submit', (event) =>{
      event.preventDefault();
      this.submitSectionCreateData();
    });
    this.disableButtonBySelector('.js-create-section-submit');
  };

  initializeCancelButton() {
    const cancelButton = document.querySelector('.js-edit-section-cancel');
    cancelButton.addEventListener('click', () => {
      document.querySelector('.js-edit-section-settings').closeModal();
    });
  }

  initializeCancelCreateButton() {
    const cancelButton = document.querySelector('.js-create-section-cancel');
    cancelButton.addEventListener('click', () => {
      document.querySelector('.js-create-section-settings').closeModal();
    });
  }

  disableButtonBySelector(selector) {
    const button = document.querySelector(selector);
    button.disabled = true;
  }

  addInstructorWithButton(){
    const possibleInstructorsCount = this.getPossibleInstructors().length;
    if (possibleInstructorsCount > this.additionalInstructorsCount) {
      this.createFormFieldGroup();
    }
  }

  addInstructorWithCreateButton(){
    const possibleInstructorsCount = this.getPossibleInstructors().length;
    if (possibleInstructorsCount > this.additionalInstructorsCount) {
      this.createFormFieldCreateGroup();
    }
  }

  initializeInstructorsCreateSubform(){
    this.instructorsCreateSubform.replaceChildren();
  }

  initializeInstructorsSubform(){
    this.instructorsSubform.replaceChildren();
    const additionalInstructors = this.sectionData.additional_instructors;
    additionalInstructors.forEach((instructor) => {
      this.createFormFieldGroup(instructor.id, instructor.role, instructor.show);
    });
  }

  createFormFieldGroup(id, role, show_instructor){
    this.additionalInstructorsCount++;
    const selectControls = document.createElement('div');
    selectControls.classList.add('l-simple-grid-v3', 'l-simple-grid-v3--2-1', 'u-mar-top-24');
    const instructorSelector = this.createInstructorSelect(this.additionalInstructorsCount, id);
    const roleSelector = this.createRoleSelector(this.additionalInstructorsCount, role);
    const visibilityCheckbox = this.createInstructorVisibilityCheckbox(this.additionalInstructorsCount, show_instructor);
    selectControls.append(instructorSelector, roleSelector);
    this.instructorsSubform.append(selectControls, visibilityCheckbox);
  }

  createFormFieldCreateGroup(id, role, show_instructor){
    this.additionalInstructorsCount++;
    const selectControls = document.createElement('div');
    selectControls.classList.add('l-simple-grid-v3', 'l-simple-grid-v3--2-1', 'u-mar-top-24');
    const instructorSelector = this.createInstructorSelect(this.additionalInstructorsCount, id);
    const roleSelector = this.createRoleSelector(this.additionalInstructorsCount, role);
    const visibilityCheckbox = this.createInstructorVisibilityCheckbox(this.additionalInstructorsCount, show_instructor);
    selectControls.append(instructorSelector, roleSelector);
    this.instructorsCreateSubform.append(selectControls, visibilityCheckbox);
  }

  createRoleSelector(index, selectedRole = ''){
    const musicSelectField = document.createElement('music-select-field-v3');
    const label = document.createElement('label');
    label.setAttribute('for', `instructor_role_${index}`);
    label.innerText = 'Role';

    const select = document.createElement('select');
    const options = this.roleOptions();
    select.classList.add('music-select', 'test-additional-instructor-role');
    select.required = true;
    select.setAttribute('name', `instructor_role_${index}`);
    select.append(...options);
    select.value = selectedRole;
    
    musicSelectField.append(label, select);
    return musicSelectField;
  }

  createInstructorSelect(index, instructor_id = ''){
    const musicSelectField = document.createElement('music-select-field-v3');
    const label = document.createElement('label');
    label.setAttribute('for', `additional_instructor_${index}`);
    label.innerText = 'Additional Instructor';

    const select = document.createElement('select');
    const options = this.instructorOptions();
    select.classList.add('music-select', 'test-additional-instructor');
    select.setAttribute('name', `additional_instructor_${index}`);
    select.append(...options);
    select.value = instructor_id;

    musicSelectField.append(label, select);
    return musicSelectField;
  }

  createInstructorVisibilityCheckbox(index, show_instructor = false){
    const formItem = document.createElement('div');
    formItem.classList.add('c-form-item', 'u-mar-top-12');
    const label = document.createElement('label');
    label.setAttribute('for', `show_instructor_${index}`);
    label.classList.add('c-form-item__label');
    label.innerText = 'Visible to students in course';

    const checkbox = document.createElement('input');
    checkbox.setAttribute('type', 'checkbox');
    checkbox.value = 'true';
    checkbox.setAttribute('name', `show_instructor_${index}`);
    checkbox.setAttribute('id', `show_instructor_${index}`);
    checkbox.classList.add('c-form-item__checkbox');
    checkbox.checked = show_instructor;

    formItem.append(checkbox, label);
    return formItem;
  }

  roleOptions(){
    const roles = ['', 'Co-instructor', 'Assistant'];
    const options = roles.map( (role) => {
      const option = new Option(role, role);
      return option;
    });
    return options;
  }

  getPossibleInstructors() {
    const instructorsFromDom = document.querySelector('.js-possible-instructors');
    return JSON.parse(instructorsFromDom.getAttribute('data-instructors')).additional_instructors;
  }

  instructorOptions() {
    const instructors = this.getPossibleInstructors();
    const options = instructors.map( (instructor) => {
      const instructorNameAndEmail = `${instructor.full_name} (${instructor.email})`;
      const option = new Option(instructorNameAndEmail, instructor.id);
      return option;
    } );
    options.unshift(new Option(''));
    return options;
  }

  submitSectionData() {
    const url = `${location.origin}/institution_admin/update_section.json`;
    const payload = this.payload();
    this.disableButtonBySelector('.js-edit-section-submit');
    postToEndpoint(
      url,
      payload,
      (data) => {
        location.reload(true)
      }
    );
  }

  submitSectionCreateData() {
    const url = `${location.origin}/institution_admin/create_section.json`;
    const payload = this.payloadCreate();
    this.disableButtonBySelector('.js-create-section-submit');
    postToEndpoint(
      url,
      payload,
      (data) => {
        location.reload(true)
      }
    );
  }

  payloadCreate() {
    const dataFromForm = this.parseCreateForm();
    const payload = { section: {} };
    const dueDateHour = dataFromForm.get('due_date_hour');
    const dueDateMin = dataFromForm.get('due_date_min');
    const dueDateAMPM = dataFromForm.get('due_date_ampm');

    payload.school_id = parseInt(dataFromForm.get('school_id'));
    payload.course_id = parseInt(dataFromForm.get('course_id'));
    payload.section.open_to_students = dataFromForm.get('create_open_to_students') == 'on';
    payload.section.course_id = parseInt(dataFromForm.get('course_id'));
    payload.section.name = dataFromForm.get('section_name');
    payload.section.hide_owner_name = dataFromForm.get('create_show_course_owner') == 'true';
    payload.section.days_to_show_assignment_due_date = parseInt(dataFromForm.get('before_due_date'));
    payload.section.time_zone = dataFromForm.get('time_zone');
    payload.section.due_time = this.parseTo24Hour(`${dueDateHour}:${dueDateMin}${dueDateAMPM}`);

    const suffix = this.additionalInstructorsCount;
    const additionalInstructors = [];

    for (let i = 1; i <= suffix; i++) {
      const instructorIdKey = `additional_instructor_${i}`;
      const instructorRoleKey = `instructor_role_${i}`;
      const showInstructorKey = `show_instructor_${i}`;
      const instructorId = parseInt(dataFromForm.get(instructorIdKey));
      const instructorRole = dataFromForm.get(instructorRoleKey);

      const entry = {};
      entry.instructor_id = instructorId;
      entry.role = instructorRole;
      entry.show = dataFromForm.get(showInstructorKey) == 'true';

      additionalInstructors.push(entry);
    }
    payload.section.additional_instructors = additionalInstructors;
    return payload;
  }

  payload() {
    const dataFromForm = this.parseForm();
    const payload = { section: {} };
    const dueDateHour = dataFromForm.get('due_date_hour');
    const dueDateMin = dataFromForm.get('due_date_min');
    const dueDateAMPM = dataFromForm.get('due_date_ampm');
    payload.section.section_id = parseInt(dataFromForm.get('section_id'));
    payload.section.course_id = parseInt(dataFromForm.get('course_id'));
    payload.section.name = dataFromForm.get('section_name');
    payload.section.hide_owner_name = dataFromForm.get('show_course_owner') !== 'true';
    payload.section.open_to_students = dataFromForm.get('section_open_to_students') == 'true';
    payload.section.days_to_show_assignment_due_date =
      dataFromForm.get('days_to_show_assignment_due_date');
    payload.section.time_zone = dataFromForm.get('time_zone');
    payload.section.due_time = this.parseTo24Hour(`${dueDateHour}:${dueDateMin}${dueDateAMPM}`);

    const suffix = this.additionalInstructorsCount;
    const additionalInstructors = [];

    for (let i = 1; i <= suffix; i++) {
      const instructorIdKey = `additional_instructor_${i}`;
      const instructorRoleKey = `instructor_role_${i}`;
      const showInstructorKey = `show_instructor_${i}`;
      const instructorId = parseInt(dataFromForm.get(instructorIdKey));
      const instructorRole = dataFromForm.get(instructorRoleKey);

      const entry = {};
      entry.instructor_id = instructorId;
      entry.role = instructorRole;
      entry.show = dataFromForm.get(showInstructorKey) == 'true';

      additionalInstructors.push(entry);
    }
    payload.section.additional_instructors = additionalInstructors;
    return payload;
  }

  parseForm() {
    const form = document.querySelector('.js-edit-section-form');
    const formData = new FormData(form);
    return formData;
  }

  parseCreateForm() {
    const form = document.querySelector('.js-create-section-form');
    const formData = new FormData(form);
    return formData;
  }

  parseTo24Hour(timeStr) {
    const [hours, minutesPeriod] = timeStr.split(':');
    const minutes = minutesPeriod.slice(0, 2);
    const period = minutesPeriod.slice(2);

    let hour = parseInt(hours);
    if (period === 'PM' && hour !== 12) hour += 12;
    if (period === 'AM' && hour === 12) hour = 0;

    return `${hour.toString().padStart(2, '0')}:${minutes}:00`;
  }
}
