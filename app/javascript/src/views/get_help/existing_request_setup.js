import * as ajaxUtils from 'shared/ajax_utils';
import { reactive, createApp } from 'vue';
import HelpableItemRequestsList from 'features/get_help/HelpableItemRequestsList';
import { filterRequestProperties } from 'features/get_help/utils';


/** Class representing a Existing Help Request Setup. */
class ExistingRequestSetup {
  /**
  * Initialise function for ExistingRequestSetup
  * @param {object} opts Object containing metadata.
  * @param {string} allowsExpandedNotes defines whether expanded notes are allowed or not.
  */
  constructor(opts) {
    this.metaData = opts.metaData;
    this.apps = {};
  }

  /**
   * get all requests attach to the activity and user.
   * @return {Promise}.
   */
  getAllRequests() {
    if (this.metaData.userType === 'Student') {
      return new Promise((resolve) => {
        ajaxUtils.getFromEndpoint(
          `/sections/${this.metaData.sectionId}/activities/${this.metaData.activityId}` +
          '/help_requests',
          (data) => resolve(data)
        );
      });
    } else {
      const requestData = JSON.parse(
        document.querySelector('.js-help-request-rails-data').getAttribute('data-from-dom')
      );
      const requestUrl = `/instructor/${this.metaData.programId}/activity/` +
      `${requestData.activity_id}/activity_help_requests?question_id=` +
      `${requestData.question_id}&student_ids[0]=${requestData.user_id[0]}`;
      return new Promise((resolve) => {
        ajaxUtils.getFromEndpoint(
          requestUrl,
          (data) => resolve(data)
        );
      });
    }
  }

  /**
   * Attaches the help requests for the corresponding page.
   */
  async addRequests() {
    this.activityRequests = await this.getAllRequests();
    this.activityRequests = this.rearrangeRequests();

    this.onRequestChange();
    for (const elmSelector in this.activityRequests) {
      // To filter unwanted properties from the prototype  guard-for-in (Eslint Feedback).
      if (Object.prototype.hasOwnProperty.call(this.activityRequests, elmSelector)) {
        const requestObj = this.activityRequests[elmSelector][0];
        const requestContainer = this.createRequestElement(
          elmSelector,
          requestObj.user_id,
          requestObj.request_type,
          requestObj.helpable_item_type
        );
        this.apps[elmSelector] = this.createRequestApp(
          requestContainer, this.activityRequests[elmSelector], elmSelector
        );
      }
    }
    return this.apps;
  }

  /**
   * Rearranging the requests for further vue app use.
   * @return {Object}.
   */
  rearrangeRequests() {
    const requests = {};
    this.activityRequests.map((request) => {
      if (request.helpable_item_id in requests) {
        requests[request.helpable_item_id].push(request);
      } else {
        const elm = document.getElementById(request.helpable_item_id);
        if (request.request_type === 'request_review' && elm) {
          const requiredHelpableId = this.getResponseHelpableId(elm);
          if (requiredHelpableId) {
            requests[requiredHelpableId].push(request);
          } else {
            requests[request.helpable_item_id] = [request];
          }
        } else {
          requests[request.helpable_item_id] = [request];
        }
      }
    });
    return requests;
  }

  /**
   * It returns the Instructor Response Helpable Id.
   * @param {HTMLElement} elm
   * @return {String} requiredHelpableId
   */
  getResponseHelpableId(elm) {
    // Tries to grab the container for a review request from a parent if it exists.
    this.activityRequests.map((request) => {
      if (elm.closest(`#${request.helpable_item_id}`) && request.helpable_item_id !== elm.id) {
        return request.helpable_item_id;
      }
    });

    // check the siblings of the element.
    const elmSiblings = elm.parentNode.childNodes;
    const returnedHelpableId = this.getSiblingFeedbackItem(elmSiblings, elm);

    // check the siblings of the parent.
    if (!returnedHelpableId) {
      const parentelmSiblings = elm.parentNode.parentNode.childNodes;
      return this.getSiblingFeedbackItem(parentelmSiblings, elm);
    }

    return returnedHelpableId;
  }

  /**
   * Get Feedback disclosure corresponding to a sibling if it already exists.
   * @param {Array} elmSiblings
   * @param {HTMLElement} elm
   * @return {String}
   */
  getSiblingFeedbackItem(elmSiblings, elm) {
    const siblingIds = [...elmSiblings].map((sibling) => sibling.id);
    this.activityRequests.map((request) => {
      if (siblingIds.includes(request.helpable_item_id) && request.helpable_item_id !== elm.id) {
        return request.helpable_item_id;
      }
    });
    return null;
  }

