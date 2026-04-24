import * as ajaxUtils from 'shared/ajax_utils';
import ActivityNotes from 'features/instructor_notes/ActivityNotes';
import AddActivityNote from 'features/instructor_notes/AddActivityNote';
import { createApp } from 'vue';

/** Class representing a Activity Notes Setup. */
class ActivityNoteSetup {
  /**
   * Setup the configutation required mounting activity notes vue apps.
   * @param {object} options
   * options parameter includes following:
   * 1. allowsExpandedNotes (boolean): Whether or not expanded notes are allowed.
   *    For PChat, Vchat and VVchat expaded notes are not allowed.
   * 2. railsData (object): rails data includes Program Id, activity Id etc.
   * 3. userType (string): User type of current user (Instructor or
   *    Student).
   */
  constructor(options) {
    this.allowsExpandedNotes = options.allowsExpandedNotes;
    this.controllerType = options.controllerType;
    this.railsData = options.railsData;
    this.userType = options.userType;
    this.directionLineElm = ActivityNoteSetup.getDirectionLineElm();
    this.activityNotes = [];
    this.activityNoteApps = {};
  }

  /**
   * getNotableElements.
   * @return {HTMLElement} NodeList of all notable elements.
   */
  static getNotableElements() {
    return document.querySelectorAll('[data-instructor-notable]');
  }

  /**
   * getDirectionLineElm.
   * @return {HTMLElement} direction line element.
   */
  static getDirectionLineElm() {
    return document.querySelector('.js-direction-line');
  }

  /**
   * getDirectionLineElm.
   * @param {HTMLElement} elm Given html element.
   * @return {boolean} returns whether given elm is direction-line or not.
   */
  isDirectionLineElm(elm) {
    return elm === this.directionLineElm;
  }

  /**
   * getNotes.
   *  @return {Promise<array>} A promise that return array of instructor notes
   * when fulfilled.
   */
  getNotes() {
    if (this.railsData.activity_notes) {
      return this.railsData.activity_notes;
    }

    const programId = this.railsData.program_id;
    const activityId = this.railsData.activity_id;
    return new Promise((resolve) => {
      ajaxUtils.getFromEndpoint(
        `/instructor/${programId}/activity/${activityId}/activity_notes`,
        (data) => {
          resolve(data);
        }
      );
    });
  }

  /**
   * initAddNoteApp.
   * Mounts Add Instructor Note app on the '.js-add-instructor-note-app'.
   * @return {object} vm Add Instructor note vue object.
   */
  initAddNoteApp() {
    const self = this;
    const el = document.querySelector('.js-add-instructor-note-app');
    const app = createApp(AddActivityNote, {
      activityId: self.railsData.activity_id,
      programId: self.railsData.program_id,
      allowsExpandedNotes: self.allowsExpandedNotes,
    });
    const vm = app.mount(el);
    return vm;
  }

  /**
   * createNoteElm.
   * Create a HTML div Element for the notable element, on which vue
   * app will be mounted.
   * @param {HTMLElement} notableElm Given notable element.
   * @return {HTMLElement} return the created HTML div Element.
   */
  createNoteElm(notableElm) {
    const activityNoteRootElm = document.createElement('div');
    activityNoteRootElm.className = 'c-instructor-note-container';
    /**
       * if the current notable element is DL then notes will added below it
       * otherwise notes are added above it.
     */
    if (this.isDirectionLineElm(notableElm)) {
      notableElm.parentElement.insertBefore(
        activityNoteRootElm,
        notableElm.nextSibling
      );
    } else {
      notableElm.parentElement.insertBefore(activityNoteRootElm, notableElm);
    }
    return activityNoteRootElm;
  }

  /**
   * Create vue app for the activity notes disclosure (of a single notable element).
   * @param {array} notes notes array for a given notable element.
   * @param {HTMLElement} notableElm Given notable element.
   * @return {HTMLElement} return the created HTML div Element.
   */
  createNoteApp(notes, notableElm) {
    const noteContainer = this.createNoteElm(notableElm);
    if (document.querySelector('.t-supersites-jr')) {
      noteContainer.classList.add('c-supersite-jr-activity-context__instructor-notes');
    }
    const app = createApp(ActivityNotes, {
      notes: notes,
      appId: notableElm.id,
    });

    app.provide('allowsExpandedNotes', this.allowsExpandedNotes);
    app.provide('activityId', this.railsData.activity_id);
    app.provide('controllerType', this.controllerType);
    app.provide('programId', this.railsData.program_id);
    app.provide('userType', this.userType);
    const vm = app.mount(noteContainer);
    return vm;
  }

  /**
   * getNoteApps.
   * @return {object} object contaning vue apps for each notable element.
   */
  getNoteApps() {
    const apps = {};
    const notableElms = ActivityNoteSetup.getNotableElements();
    for (const notableElm of notableElms) {
      const notes = this.activityNotes?.filter(
        (note) => note.note_item_id === notableElm.id
      );
      apps[notableElm.id] = this.createNoteApp(notes, notableElm);
    }
    return apps;
  }

  /**
   * attachNotes.
   * Attach vue apps containg notes disclosure for all the notable elements.
   */
  async attachNotes() {
    this.activityNotes = await this.getNotes();
    if (this.allowsExpandedNotes) {
      this.activityNoteApps = this.getNoteApps();
    } else {
      this.activityNoteApps['direction_line'] = this.createNoteApp(
        this.activityNotes,
        this.directionLineElm
      );
    }
  }
}

export default ActivityNoteSetup;
