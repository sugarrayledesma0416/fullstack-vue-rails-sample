import FormComponent from 'institution_admin/shared/form_component.js';
import ExternalItem from './external_item.js';
import { sectionId } from 'shared/utils.js';
import { deleteFromEndpoint, postToEndpoint, putToEndpoint } from 'shared/ajax_utils.js';
import { observeAttrChange, optionIndexLookup, setDatepickerDate } from './utils.js';

// Define class name outside of closure so we can export it
let ExternalItemModal;

// Create a closure to allow private functionality.
{
  // TODO: Add JSDoc comments.
  ExternalItemModal = class extends FormComponent {
    /**
     * @constructor
     */
    constructor(rootElm, context) {
      let dueDateElm = rootElm.querySelector('.js-due-date');

      let model = new ExternalItem(
        context.externalActivityId,
        sectionId(),
        dueDateElm.dataset.min,
        dueDateElm.dataset.max,
        context.initialFormValues
      );

      let config = {
        elmEventListenerMap: {
          'js-submit': ['click', 'submitForm'],
          'js-delete': ['click', 'delete'],
          'js-form-fields': ['change', 'validate'],
          'js-modal-close': ['click', 'resetForm']
        },
        context: {
          deletionEndpoint: `${location.pathname}/${context.externalActivityId}`,
          endpoint: `${location.pathname}.json`,
          externalActivityId: context.externalActivityId,
          initialFormValues: context.initialFormValues,
          mode: context.mode,
          model: model
        }
      };

      super(rootElm, config);
    }

    async init() {
      await super.init();

      this.startDate = this.getElm('js-due-date').dataset.min;
      this.endDate = this.getElm('js-due-date').dataset.max;
      observeAttrChange(this.getElm('js-due-date-hidden'),
                        'value',
                        this.getElm('js-form-fields'));
    }

    open() {
      this.resetForm();

      $(this.rootElm).vhlModal('open');
    }

    data() {
      return {
        categoryId: this.getElm('js-category-id').selectedOptions[0].value,
        dueDate: this.getElm('js-due-date-hidden').value,
        lessonId: this.getElm('js-lesson-id').selectedOptions[0].value,
        pointsPossible: this.getElm('js-points-possible').value,
        title: this.getElm('js-title').value.trim()
      };
    }

    validate(event) {
      event.stopPropagation();

      const submitButton = this.getElm(`js-submit--${this.initialContext.mode}`);

      if (this.model.update(this.data())) {
        submitButton.removeAttribute('disabled');
      } else {
        submitButton.setAttribute('disabled', '');
      }
    }

    submitForm() {
      if (this.submitted) { return; }

      let ajaxMethod = this.initialContext.mode === 'add' ? postToEndpoint : putToEndpoint;

      ajaxMethod(
        this.initialContext.endpoint,
        this.model.data(),
        (data) => {
          location.reload(true);
        }
      );

      this.submitted = true;
    }

    delete() {
      if (this.submitted) { return; }

      deleteFromEndpoint(
        this.initialContext.deletionEndpoint,
        (data) => {
          location.reload(true);
        }
      );

      this.submitted = true;
    }

    resetForm() {
      if (this.initialContext.initialFormValues === undefined) {
        ['js-title', 'js-points-possible'].forEach(jsClass => {
          this.getElm(jsClass).value = '';
        });
        ['js-lesson-id', 'js-category-id'].forEach(jsClass => {
          this.getElm(jsClass).selectedIndex = 0;
        });
        setDatepickerDate('.js-due-date');
      } else {
        const lessonOptionIndexLookup = optionIndexLookup(this.getElm('js-lesson-id'));
        const categoryOptionIndexLookup = optionIndexLookup(this.getElm('js-category-id'));
        const formValues = this.initialContext.initialFormValues;
        this.getElm('js-title').value = formValues.title;
        // Add quotes around date to get date in local timezone.
        setDatepickerDate('.js-due-date', `"${formValues.dueDate}"`);
        this.getElm('js-due-date-hidden').value = formValues.dueDate;
        this.getElm('js-points-possible').value = formValues.pointsPossible;
        this.getElm('js-lesson-id').selectedIndex = lessonOptionIndexLookup[formValues.lessonId];
        this.getElm('js-category-id').selectedIndex = categoryOptionIndexLookup[formValues.categoryId];
      }

      const mode = this.initialContext.mode;
      this.setDisplayed('js-delete', mode === 'edit');
      this.setDisplayed('js-submit--edit', mode === 'edit');
      this.setDisplayed('js-submit--add', mode === 'add');
      this.getElm('js-modal-heading').innerHTML = `${mode.slice(0, 1).toUpperCase()}${mode.slice(1)} External Item`;
    };
  };
}

export default ExternalItemModal;
