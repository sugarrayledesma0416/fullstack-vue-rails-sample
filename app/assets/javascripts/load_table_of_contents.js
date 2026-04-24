$(document).ready(function() {
  VHL.TableOfContents.init();
  VHL.Common.prep_common_jquery_modal({show_spinner: true});

  VHL.Checkboxes.vhl_group_checkboxes({page: "toc"});
});
