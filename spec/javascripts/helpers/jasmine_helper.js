// Returns true when a spy is called on a selector
// Ex. $('#heyhey').show();
// spyOn($.fn, 'show');
// expect(called_on_selector($.fn.show, '#heyhey')).toEqual(true);
function called_on_selector(spy, elm) {
  return _.some(spy.calls, function(obj) {
    return obj.object.selector == elm;
  });
}