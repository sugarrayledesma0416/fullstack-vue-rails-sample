import Handlebars from 'handlebars';
import '../shared/options_for_select_helper.js';

const sectionSubformTemplate = Handlebars.compile(`
<div class="c-form-item-group">
  <div class="c-form-item u-width-full">
    <label class="c-form-item__label" for="section_name">section name</label>
    <input class="c-form-item__input u-width-70 js-section-name"
           type="text"
           id="section_name"
           value="{{model.sectionName}}"
           maxlength="16" />
  </div> <!-- end form-item-->
</div><!-- end form-group -->

<div class="c-form-item-group">
  <div class="c-form-item u-width-full">
    <label class="c-form-item__label" for="section_template">section template</label>
    <select name="section_template[]"
            id="section_template_{{sectionSubformIndex}}"
            class="c-dropdown--button  c-select u-width-70  js-section-template">
      {{options_for_select model.sectionOptions.section_template_options model.selectedTemplate}}
    </select>
  </div><!-- end form-item-->
</div><!-- end form-group -->

<div class="c-form-item-group">
  <div class="c-form-item u-width-full">
    <label class="c-form-item__label" for="instructor">Instructor</label>
    <input class="c-form-item__input  u-width-70  u-mar-rt-12"
          type="text"
          id="instructor"
          value="{{model.instructor}}"
          disabled />
    <input class="c-form-item__checkbox u-width-24 js-show-owner"
         {{#if model.showOwner}}checked="true"{{/if}}
         type="checkbox"
         id="cbox_show_owner_{{sectionSubformIndex}}" />
    <label class="c-form-item__label" for="cbox_show_owner_{{sectionSubformIndex}}">
         Show instructor
    </label>
  </div> <!--end form-item-->
</div><!--end form-item-group -->

<div class="js-form-component--instructor-subform-collection"
     data-path="institution_admin/dashboard/create_section">
</div>

<div class="u-bord-bot-2  u-bord-gray-e  u-mar-bot-16  u-pad-bot-10"></div>
`);

export default sectionSubformTemplate;
