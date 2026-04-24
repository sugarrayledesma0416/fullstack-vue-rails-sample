import DueDateGraph from 'features/learning_tracks/models/due_date_graph';
import AssignmentGroup from 'features/learning_tracks/models/assignment_group';

const activity1 = {
  id: 1,
  minutes_to_complete: 10,
  lesson_name: 'Lesson 1',
  strand_name: 'Strand 1',
};

const assignment1 = { activity: activity1, group: 'Learn' };
const group1 = AssignmentGroup.build(assignment1);

const localstore = {
  workLoad: {
    activityCount: 354,
    avg: 1555.5,
    max: 1564,
    min: 1547,
  },
  dueDate: {
    dayOfWeek: 'Su',
    label: 'Aug 29',
    locked: true,
    name: '08/29/2021',
  },
  groups: [group1],
  unitLabel: 'Lesson',
  showGroupInfoElm: false,
};
const graphElm = document.createElement('div');
const groupInfoElm = document.createElement('div');

let dueDateGraph;

class D3 {
  get scale() {
    return this;
  }

  append() {
    return this;
  }

  attr() {
    return this;
  }

  domain() {
    return this;
  }

  data() {
    return this;
  }

  enter() {
    return this;
  }

  linear() {
    return this;
  }

  on() {
    return this;
  }

  range() {
    return this;
  }

  select() {
    return this;
  }

  selectAll() {
    return this;
  }

  text() {
    return this;
  }
}

d3 = new D3();
let spy;

describe('DueDateGraph', () => {
  beforeEach(() => {
    dueDateGraph = new DueDateGraph(graphElm, groupInfoElm, localstore);
  });

  describe('#drawGraph', () => {
    it('calls d3 select method', () => {
      spy = jest.spyOn(d3, 'select');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 append method', () => {
      spy = jest.spyOn(d3, 'append');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 attr method', () => {
      spy = jest.spyOn(d3, 'attr');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 linear method', () => {
      spy = jest.spyOn(d3, 'linear');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 domain method', () => {
      spy = jest.spyOn(d3, 'domain');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 range method', () => {
      spy = jest.spyOn(d3, 'range');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });

    it('calls d3 on method', () => {
      spy = jest.spyOn(d3, 'on');
      dueDateGraph.drawGraph();
      expect(spy).toHaveBeenCalled();
    });
  });
});