  /**
   * Method creates an HTML div Element for the helpable element, on which vue app will be mounted.
   * @param {string} helpableItemId
   * @param {string} requestUserId
   * @param {String} requestType
   * @param {String} helpableItemType
   * @return {HTMLElement}.
   */
  createRequestElement(helpableItemId, requestUserId, requestType, helpableItemType) {
    /*
    // This ported code which calls appendInQuestionLiTag method is commented
    // but kept for reference. Now helpableItemType has value instead of null.
    // Thus the code block is executing and many specs are breaking.
    const itemTypes = ['whole_question', 'answer_blank', 'question_prompt', 'student_response'];
    if (itemTypes.includes(helpableItemType)) {
      this.appendInQuestionLiTag(requestElm, activityRequestRootElm);
    } else
    */

    const requestElm = this.getHelpableElement(helpableItemId, requestUserId);
    const activityRequestRootElm = document.createElement('div');
    if (this.shouldAppendToDirectionLine(helpableItemType, requestType)) {
      this.appendToDirectionLineVTextRequests(activityRequestRootElm, helpableItemType);
    } else if (requestElm && requestElm.getAttribute('id') === 'partner_chat_whole_question') {
      this.insertAfterHelpableParent(requestElm, activityRequestRootElm);
    } else {
      this.insertAfterHelpableElement(requestElm, activityRequestRootElm);
    }
    return activityRequestRootElm;
  }

  /**
   * Method appendInQuestionLiTag searches for li tag in parents hierarchy
   * and appends vue app container in it
   * @param {HTMLElement} requestElm - Helpable element
   * @param {HTMLElement} activityRequestRootElm - Vue app container element
   */
  /*
  // Note: This method code is kept for reference but is commented as caller code is commented.
  appendInQuestionLiTag(requestElm, activityRequestRootElm) {
    if (!requestElm) return;
    let questionLiTag = this.getNodeInParents(requestElm, 'li');
    if (!questionLiTag) {
      questionLiTag = this.getNodeInParents(requestElm, '.student_answer_container');
    }
    questionLiTag?.appendChild(activityRequestRootElm);
  }
  */

  /**
   * Method getNodeInParents returns first parent of the given element with given selector
   * @param {HTMLElement} element - Element whose parent hierarchy is checked
   * @param {String} selector - Css selector to look for
   * @return {HTMLElement} - Parent element with given selector
   */
  /*
  // Note: This method code is kept for reference but is commented as caller code is commented.
  getNodeInParents(element, selector) {
    let result;
    let parentElement = element.parentElement;
    while (parentElement) {
      if (parentElement.matches(selector)) {
        result = parentElement;
        break;
      }
      parentElement = parentElement.parentElement;
    }
    return result;
  }
  */

  /**
   * This searches for 'direction line vtext requests' element and appends vue app container in it
   * @param {HTMLElement} activityRequestRootElm - Vue app container element
   * @param {String} helpableItemType
   */
  appendToDirectionLineVTextRequests(activityRequestRootElm, helpableItemType) {
    const selector = '[data-page-element="direction_line_vtext_requests"]';
    const containerElement = document.querySelector(selector);
    if (containerElement) {
      containerElement.appendChild(activityRequestRootElm);
      helpableItemType && activityRequestRootElm.classList.add(helpableItemType);
    }
  }

  /**
   * This inserts vue app container after helpable element's parent element
   * @param {HTMLElement} requestElm - Helpable element
   * @param {HTMLElement} activityRequestRootElm - Vue app container element
   */
  insertAfterHelpableParent(requestElm, activityRequestRootElm) {
    if (!requestElm) return;
    this.insertAfter(activityRequestRootElm, requestElm.parentElement);
  }

  /**
   * This inserts vue app container after helpable element
   * @param {HTMLElement} requestElm - Helpable element
   * @param {HTMLElement} activityRequestRootElm - Vue app container element
   */
  insertAfterHelpableElement(requestElm, activityRequestRootElm) {
    if (!requestElm) return;
    activityRequestRootElm.style.flexBasis = '100%';
    this.insertAfter(activityRequestRootElm, requestElm);
  }

