/**
 * Use the Rails asset pipeline for fetching HTML and JSON fixtures.
 */
(function() {
  function patch_fixture(name, constructor) {
    var prototype = jasmine[name].prototype;

    jasmine[name] = constructor;
    jasmine[name].prototype = prototype;
  }

  patch_fixture('Fixtures', function() {
    this.containerId = 'jasmine-fixtures';
    this.fixturesCache_ = {};
    this.fixturesPath = '/assets/fixtures';
  });

  patch_fixture('JSONFixtures', function() {
    this.fixturesCache_ = {};
    this.fixturesPath = '/assets/fixtures/json';
  });

  console.log('HTML/JSON fixture paths patched!');
})();
