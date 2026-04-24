import Handlebars from 'handlebars';

const courseTemplateDataTemplate = Handlebars.compile(`
<div class="l-container-fluid  u-txt-14  u-txt-gray-6  u-bord-bot-2  u-bord-gray-e  u-pad-top-16  u-pad-bot-16  u-bg-gray-f5
            {{#if template_deleted}}u-hidden{{/if}}">
  <div class="l-grid  u-pad-bot-10">
    <div class="l-col-5">
      COURSE DATE
    </div>
    <div class="l-col-7">
      {{ start_date }} - {{ end_date }}<br />
    </div>
  </div>
  <div class="l-grid">
    <div class="l-col-5">
      CATEGORY
    </div>
    <div class="l-col-7">
      {{#each categories}}
        {{weighting_percent}}% {{name}}<br />
      {{/each}}
    </div>
  </div>
</div>
`);

export default courseTemplateDataTemplate;
