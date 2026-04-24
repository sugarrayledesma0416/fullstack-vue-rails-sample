var VHL = VHL || {};

/**
 * Data schema guidelines:
 * Choose a vhl_component string that uniquely identifies your feature in the global
     namespace.
 * Use a single set of keys per vhl_component. (This will also help with joining across
     events)
 * Initialize your logger with default values for those keys so they are included in every
     dispatch.
 * If you need to use a dramatically different set of keys for one event type, consider
     putting it on a different component. You can use more than one component per dashboard
     if needed.

 * Logstash example:

 * Run the following commands in a JS console on a page that has VHL.CarlinDispatch:

   var vhlComponent = 'my_component';
   var schemaDefaults = { foo: 'N/A', bar: 'none' };
   var logger = new VHL.CarlinDispatch.Logstash(vhlComponent, schemaDefaults);
   logger.dispatch('event_1', { foo: 'data', bar: 'baz' });
   logger.dispatch('event_1', { foo: 'info', bar: 'bat' });
   logger.dispatch('event_2', { foo: 'info'});
   logger.dispatch('event_2', { foo: 'data'});
   logger.dispatch('event_3');

 * To view a sample dashboard which will display the data you just created:
 * Go to Kibana 3
 * Search (using the "Load" folder menu) for CarlinDispatch

 * You can use this data as a template if you edit the index to use your new component:
   1. Copy and save the dashboard with a new name.
   2. On the gear in the upper right, select Configure Dashboard
   3. On the Index tab, change my_component in the index pattern to be your component name.
   */

VHL.CarlinDispatch = VHL.CarlinDispatch || {};

/**
 * @param {String} vhlComponent, A short name used to group together all of the
   events for your feature. This is used to "namespace" your events in Logstash
   and will also be used as an index for your dashboard. Must be lowercase. Use
   underscore_case.
 * @param {Object} [componentDataContinuation={}], Define your data schema here.
   Set defaults here for the keys you want to include in your eventData object
   when you dispatch. You can modify the values for these keys upon dispatch by
   including an eventData object or you can use callbacks here.
   */

