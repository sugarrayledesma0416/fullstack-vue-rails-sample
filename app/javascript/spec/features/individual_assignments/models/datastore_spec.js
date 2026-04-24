import Datastore from 'features/individual_assignments/models/datastore';

describe(
  'Datastore',
  () => {
    let user1Entry1;
    let user1Entry2;
    let user2Entry1;
    let user2Entry2;

    it(
      'assigns its entries property to a reactive version of the ' +
      'specified entries',
      () => {
        expect(new Datastore({}).entries).toBeReactiveVersionOf({});
      }
    );

    describe(
      'when the onlyIndividual argument is set to "true"',
      () => {
        it(
          'assigns a state property to a reactive object with a ' +
          'showOnlyIndividuallyAssignable property set to true and ' +
          'an activityIdBeingEdited property set to null',
          () => {
            expect(new Datastore({}, 'true').state).toBeReactiveVersionOf(
              {
                activityIdBeingEdited: null,
                showOnlyIndividuallyAssignable: true,
              }
            );
          }
        );
      }
    );

    describe(
      'when the onlyIndividual argument is set to "false"',
      () => {
        it(
          'assigns a state property to a reactive object with a ' +
          'showOnlyIndividuallyAssignable property set to false and ' +
          'an activityIdBeingEdited property set to null',
          () => {
            expect(new Datastore({}, 'false').state).toBeReactiveVersionOf(
              {
                activityIdBeingEdited: null,
                showOnlyIndividuallyAssignable: false,
              }
            );
          }
        );
      }
    );

    describe(
      'activityEntries',
      () => {
        user1Entry1 = {
          assignable_id: 111,
          individually_assignable: true,
          user_id: 123,
        };
        user1Entry2 = {
          assignable_id: 222,
          individually_assignable: false,
          user_id: 123,
        };
        user2Entry1 = {
          assignable_id: 111,
          individually_assignable: true,
          user_id: 456,
        };
        user2Entry2 = {
          assignable_id: 222,
          individually_assignable: false,
          user_id: 456,
        };

        const entries = {
          123: [user1Entry1, user1Entry2],
          456: [user2Entry1, user2Entry2],
        };

        it(
          'returns only individually-assigned entries for the first user ' +
          'when the showOnlyIndividuallyAssignable flag is true',
          () => {
            const store = new Datastore(entries);
            store.state.showOnlyIndividuallyAssignable = true;

            expect(store.activityEntries).toEqual([user1Entry1]);
          }
        );

        it(
          'returns all entries for the first user when the ' +
          'showOnlyIndividuallyAssignable flag is false',
          () => {
            const store = new Datastore(entries);
            store.state.showOnlyIndividuallyAssignable = false;

            expect(store.activityEntries).toEqual([user1Entry1, user1Entry2]);
          }
        );
      }
    );

    describe(
      'hasChanges',
      () => {
        let store;

        beforeEach(
          () => {
            user1Entry1 = {
              assignable_id: 111,
              individually_assignable: true,
              user_id: 123,
            };
            user2Entry1 = {
              assignable_id: 111,
              individually_assignable: true,
              user_id: 456,
            };

            const entries = { 123: [user1Entry1], 456: [user2Entry1] };
            store = new Datastore(entries);
          }
        );

        it(
          'returns true if any property of any entry is different from ' +
          'the original state',
          () => {
            store.entries['123'][0].individually_assignable = false;

            expect(store.hasChanges).toBeTruthy();
          }
        );

        it(
          'returns false if no property of any entry is different from ' +
          'the original state',
          () => {
            store.entries['123'][0].individually_assignable = false;
            store.entries['123'][0].individually_assignable = true;

            expect(store.hasChanges).toBeFalsy();
          }
        );
      }
    );

    describe(
      'hasEntries',
      () => {
        it(
          'is true if a non-empty object is passed in',
          () => {
            const store = new Datastore({ 'a': ['b'] });

            expect(store.hasEntries).toBeTruthy();
          }
        );

        it(
          'is false if an empty object is passed in',
          () => {
            const store = new Datastore({});

            expect(store.hasEntries).toBeFalsy();
          }
        );
      }
    );

    describe(
      'strandHeaders',
      () => {
        const entries = {
          123: [
            {
              individually_assignable: true,
              strand_color: '#FFF',
              strand_id: 111,
              strand_name: 'Strand 1',
            },
            {
              individually_assignable: true,
              strand_color: '#FFF',
              strand_id: 111,
              strand_name: 'Strand 1',
            },
            {
              individually_assignable: false,
              strand_color: '#000',
              strand_id: 222,
              strand_name: 'Strand 2',
            },
            {
              individually_assignable: true,
              strand_color: '#FFF',
              strand_id: 111,
              strand_name: 'Strand 1',
            },
            {
              individually_assignable: true,
              strand_color: '#000',
              strand_id: 222,
              strand_name: 'Strand 2',
            },
            {
              individually_assignable: false,
              strand_color: '#000',
              strand_id: 222,
              strand_name: 'Strand 2',
            },
            {
              individually_assignable: true,
              strand_color: '#FFF',
              strand_id: 111,
              strand_name: 'Strand 1',
            },
          ],
        };

        const store = new Datastore(entries);

        describe(
          'when showOnlyIndividuallyAssignable is false',
          () => {
            beforeEach(
              () => store.state.showOnlyIndividuallyAssignable = false
            );

            it(
              'returns strand groups for all activities, preserving the ' +
              'activity order, with separate groups for non-contiguous ' +
              'strands',
              () => {
                expect(store.strandHeaders).toEqual(
                  [
                    { color: '#FFF', count: 2, id: 111, name: 'Strand 1' },
                    { color: '#000', count: 1, id: 222, name: 'Strand 2' },
                    { color: '#FFF', count: 1, id: 111, name: 'Strand 1' },
                    { color: '#000', count: 2, id: 222, name: 'Strand 2' },
                    { color: '#FFF', count: 1, id: 111, name: 'Strand 1' },
                  ]
                );
              }
            );
          }
        );

        describe(
          'when showOnlyIndividuallyAssignable is true',
          () => {
            beforeEach(
              () => store.state.showOnlyIndividuallyAssignable = true
            );

            it(
              'returns strand groups only for individually-assignable ' +
              'activities, preserving the activity order, with separate ' +
              'groups for non-contiguous strands',
              () => {
                expect(store.strandHeaders).toEqual(
                  [
                    { color: '#FFF', count: 3, id: 111, name: 'Strand 1' },
                    { color: '#000', count: 1, id: 222, name: 'Strand 2' },
                    { color: '#FFF', count: 1, id: 111, name: 'Strand 1' },
                  ]
                );
              }
            );
          }
        );
      }
    );

    describe(
      'checkAll',
      () => {
        it(
          'flags all entries with an assignable_id matching the specified ' +
          'activity id as being individually-assigned',
          async () => {
            user1Entry1 = {
              assignable_id: 111,
              individually_assigned: false,
              user_id: 123,
            };
            user1Entry2 = {
              assignable_id: 222,
              individually_assigned: false,
              user_id: 123,
            };
            user2Entry1 = {
              assignable_id: 111,
              individually_assigned: true,
              user_id: 456,
            };
            user2Entry2 = {
              assignable_id: 222,
              individually_assigned: false,
              user_id: 456,
            };

            const entries = {
              123: [user1Entry1, user1Entry2],
              456: [user2Entry1, user2Entry2],
            };

            const store = new Datastore(entries);

            await store.checkAll(222);

            expect(
              [...store.entries[123], ...store.entries[456]].map(
                (entry) => entry.individually_assigned
              )
            ).toEqual([false, true, true, true]);
          }
        );
      }
    );

    describe(
      'filterColumns',
      () => {
        const entry1 = {
          assignable_id: 111,
          individually_assignable: true,
        };
        const entry2 = {
          assignable_id: 222,
          individually_assignable: false,
        };

        const columns = [entry1, entry2];

        it(
          'returns only the individually-assigned entries from the specified ' +
          'columns when the showOnlyIndividuallyAssignable flag is true',
          () => {
            const store = new Datastore({});
            store.state.showOnlyIndividuallyAssignable = true;

            expect(store.filterColumns(columns)).toEqual([entry1]);
          }
        );

        it(
          'returns all the specified columns when the ' +
          'showOnlyIndividuallyAssignable flag is false',
          () => {
            const store = new Datastore({});
            store.state.showOnlyIndividuallyAssignable = false;

            expect(store.filterColumns(columns)).toEqual([entry1, entry2]);
          }
        );
      }
    );

    describe(
      'startEditing',
      () => {
        it(
          'marks the specified activity as currently being edited',
          () => {
            const store = new Datastore({});

            const activityId = 123;

            store.startEditing(activityId);

            expect(store.state.activityIdBeingEdited).toBe(activityId);
          }
        );
      }
    );

    describe(
      'uncheckAll',
      () => {
        it(
          'flags all entries with an assignable_id matching the specified ' +
          'activity id as not being individually-assigned',
          () => {
            user1Entry1 = {
              assignable_id: 111,
              individually_assigned: false,
              user_id: 123,
            };
            user1Entry2 = {
              assignable_id: 222,
              individually_assigned: true,
              user_id: 123,
            };
            user2Entry1 = {
              assignable_id: 111,
              individually_assigned: true,
              user_id: 456,
            };
            user2Entry2 = {
              assignable_id: 222,
              individually_assigned: true,
              user_id: 456,
            };

            const entries = {
              123: [user1Entry1, user1Entry2],
              456: [user2Entry1, user2Entry2],
            };

            const store = new Datastore(entries);

            store.uncheckAll(222);

            expect(
              [user1Entry1, user1Entry2, user2Entry1, user2Entry2].map(
                (entry) => entry.individually_assigned
              )
            ).toEqual([false, false, true, false]);
          }
        );
      }
    );

    describe(
      'updateAssignableState',
      () => {
        let entries;
        let store;

        beforeEach(
          () => {
            user1Entry1 = {
              assignable_id: 111,
              individually_assignable: true,
              user_id: 123,
            };
            user1Entry2 = {
              assignable_id: 222,
              individually_assignable: false,
              user_id: 123,
            };
            user2Entry1 = {
              assignable_id: 111,
              individually_assignable: false,
              user_id: 456,
            };
            user2Entry2 = {
              assignable_id: 222,
              individually_assignable: true,
              user_id: 456,
            };

            entries = {
              123: [user1Entry1, user1Entry2],
              456: [user2Entry1, user2Entry2],
            };

            store = new Datastore(entries);
          }
        );

        it(
          'flags all entries with an assignable_id matching the specified ' +
          'activity id as not being individually-assignable when a false ' +
          'value is specified',
          () => {
            store.updateAssignableState(222, false);

            expect(
              [user1Entry1, user1Entry2, user2Entry1, user2Entry2].map(
                (entry) => entry.individually_assignable
              )
            ).toEqual([true, false, false, false]);
          }
        );

        it(
          'flags all entries with an assignable_id matching the specified ' +
          'activity id as being individually-assignable when a true ' +
          'value is specified',
          () => {
            store.updateAssignableState(222, true);

            expect(
              [user1Entry1, user1Entry2, user2Entry1, user2Entry2].map(
                (entry) => entry.individually_assignable
              )
            ).toEqual([true, true, false, true]);
          }
        );
      }
    );

    describe('hasVariedDueDates', () => {
      let entries;
      let store;

      beforeEach(
        () => {
          user1Entry1 = {
            assignable_id: 111,
            due_date: '9/25',
            individually_assigned: false,
            individual_due_date: null,
            user_id: 123,
          };
          user2Entry1 = {
            assignable_id: 111,
            due_date: '9/25',
            individually_assigned: false,
            individual_due_date: null,
            last_individual_due_date: null,
            user_id: 456,
          };
        }
      );

      describe('when no individual due date is set', () => {
        it('returns false', () => {
          entries = {
            123: [user1Entry1],
            456: [user2Entry1],
          };

          store = new Datastore(entries);
          expect(store.hasVariedDueDates(111)).toBe(false);
        });
      });

      describe('when an individual due date identical to the default is set', () => {
        it('returns false', () => {
          user2Entry1.individual_due_date = '9/25';

          entries = {
            123: [user1Entry1],
            456: [user2Entry1],
          };

          store = new Datastore(entries);
          expect(store.hasVariedDueDates(111)).toBe(false);
        });
      });

      describe('when an individual due date different from the default is set', () => {
        it('returns true', () => {
          user1Entry1.individual_due_date = '9/26';

          entries = {
            123: [user1Entry1],
            456: [user2Entry1],
          };

          store = new Datastore(entries);
          expect(store.hasVariedDueDates(111)).toBe(true);
        });
      });
    });
  }
);
