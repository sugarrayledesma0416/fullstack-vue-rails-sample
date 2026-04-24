//= require carlin_dispatch

describe('VHL.CarlinDispatch', function() {
  describe('Logstash', function() {
    var logstash;
    var logstashWithoutData;
    var defaultDataInFixture;

    beforeEach(function() {
      defaultDataInFixture = { user_id: 'u1',
                               user_type: 'ut1',
                               school_ids: 'sch01',
                               course_id: 'c1',
                               section_id: 's1',
                               program_id: 'prog1',
                               activity_id: 'a1' };
      loadFixtures('carlin_dispatch.html');
      var componentDataContinuation = function() {
        return {'component_data_key': 'component_data_value'};
      };
      logstash = new VHL.CarlinDispatch.Logstash('component_name',
                                                 componentDataContinuation);
      logstashWithoutData = new VHL.CarlinDispatch.Logstash('component_name');
    });

    describe('constructor', function() {
      it('assigns the expected default data', function() {
        expect(logstash.defaultData).toEqual(defaultDataInFixture);
      });

      it('assigns the component-name param to a property', function() {
        expect(logstash.vhlComponent)
        .toEqual('component_name');
      });

      xit('assigns component-data param to a property', function() {
        expect(logstash.componentData)
        .toEqual({'component_data_key': 'component_data_value'});
      });
    });

    describe('timer functions', function() {
      beforeEach(function() {
        spyOn(VHL.Stats, 'Timer').andCallFake((function() {
          var constructor = function() {
            this.start = jasmine.createSpy('start');
            this.stop = jasmine.createSpy('stop');
          };

          return constructor;
        })());
        logstash.startTimer('foo');
      });
      describe('#startTimer', function() {
        it('creates a timer', function() {
          expect(VHL.Stats.Timer).toHaveBeenCalled();
        });

        it('stores the timer in a hash under the given name', function() {
          expect(logstash.timers['foo']).not.toBeUndefined();
        });

        it('starts the timer', function() {
          expect(logstash.timers['foo'].start).toHaveBeenCalled();
        });
      });

      describe('#stopTimer', function() {
        it('stops the timer stored under the given name', function() {
          logstash.stopTimer('foo');
          expect(logstash.timers['foo'].stop).toHaveBeenCalled();
        });
      });

      describe('#getTimerData', function() {
        it('returns an object with the expected keys and values', function() {
          logstash.timers['bar'] = {
            s_time: 1,
            e_time: 2,
            delta: 1
          };
          expect(logstash.getTimerData('bar')).toEqual({
            bar_s_time: 1,
            bar_e_time: 2,
            bar_delta: 1
          });
        });
      });
    });

    describe('#dispatch', function() {
      beforeEach(function() {
        VHL.Dispatcher = jasmine.createSpyObj('dispatcher', ['send']);
        spyOn(VHL.Stats, 'logstashObject').andCallFake(function(obj) {
          return { logstashObject: obj };
        });
      });

      it('calls VHL.Dispatcher.send with the expected composite hash', function() {
        logstash.dispatch('my_event',
                          {'event_data_key': 'event_data_value'});
        expect(VHL.Dispatcher.send).toHaveBeenCalledWith({
          logstashObject: _.extend(defaultDataInFixture, {
            vhl_component: 'component_name',
            'component_data_key': 'component_data_value',
            event_type: 'my_event',
            'event_data_key': 'event_data_value'
          })
        });
      });

      it('can handle missing component data', function() {
        logstashWithoutData.dispatch('my_event',
                                     {'event_data_key': 'event_data_value'});
        expect(VHL.Dispatcher.send).toHaveBeenCalledWith({
          logstashObject: _.extend(defaultDataInFixture, {
            vhl_component: 'component_name',
            event_type: 'my_event',
            'event_data_key': 'event_data_value'
          })
        });
      });

      it('can handle missing event data', function() {
        logstash.dispatch('my_event');
        expect(VHL.Dispatcher.send).toHaveBeenCalledWith({
          logstashObject: _.extend(defaultDataInFixture, {
            vhl_component: 'component_name',
            'component_data_key': 'component_data_value',
            event_type: 'my_event'
          })
        });
      });
    });
  });
});
