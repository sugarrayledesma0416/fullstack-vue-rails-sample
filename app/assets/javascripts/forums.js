/* global StreamRecorder */
//= require recorder/application
//= require ./forums_audio_controls


/**
 * Class to act as controller for Forums - Recording Audio, Adding Text and Playing back Audio capabilities
 */
VHL.Forums = class Forums {

  /**
   * Selectors of DOM elements which is displayed or hidden when any of the Reply / Edit button is clicked.
   */
  get DOM_SELECTOR() {
    return Object.freeze({
      EDIT: {
        DISPLAY: '.js-edit-form',
        HIDE: '.js-post-body'
      },
      REPLY: {
        DISPLAY: '.js-reply-form',
        HIDE: '.js-post-actions'
      },
      NEW: {
        DISPLAY: '.js-new-forum'
      }
    });
  }

  constructor() {
    this._attachEventListeners();

    // Inialize Audio controls in case Edit / Reply / New form is visible on Init
    this._initAudioControls(this.DOM_SELECTOR.REPLY.DISPLAY);
    this._initAudioControls(this.DOM_SELECTOR.EDIT.DISPLAY);
    this._initAudioControls(this.DOM_SELECTOR.NEW.DISPLAY);

    this.accentBarEnabled = document.querySelector('meta[name="VHL.program_accent_bar_enabled"]')?.content === 'true' || false;
    if (this.accentBarEnabled) {
      // Initialize Accent Bar Component for inputs and text areas.
      this.accentBarComponent = new VHL.AccentBarComponent();
      let textBoxes = document.querySelectorAll('input[type="text"], textarea');
      textBoxes.forEach(textBox => {
        this.accentBarComponent.register(textBox);
      });
    }
  }


  /**
   * @summary Attach event handlers to edit, reply buttons. Initialize play comment media button
   */
  _attachEventListeners() {
    // Event Handlers for Reply Modal - Reply and Cancel Buttons
    $('.js-start-reply').on('click', (event) => this._replyHandler(event, this.DOM_SELECTOR.REPLY));
    $('.js-cancel-reply').on('click', (event) => this._cancelHandler(event, 'REPLY'));

    // Event Handlers for Edit Form - Reply and Cancel Buttons
    $('.js-start-edit').on('click', (event) => this._replyHandler(event, this.DOM_SELECTOR.EDIT));
    $('.js-cancel-edit').on('click', (event) => this._cancelHandler(event, 'EDIT'));

    // Post Show View - Listen (Play) Audio Button - Event Handlers
    document.querySelectorAll('.js-play-audio-comment').forEach((audioComment) => {
      // Get the Span element containing audio data
      let $clickedCommentButton = $(audioComment);
      let url = $clickedCommentButton.siblings('.js-audio-comment-url').data('audio-url');

      // Create new media button
      this.audioCommentPlayButton = new VHL.Music.V1.MediaButton({
        $button: $(audioComment),
        activate: function () {
          // Create Audio Object
          let audio;
          if ($clickedCommentButton.data("audio")) {
            // Extract Audio Object in case it already exists
            audio = $clickedCommentButton.data("audio");
          } else {
            // Create a new Audio object and save
            audio = new Audio(url);
            $clickedCommentButton.data({ audio: audio });
          }
          audio.onended = () => {
            this.reset();
            $clickedCommentButton.data({ audio: false });
          };

          // Play Audio
          audio.play();
        },
        deactivate: function () {
          let audio = $clickedCommentButton.data("audio");
          audio.load();
        }
      });
    });

    this._attachDeletionDialogues();

    $('.js-disclosure').each((idx, disclosure) => {
      new VHL.Music.V1.Disclosure($(disclosure));
    });

    $('.js-disclosure-controller').on('click', (event) => {
      this._disclosureControllerClickHandler(event);
    });

    // When page loaded, open the first level of replies only:
    $('.js-disclosure-controller:first').click();
  }

  /**
   * @summary Create options for Deletion Dialog displayed on Post and Forum Deletion
   */
  _attachDeletionDialogues() {
    let deletionDialogOpts = {
      bindTo: '.js-delete-forum-or-post',
      post: {
        title: 'Delete Post?',
        content: 'Are you sure you want to delete this post? ' +
          'Its contents will be deleted, but its replies ' +
          'will not be affected.'
      },
      forum: {
        title: 'Delete Forum',
        content: 'Are you sure you want to delete this forum? ' +
          'All posts on this forum will be deleted, and cannot ' +
          'be recovered.'
      }
    };
    new VHL.jQueryCommon.DeletionDialog(deletionDialogOpts);
  }


  /**
   * Handler when "Reply" / "Edit" button is clicked in the Post HTML
   * @param {*} event - Browser Click evbent
   * @param {*} uiMode - Object of DOM_SELECTOR.EDIT / DOM_SELECTOR.REPLY
   */
  _replyHandler(event, uiMode) {
    const selectedPostId = $(event.currentTarget).data('post-id');

    // Close all open forms
    this._closeAllForms();

    // Display Reply Form
    const $formElement = $(`${uiMode.DISPLAY}-${selectedPostId}`);
    $formElement.removeClass("u-hidden");
    
    // Focus the first focusable element
    const $first = this._getFirstFocusable($formElement);
    if ($first.length) $first.focus();

    // Hide Action Bar of the Post when reply modal is open
    const $actionBarElement = $(`${uiMode.HIDE}-${selectedPostId}`)
    $actionBarElement.addClass("u-hidden");

    // Initialize all Audio Controls and make Submit button active
    this.audioControl = new AudioControls($formElement);
    const textArea = $formElement.find('.js-forum-post-textarea');
    this.textArea = textArea.length ? textArea[0] : null;
    const formElm = $formElement.length ? $formElement[0] : null;
    this.attachChangeHandlers(formElm);
    $formElement.on("submit", (event) => this._formAudioSubmitHandler(event));
  }

  /**
   * Handle click event for disclosure controller
   * @param {*} event - Browser Click event
   */
  _disclosureControllerClickHandler(event) {
    const $replyDisclosureHeader = $(event.currentTarget);

    // generating conditional display text for reply disclosure controller
    const state = ($replyDisclosureHeader.attr('aria-expanded') == "false");
    const replyCount = $replyDisclosureHeader.data('reply-count');
    const displayText = state ? `View  (${ replyCount })`
                              : `Hide  (${ replyCount })`;

    // Setting up the generated text in the reply disclosure controller view
    $replyDisclosureHeader.find('.js-disclosure-controller__text').text(displayText);
  }

  /**
   * Handler when Cancel button clicked in "Reply" / "Edit" UI
   * @param {Event} event - Browser Click event
   * @param {string} uiMode - 'REPLY' or 'EDIT' to determine which form is being cancelled
   */
  _cancelHandler(event, uiMode) {
    // Close Accent Bar
    if (this.accentBarEnabled) {
      this.accentBarComponent.deactivateAll();
    }

    if (['REPLY', 'EDIT'].includes(uiMode)) {
      const formElm = event.currentTarget.closest('form');
      this.clearValidationError(formElm);
      this.detachChangeHandlers(formElm);
    }

    // Close all open forms
    this._closeAllForms();

    const selectedPostId = event.currentTarget.dataset.postId;
    const focusSelector =
      uiMode === 'REPLY'
        ? '.js-start-reply'
        : uiMode === 'EDIT'
        ? '.js-start-edit'
        : null;

    if (focusSelector) {
      document.querySelector(`${focusSelector}[data-post-id="${selectedPostId}"]`)?.focus();
    }
  }

  /**
   * Inialize Audio controls in case Edit / Reply form is visible on Init
   * In case on page load the form is already open (for example, From Submission Error) - Initialize the audio controls
   * @param {*} modeSelector - String representing one of of DOM_SELECTOR.EDIT.SHOW Or DOM_SELECTOR.REPLY.SHOW
   */
  _initAudioControls(modeSelector) {
    // Get the visible Form
    const $defaultActiveReply = $(`${modeSelector}:not(.u-hidden)`);

    if ($defaultActiveReply.length > 0) {
      // Initialize Audio Controls and bind Submit
      this.audioControl = new AudioControls($defaultActiveReply);
      this.attachChangeHandlers($defaultActiveReply[0]);
      $defaultActiveReply.on("submit", (event) => this._formAudioSubmitHandler(event));
    }
  }


  /*
   Form submit handler and helpers
  */

  /**
  * Handle submit event for currently open form when audio is recorded.
  * Show validation errors and avoid disabling submit button if detected any error on the form.
  * If no errors, then first upload the audio and then programmatically submit the form.
  * @param {Jquery Object} event | submit event jquery object
  */
  _formAudioSubmitHandler(event) {
    let blob = this.audioControl.blob;
    const bError = this.preventSubmissionAndShowError(event, blob);
    if (bError) return;

    if(!blob) return;

    // Don't submit until we explicitly say to
    event.preventDefault();

    // Ensure that we do not loop back into this callback
    // when we explicitly submit the form.
    $(event.currentTarget).off('submit');

    // Generate filename, upload audio file, then submit
    this._generateFileHashedName(blob).then((hashedName) => {
      return this._uploadFile(hashedName, blob, event);
    }).then(() => {
      $(event.currentTarget).submit();
    }).catch((error) => {
      console.log("The audio did not upload.", error);
    });
  }

  /**
  * Validate that any one of the audio or text should be present.
  * Prevent submission and return true if validation error is found.
  * Implement this logic only for reply post or edit post dialog for now.
  * The forum+firstPost flow can be included after discussions.
  * @param {Event} event Submit event
  * @param {Blob} blob Recorded audio related data
  * @return {boolean} True if error is found.
  */
  preventSubmissionAndShowError(event, blob) {
    const formElm = event.currentTarget;
    const formCls = formElm.classList;
    const isReplyOrEditDlg = formCls.contains('js-edit-form') || formCls.contains('js-reply-form');

    if (!isReplyOrEditDlg) return false;

    const hasText = (this.textArea.value || '').trim().length > 0;
    if (!hasText && !blob) {
      event.preventDefault();
      this.showValidationError(formElm);
      this.enableSubmitButton(event);
      return true;
    } else {
      this.clearValidationError(formElm);
      this.detachChangeHandlers(formElm);
    }

    return false;
  }

  /**
  * Add event handlers to clear validation error when text or audio is added.
  * @param {HTMLFormElement} formElm Form element
  */
  attachChangeHandlers(formElm) {
    if (!formElm) return;

    const textarea = formElm.querySelector('.js-forum-post-textarea');
    if (!textarea) return;

    textarea.removeEventListener('input', this.textChangeHandler);
    textarea.addEventListener('input', this.textChangeHandler);
    $(textarea).off('accented_character_added', this.textChangeHandler);
    $(textarea).on('accented_character_added', this.textChangeHandler);
    formElm.removeEventListener('audio:changed', this.audioChangeHandler);
    formElm.addEventListener('audio:changed', this.audioChangeHandler);
  }

  /**
  * Remove event handlers to clear validation error.
  * @param {HTMLFormElement} formElm Form element
  */
  detachChangeHandlers(formElm) {
    if (!formElm) return;

    formElm.removeEventListener('audio:changed', this.audioChangeHandler);
    const textarea = formElm.querySelector('.js-forum-post-textarea');
    if (textarea) {
      textarea.removeEventListener('input', this.textChangeHandler);
      $(textarea).off('accented_character_added', this.textChangeHandler);
    }
  }

  /**
  * Handler to clear validation error when audio is changed.
  * @param {Event} evt 'audio:changed' event from form element
  */
  audioChangeHandler = (evt) => {
    const currentTarget = evt.currentTarget;
    let formElm = null;
    if (currentTarget.tagName === 'FORM') {
      formElm = currentTarget;
    }
    this.clearErrorOnAudioOrTextChange(evt, formElm);
  }

  /**
  * Handler to clear validation error when textarea text is changed.
  * @param {Event} evt textarea input change event
  */
  textChangeHandler = (evt) => {
    const currentTarget = evt.currentTarget;
    let formElm = currentTarget.form || currentTarget.closest('form');
    this.clearErrorOnAudioOrTextChange(evt, formElm)
  }

  /**
  * Clear validation error when text or audio is added.
  * This handles text change in text area or audio changed trigger by form element.
  * @param {Event} evt textarea input change event or 'audio:changed' event
  * @param {HTMLFormElement} formElm Form element
  */
  clearErrorOnAudioOrTextChange(evt, formElm) {
    if (!formElm || !this.isValidationErrorState(formElm)) return;

    const hasAudio = (evt.type === 'audio:changed') ? !!evt.detail?.hasAudio : null;
    const textarea = formElm.querySelector('.js-forum-post-textarea');
    const hasText = (textarea?.value || '').trim().length > 0;
    if (hasText || hasAudio) {
      this.clearValidationError(formElm);
      this.detachChangeHandlers(formElm);
    }
  }

  /**
  * Return whether form has validation error related to empty text / audio.
  * @param {boolean}
  */
  isValidationErrorState(formElm) {
    const emptyErrorElm = formElm?.querySelector('.js-empty-input-error');
    return (emptyErrorElm?.textContent || '').trim().length;
  }

  /**
  * Suppress the functionality of disabling the submit button on click once.
  * But restore that for next click.
  * @param {EVent} event Submit event
  */
  enableSubmitButton(event) {
    const submitBtn = event.originalEvent?.submitter;
    if (!submitBtn) return;

    this.removeAttributeDisableWith(submitBtn);
    setTimeout(() => {
      this.restoreAttributeDisableWith(submitBtn);
    }, 300);
  }

  /**
  * Suppress the functionality of disabling the submit button on click,
  * which works due to 'data-disable-with' attr.
  * @param {HTMLElement} submitBtn Submit button
  */
  removeAttributeDisableWith(submitBtn) {
    submitBtn.disabled = false;
    submitBtn.removeAttribute('data-disable-with');
  }

  /**
  * Restore the functionality of disabling the submit button on click,
  * which works due to 'data-disable-with' attr.
  * @param {HTMLElement} submitBtn Submit button
  */
  restoreAttributeDisableWith(submitBtn) {
    if (submitBtn && !submitBtn.hasAttribute('data-disable-with')) {
      submitBtn.setAttribute(
        'data-disable-with',
        submitBtn.value || submitBtn.textContent
      );
    }
  }

  /**
  * Show validation error related to empty text / audio.
  * @param {HTMLFormElement} formElm Form element
  */
  showValidationError(formElm) {
    const emptyErrorElm = formElm?.querySelector('.js-empty-input-error');
    if (emptyErrorElm) {
      emptyErrorElm.textContent = 'Please enter a reply or record audio before submitting.';
    }
  }

  /**
  * Clear validation error related to empty text / audio.
  * @param {HTMLFormElement} formElm Form element
  */
  clearValidationError(formElm) {
    const emptyErrorElm = formElm?.querySelector('.js-empty-input-error');
    if (emptyErrorElm) {
      emptyErrorElm.textContent = '';
    }
  }

  /**
   * @summary Generates hashed name for recorded audio file
   * @param {*} blob | recorded audio related data
   */
  _generateFileHashedName(blob) {
    let fileReader = new FileReader();
    //TODO make this perform better.
    return new Promise(function (resolve) {
      fileReader.readAsText(blob);
      fileReader.onloadend = function () {
        resolve(sha256(fileReader.result) + ".wav");
      };
    });
  }

  /**
   * @summary Generates meta data for uploaded post
   */
  _generateMetadata() {
    return JSON.stringify({
      'section_guid': $('meta[name=\'VHL.section_guid\']').attr('content'),
      'course_guid': $('meta[name=\'VHL.course_guid\']').attr('content'),
      'user_id': $('meta[name=\'VHL.user_id\']').attr('content'),
      'school_id': $('meta[name=\'VHL.current_school\']').attr('content'),
    });
  }

  /**
   * @summary Uploads file to server
   * @param {*} hashedName | Hash name of file to be uploaded
   * @param {*} blob | Recorded audio data
   * @param {*} event | Submit event jquery object
   * @return Promise object
   */
  _uploadFile(hashedName, blob, event) {
    let uploader = new streamAudioUploader({
      url: VHL.ForumsConfig.audioEndpoint,
      successCallback: function () {
        // Add filename to comment form.
        $(event.currentTarget).find('[data-audio-path]').val(hashedName);
      }
    });

    // Uploader.upload expects a FormData object for an xhr request.
    let formData = new FormData();
    formData.append('post_recording', blob);
    formData.append('filename', VHL.ForumsConfig.baseDir + hashedName);
    formData.append('metadata', this._generateMetadata());
    return uploader.upload(formData); /* this returns a promise */
  }

  /**
   * @summary Closes all edit and post forms.
   */
  _closeAllForms() {
    $('.js-post-body, .js-post-actions').removeClass('u-hidden');
    $('.js-reply-form, .js-edit-form').addClass('u-hidden');
  }

  _getFirstFocusable($container) {
    const FOCUSABLE_SELECTOR = `
      a[href], area[href],
      input:not([disabled]):not([type="hidden"]),
      select:not([disabled]), textarea:not([disabled]),
      button:not([disabled]), iframe, object, embed,
      [tabindex]:not([tabindex="-1"]), [contenteditable]
    `;
    return $container.find(FOCUSABLE_SELECTOR).filter(':visible').first();
  }
}

$(document).ready(function () {
  new VHL.Forums();
})
