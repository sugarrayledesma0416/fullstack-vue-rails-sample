import ActivityNoteSetup from './activity_note_setup';
import FlashBannerSetup from 'features/flash_banner/flash_banner_setup';
import { metaTagContent } from 'shared/utils';
import Overlay from './overlay';
import './instructor_note_audio_config';

/**
 * Sets up activity notes, and if in an instructor view, sets up the
 * instructor note editing functionality as well.
 */
function doInstructorNoteSetup() {
  const allowsExpandedNotes = document.querySelector(
    '.js-allows-expanded-notes'
  ).getAttribute('data-allows-expanded-notes') === 'true';

  const railsData = JSON.parse(
    document.querySelector(
      '.js-instructor-notes-rails-data'
    ).getAttribute('data-from-dom')
  );
  const userType = metaTagContent('VHL.user_type');
  const controllerType = metaTagContent('VHL.Controller');
  const sectionId = metaTagContent('VHL.section_id');

  const activityNoteSetup = new ActivityNoteSetup(
    {
      allowsExpandedNotes,
      controllerType,
      railsData,
      userType,
    }
  );

  activityNoteSetup.attachNotes();

  if (userType !== 'Student' && sectionId === '0' && controllerType !== 'grading_styles') {
    /* Handling for Add Instructor Note */
    const addNoteApp = activityNoteSetup.initAddNoteApp();
    document.addEventListener(
      'i_was_chosen',
      (event) => {
        addNoteApp.showDialog(event.detail);
      }
    );
    document.addEventListener(
      'activityNoteAdded',
      (arg) => {
        const { note } = arg.detail;
        const app = activityNoteSetup.activityNoteApps[note.note_item_id];
        app.addNote(note);
      }
    );

    // Initialise Overlay for Instructor View.
    Overlay.attachEvtHandler();
  }

  FlashBannerSetup.init();
}

document.addEventListener(
  'DOMContentLoaded',
  () => {
    /**
     * To avoid a race condition when the page contains glossable content,
     * where the gloss processing alters the elements in the DOM and wipes
     * out their event bindings, if the page contains glossable content,
     * hold off on starting the setup process until an Event is
     * dispatched notifying that the gloss processing is complete.
     */
    const glossContainer = document.querySelector('.js-glossable-content');

    if (glossContainer) {
      document.addEventListener(
        'gloss_processing_complete',
        () => {
          setTimeout(doInstructorNoteSetup, 0);
        }
      );
    } else {
      setTimeout(doInstructorNoteSetup, 0);
    }
  }
);
