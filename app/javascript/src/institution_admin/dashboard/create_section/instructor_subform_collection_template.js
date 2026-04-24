import Handlebars from 'handlebars';

const instructorSubformCollectionTemplate = Handlebars.compile(`
<div class="fc-instructor-subform-container">
  {{#each model.additionalInstructors}}
    <div class="js-form-component--instructor-subform"
         data-instructor-subform-index="{{@index}}"
         data-path="institution_admin/dashboard/create_section">
    </div>
  {{/each}}
  <button type="button"
        class="c-no-button  u-txt-upper  fc-add-more"
        {{#if disableAddMore}}disabled="true"{{/if}}>Add more</button>
  </div>
`);

export default instructorSubformCollectionTemplate;
