import Handlebars from 'handlebars';
import '../shared/options_for_select_helper.js'

const instructorSubformTemplate = Handlebars.compile(`

<div class="js-instructor-subform">
  <div class="c-form-item-group">
    <div class="c-form-item  u-width-40">
      <label class="c-form-item__label">Additional instructors</label>
      <select class="c-dropdown--button  c-select  u-width-full  fc-instructor-select"
                id="instructor_select_{{componentId}}"
                data-instructor-subform-index="{{instructorSubformIndex}}">
                {{options_for_select instructorOptions model.selectedInstructorID}}
      </select>
    </div>
    <div class="c-form-item u-width-28">
      <label class="c-form-item__label">Role</label>
      <select {{#if disableRelatedInputs}}disabled{{/if}}
              class="c-dropdown--button  c-select  u-width-full  js-role-select"
              id="role_select_{{componentId}}">
              {{options_for_select roleOptions model.selectedRole}}
      </select>
    </div><!-- end form-item -->
    <div class="c-form-item" >
      <input  {{#if disableRelatedInputs}}disabled{{/if}}
               class="c-form-item__checkbox  js-show-instructor"
               {{#if model.showInstructor}}checked="true"{{/if}}
                                           type="checkbox"
                                           id="cbox_{{componentId}}">
      </input>
      <label class="c-form-item__label" for="cbox_{{componentId}}"> Show instructor </label>
    </div><!-- end form-item -->
  </div><!-- end form group -->
</div>
`);

export default instructorSubformTemplate;
