import Handlebars from 'handlebars';

const sectionSubformCollectionTemplate = Handlebars.compile(`
{{#each sections}}
<div class="js-form-component--section-subform"
     data-path="institution_admin/dashboard/create_section"
     data-section-subform-index="{{@index}}">
</div>
{{/each}}
`);

export default sectionSubformCollectionTemplate;