VHL.CarlinDispatch.Logstash = (function() {
  var constructor = function(vhlComponent, componentDataContinuation) {
    this.vhlComponent = vhlComponent;
    this.timers = {};

    /*
     * If no continuation is given, provide a sensible
     * default.
     */
    this.componentDataContinuation = componentDataContinuation ?
      componentDataContinuation :
      function() { return {}; };

    var self = this;
    function setDefaultData() {
      // Get the connection type from the NetworkInformationAPI
      // only if its supported
      var connection_type = navigator.connection && navigator.connection.type;
      self.defaultData = {
        app_name: 'm3',
        application: 'm3',
        user_id: $('meta[name=\'VHL.user_id\']').attr('content'),
        user_guid: $('meta[name=\'VHL.user_guid\']').attr('content'),
        user_type: $('meta[name=\'VHL.user_type\']').attr('content'),
        environment: $('meta[name=\'VHL.environment\']').attr('content'),
        school_ids: $('meta[name=\'VHL.school_ids\']').attr('content'),
        school_guids: $('meta[name=\'VHL.school_guids\']').attr('content'),
        school_names: $('meta[name=\'VHL.schools\']').attr('content'),
        course_id: $('meta[name=\'VHL.course_id\']').attr('content'),
        course_guid: $('meta[name=\'VHL.course_guid\']').attr('content'),
        course_name: $('meta[name=\'VHL.course_name\']').attr('content'),
        section_id: $('meta[name=\'VHL.section_id\']').attr('content'),
        section_guid: $('meta[name=\'VHL.section_guid\']').attr('content'),
        section_name: $('meta[name=\'VHL.section_name\']').attr('content'),
        section_tz: $('meta[name=\'VHL.section_tz\']').attr('content'),
        program_id: $('meta[name=\'VHL.program_id\']').attr('content'),
        program_title: $('meta[name=\'VHL.program_title\']').attr('content'),
        program_language: $('meta[name=\'VHL.program_language\']').attr('content'),
        activity_id: $('meta[name=\'VHL.activity_id\']').attr('content'),
        activity_type: $('meta[name=\'VHL.activity_type\']').attr('content'),
        activity_title: $('meta[name=\'VHL.activity_title\']').attr('content'),
        activity_grading_method: $('meta[name=\'VHL.activity_grading_method\']').attr('content'),
        activity_component_name: $('meta[name=\'VHL.activity_component_name\']').attr('content'),
        activity_submittable: $('meta[name=\'VHL.activity_submittable\']').attr('content'),
        activity_points_possible: $('meta[name=\'VHL.activity_points_possible\']').attr('content'),
        activity_max_attempts: $('meta[name=\'VHL.activity_max_attempts\']').attr('content'),
        activity_instructor_id: $('meta[name=\'VHL.activity_instructor_id\']').attr('content'),
        activity_revision_id: $('meta[name=\'VHL.activity_revision_id\']').attr('content'),
        activity_revision_instructor_id: $('meta[name=\'VHL.activity_revision_instructor_id\']').attr('content'),
        controller_name: $('meta[name=\'VHL.Controller\']').attr('content'),
        concept_id: $('meta[name=\'VHL.concept_id\']').attr('content'),
        concept_name: $('meta[name=\'VHL.concept_name\']').attr('content'),
        concept_rank: $('meta[name=\'VHL.concept_rank\']').attr('content'),
        lesson_id: $('meta[name=\'VHL.lesson_id\']').attr('content'),
        lesson_name: $('meta[name=\'VHL.lesson_name\']').attr('content'),
        lesson_label: $('meta[name=\'VHL.lesson_label\']').attr('content'),
        navigator_user_agent: navigator.userAgent,
        navigator_platform: navigator.platform,
        navigator_vendor: navigator.vendor,
        navigator_appCodeName: navigator.appCodeName,
        navigator_appName: navigator.appName,
        navigator_language: navigator.language,
        navigator_connection_type: connection_type,
      };
    }
    // assign default m3 data
    setDefaultData();
  };

  /** Store a timer under the given name and start it.
   *
   * @param {String} timerName, The name of the timer.
   */
  constructor.prototype.startTimer = function(timerName) {
    this.timers[timerName] = new VHL.Stats.Timer();
    this.timers[timerName].start();
  };

  /** Stop a timer stored under the given name.
   *
   * @param {String} timerName, The name of the timer.
   */
  constructor.prototype.stopTimer = function(timerName) {
    this.timers[timerName].stop();
  };

  /** Assemble and return data from the timer stored under the given name.
   *
   * @param {String} timerName, The name of the timer.
   * @returns {Object} An object containing data from the timer.
   */
  constructor.prototype.getTimerData = function(timerName) {
    var timerData = {};
    var timer = this.timers[timerName];
    timerData[timerName + '_s_time'] = timer.s_time;
    timerData[timerName + '_e_time'] = timer.e_time;
    timerData[timerName + '_delta'] = timer.delta;
    return timerData;
  };

  /** Send event data to logstash.
   *
   * @param {String} eventType, The name of the event.
   * @param {Object} eventData, A key-value collection of event-specific data. Use
     this to over-ride default values set when instantiating your logger.
   */
  constructor.prototype.dispatch = function(eventType, eventData) {
    var self = this;

    function mergeEventData(type, data) {
      return _.extend({}, { vhl_component: self.vhlComponent },
                      self.componentDataContinuation,
                      self.defaultData,
                      { type: type },
                      data);
    }

    // send an object that merges vhl_component, event type, default data and metadata
    var mergedData = mergeEventData(eventType, eventData);
    var logstashObject = VHL.Stats.logstashObject(mergedData);
    VHL.Dispatcher && VHL.Dispatcher.send(logstashObject);
  };

  return constructor;
})();