  /**
   * This returns whether to append vue app at direction line
   * Note: Here extra check of containerElm required while porting the code from angular
   * because in earlier angular code it seems that helpableItemType was not saving
   * thus requests were not appending in containerElm
   * @param {String} helpableItemType
   * @param {String} requestType
   * @return {Boolean}
   */
  shouldAppendToDirectionLine(helpableItemType, requestType) {
    const selector = '[data-page-element="direction_line_vtext_requests"]';
    const containerElm = document.querySelector(selector);
    return (['vtext_reference', 'direction_line'].includes(helpableItemType) && containerElm) ||
      requestType == 'report_technical_problem';
  }

  /**
   * This method inserts a given element after a given element
   * @param {HTMLElement} elmToInsert
   * @param {HTMLElement} elmToInsertAfter
   */
  insertAfter(elmToInsert, elmToInsertAfter) {
    elmToInsertAfter.parentElement.insertBefore(
      elmToInsert,
      elmToInsertAfter.nextSibling
    );
  }

  /**
   * getHelpableElement.
   * Gets helpable element, corresponding the existing helo request is needed.
   * @param {string} helpableItemId
   * @param {string} requestUserId
   * @return {HTMLElement}
   */
  getHelpableElement(helpableItemId, requestUserId) {
    let helpableElement = document.querySelector(`#student_${requestUserId}_${helpableItemId}`);
    if (!helpableElement) {
      helpableElement = document.querySelector(`#${helpableItemId}`);
      if (!helpableElement) {
        helpableElement = document.querySelector('#activity_body');
      }
    }
    return helpableElement;
  }

  /**
   * onRequestChange.
   * Adding a event listener when new request is updated.
   */
  onRequestChange() {
    let activityRequests = this.activityRequests;
    let vueApps = this.apps;
    document.addEventListener('studentRequestAdded', (evt) => {
      const addRequestData = this.onRequestAdd(evt.detail, activityRequests, vueApps);
      activityRequests = addRequestData.activityRequests;
      vueApps = addRequestData.vueApps;
    });

    document.addEventListener('allRequestsRemoved', (evt) => {
      const removeRequestData = this.onRequestRemove(evt.detail, activityRequests, vueApps);
      activityRequests = removeRequestData.activityRequests;
      vueApps = removeRequestData.vueApps;
    });
  }

  /**
   * onRequestAdd.
   * Adding a event listener when new request is added on the page.
   * @param {Object} detail
   * @param {Object} activityRequests
   * @param {Object} vueApps
   * @return {Object}
   */
  onRequestAdd(detail, activityRequests, vueApps) {
    const rawRequest = detail.request;
    const requiredHelpableId = rawRequest.helpable_item_id;

    if (
      !Object.keys(activityRequests).includes(requiredHelpableId) &&
      ['request_help', 'request_review'].includes(rawRequest.request_type)
    ) {
      const requestContainer = this.createRequestElement(
        requiredHelpableId, rawRequest.user_id,
        rawRequest.request_type, rawRequest.helpable_item_type
      );
      const newRequest = this.getNewRequestData(rawRequest);
      vueApps[requiredHelpableId] = this.createRequestApp(
        requestContainer, [newRequest], requiredHelpableId
      );
      activityRequests[requiredHelpableId] = [newRequest];
    }
    return { activityRequests: activityRequests, vueApps: vueApps };
  }

  /**
   * onRequestRemove.
   * Adding a event listener when new request is removed on the page.
   * @param {Object} detail
   * @param {Object} activityRequests
   * @param {Object} vueApps
   * @return {Object}
   */
  onRequestRemove(detail, activityRequests, vueApps) {
    const helpableItemId = detail.helpableItemId;
    if (helpableItemId in activityRequests) {
      delete activityRequests[helpableItemId];
      vueApps[helpableItemId].unmount();
    }
    return { activityRequests: activityRequests, vueApps: vueApps };
  }

  /**
   * getNewRequestData.
   * Fetching subset of Object's(rawRequest) properties
   * @param {Object} rawRequest
   * @return {Object}
   */
  getNewRequestData(rawRequest) {
    return filterRequestProperties(rawRequest);
  }

  /**
   * getNewRequestData.
   * Fetching subset of Object's(rawRequest) properties
   * @param {HTMLElement} requestContainer
   * @param {Object} requests
   * @param {String} helpableId
   * @return {Object}
   */
  createRequestApp(requestContainer, requests, helpableId) {
    const app = createApp(HelpableItemRequestsList, {
      helpableItemId: helpableId,
    });
    app.provide('requests', reactive(requests));
    app.provide('metaData', this.metaData);
    app.mount(requestContainer);
    return app;
  }
}

export default ExistingRequestSetup;
