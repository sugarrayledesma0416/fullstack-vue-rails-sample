/**
 * Overwrite or add properties on the global VHL object
 * with exports from Webpack.
 */
document.addEventListener('DOMContentLoaded', function() {
  VHL.Assessments = VHL.Assessments || {};
  VHL.Assessments.showSaveWorkWarning = window.Packs['layouts/common_header'].showSaveWorkWarning;
});
