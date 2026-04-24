import Handlebars from 'handlebars';
import 'shared/handlebars/test_class_helper.js';

const sectionDataTemplate = Handlebars.compile(`
<div class="u-hidden  js-selected-course-id" data-selected-course-id="{{ course_id }}"></div>
<div class="u-hidden  js-course-data"
     data-course-id="{{ course_id }}"
     data-course-name="{{ course_name }}"
     data-course-owner-id="{{ owner_id }}"
     data-section-count="{{ total_sections }}"
     data-source-template-id="{{ source_template_id }}"
     data-hide-from-dash-checkbox-status="{{ hide_from_inst_dash }}"
    >
</div>
<div class="u-mar-lt-32  u-mar-rt-32">
  <div class="u-mar-lt-64  u-txt-ctr  u-pad-top-24">
    <div class="l--inline-group">
      <span class="c-heading--page-title  u-txt-24  u-txt-gray-4  js-course-name  u-mar-rt-16">
        {{ course_name }}
      </span>
      {{#if course_closed }}
        <span class="c-heading--caps  u-bord-1  u-bord-rad-6  u-pad-3  u-vertical-super">
          <label> closed course</label>
        </span>
      {{/if}}
      {{#if created_from_template }}
        <span>
          <a class="js-edit-course" href="#">{{{ edit_icon_snippet }}}</a>
        </span>
      {{/if}}
    </div>
    <div class="u-txt-gray-6  u-txt-16  js-owner-name">
      {{ owner_name }}
    </div>
    <div class="l--inline-group  u-pad-rt-0">
      <div class="u-pad-top-16  u-txt-upper  u-txt-16">
        {{#if created_from_template }}
          {{#if can_create_section}}
            {{{ add_section_snippet }}}
          {{else}}
            <span title="There must be at least one section template ready to use." class="u-txt-gray-a">
              {{{add_section_snippet}}}
            </span>
          {{/if}}
        {{/if}}
      </div>
    </div>
  </div>
</div>
<div class="c-box--outlined  u-pad-24  u-mar-top-32  u-mar-lt-32  u-mar-rt-32  u-mar-bot-16  u-bord-1  u-bord-rad-6  u-bord-gray-d">
  {{#if no_sections}}
    <div class="js-no-sections">This course doesn't have any sections!</div>
  {{else}}
    <div class="js-sections">
      <table class="c-table">
        <thead>
          <tr class="c-header-row  c-section-data__header-row">
            <th scope="col"></th>
            <th scope="col"> Section  </th>
            <th scope="col"> Instructor </th>
            <th scope="col" class="u-txt-ctr"> Roster </th>
            <th scope="col" class="u-txt-wrap u-txt-ctr">
              Access Issues {{{ @root.alert_icon }}}
            </th>
            <th scope="col" class="u-txt-ctr"> Enrollment </th>
          </tr>
        </thead>
        <tbody class="js-section-table-data">
          {{#if @root.course_closed }}
            {{#each sections_closed}}
              <tr class="c-row  c-section-data__row">
                <td>
                  {{#if @root.created_from_template}}
                    <div class="test-edit-section-control  js-edit-section  js-edit-section-{{ id }}" data-section-id="{{ id }}">
                      <a href="">{{{ @root.edit_icon_snippet }}}</a>
                    </div>
                  {{/if}}
                </td>
                <td class="{{ test_class @root.env 'section-name' id }}"> {{ name }} </td>
                <td class="u-txt-nowrap">
                <div class= "l-grid">
                  <div class="l-col-4">
                    <span class="u-txt-ital  u-txt-gray-9  u-pad-rt-10"> Instructor </span>
                  </div>
                  <div class="l-col-8">
                    {{{ @root.owner_name_with_email }}}
                  </div>
                </div>
                {{#each additional_instructors}}
                  <div class= "l-grid">
                    <div class="l-col-4">
                      <span class="u-txt-ital  u-txt-gray-9  u-pad-rt-10"> {{ role }} </span>
                    </div>
                    <div class="l-col-8">
                      {{{ last_name_first_with_email }}}
                    </div>
                  </div>
                {{/each}}
                </td>
                <td class="js-roster-link u-txt-ctr"> {{{ enrollment_count_with_link }}} </td>
                <td class="u-txt-ctr"> {{ insufficient_access_count }} </td>
                <td class="u-txt-ctr"> {{{ enrollment_status_icon }}} </td>
              </tr>
           {{/each}}
         {{/if}}
          {{#each sections}}
            <tr class="c-row  c-section-data__row">
              <td>
                {{#if @root.created_from_template}}
                  <div class="test-edit-section-control  js-edit-section  js-edit-section-{{ id }}" data-section-id="{{ id }}">
                    <a href="">{{{ @root.edit_icon_snippet }}}</a>
                  </div>
                {{/if}}
              </td>
              <td class="{{ test_class @root.env 'section-name' id }}"> {{ name }} </td>
              <td class="u-txt-nowrap">
              <div class= "l-grid">
                <div class="l-col-4">
                  <span class="u-txt-ital  u-txt-gray-9  u-pad-rt-10"> Instructor </span>
                </div>
                <div class="l-col-8">
                  {{{ @root.owner_name_with_email }}}
                </div>
              </div>
              {{#each additional_instructors}}
                 <div class= "l-grid">
                   <div class="l-col-4">
                     <span class="u-txt-ital  u-txt-gray-9  u-pad-rt-10"> {{ role }} </span>
                   </div>
                   <div class="l-col-8">
                     {{{ last_name_first_with_email }}}
                   </div>
                 </div>
              {{/each}}
              </td>
              <td class="js-roster-link u-txt-ctr"> {{{ enrollment_count_with_link }}} </td>
              <td class="u-txt-ctr"> {{ insufficient_access_count }} </td>
              <td class="u-txt-ctr"> {{{ enrollment_status_icon }}} </td>
            </tr>
          {{/each}}
        </tbody>
      </table>
      <div class="u-pad-lt-16  u-txt-gray-9">
        <span class="js-total-enrolled">{{ total_enrolled }}</span> Total Enrolled,
        <span class="js-total-sections">{{ total_sections }}</span> Total Sections
      </div>
    </div>
  {{/if}}
</div>
`);

export default sectionDataTemplate;
