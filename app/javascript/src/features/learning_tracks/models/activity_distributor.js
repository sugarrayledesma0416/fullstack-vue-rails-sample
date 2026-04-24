import AssignmentGroup from './assignment_group';

/**
 * @typeDef {AssignmentObject}
 * @type {Object}
 * @property {Object} activity - activity to which assignement
 * belongs.
 * @property {number} due_date - due date of assignement.
 * @property {string} group - Group to which assignement
 * belongs.
 * @property {boolean} [individually_assignable] - Whether the assignment
 * is individually assignable. Only populated for assignments loaded from
 * a previous section. For learning tracks, this will be undefined.
 */

/**
 * @typeDef {ChunkElement}
 * @type {Array.<AssignmentObject>}
 */

/**
 * Consume chunks without exceeding the total time and build
 * assignment groups from them. This function returns a pair of
 * values: An array of assignment groups and an array of chunks that
 * were not consumed.
 *
 * @param {number} totalTime - total average time for dute dates.
 * @param {Array.<ChunkElement>} chunks - array of chunks.
 * @return {Array}
 */
function assign(totalTime, chunks) {
  /*
    * Split chunks at the point where the chunk time pushes the
    * accumulator past the total time.
    */
  let time = 0;
  const splitChunks = split(chunks, (chunk) => {
    const oldTime = time;
    time += chunkTime(chunk);
    // Never split on the first chunk.
    return oldTime !== 0 && time > totalTime;
  });

  const groups = buildGroups(splitChunks[0].flat());
  const remainder = splitChunks[1];

  return [groups, remainder];
}

/**
 * Convert an array of assignments into an array of chunks based
 * upon a strategy function. A chunk is an array of assignments that
 * are inseparable when assigning. Either the entire chunk can be
 * assigned on a given due date or none of it can.
 *
 * The strategy function accepts two arguments, the current
 * assignment and the previous assignment, and returns a boolean
 * value. If the strategy function considers two neighboring
 * assignments part of the same chunk then it returns true, false
 * otherwise.
 *
 * @param {Array.<AssignmentObject>} assignments - array of assignments.
 * @param {Function} strategy - chunking strategy.
 * @return {Array.<ChunkElement>}
 *
 */
function buildChunks(assignments, strategy) {
  return assignments.reduce((chunks, assignment) => {
    const chunk = chunks[chunks.length-1];
    const previous = chunk[chunk.length-1];

    if (previous === undefined || strategy(assignment, previous)) {
      chunk.push(assignment);
    } else {
      chunks.push([assignment]);
    }

    return chunks;
  }, [[]]);
}

/**
 * @typeDef {AssignmentGroupObject}
 * @type {Object}
 * @property {string} name - name of the assignment group.
 * @property {string} strand - strand name.
 * @property {string} lesson - lesson name.
 * @property {Array.<Object>} activities - activities in a
 * assignment group.
 */

/**
 * Convert an array of assignments into an array of assignment
 * groups. Neighboring assignments that belong to the same group
 * become part of the same assignment group.
 *
 * @param {Array.<AssignmentObject>} assignments - array of
 * assignments.
 * @return {Array.<AssignmentGroupObject>}
 */
function buildGroups(assignments) {
  return assignments.reduce((memo, assignment) => {
    const currentGroup = memo[memo.length-1];
    if (currentGroup && currentGroup.name === assignment.group &&
    currentGroup.lesson === assignment.activity.lesson_name &&
    currentGroup.strand === assignment.activity.strand_name) {
      currentGroup.addActivity(assignment.activity);
    } else {
      memo.push(AssignmentGroup.build(assignment));
    }

    return memo;
  }, []);
}

/**
 * Create an assignment calendar from an array of assignments, an
 * array of due dates, and a chunking strategy.
 * @param {Array.<AssignmentObject>} assignments - array of assignments.
 * @param {Array} dueDates - array of due dates.
 * @param {Function} strategy - chunking strategy.
 * @return {Object}
 */
function distribute(assignments, dueDates, strategy) {
  const chunks = buildChunks(assignments, strategy);
  const calendar = {};
  if (dueDates.length >= chunks.length) {
    // The simple case.  There are equal or fewer assignment chunks
    // than there are due dates.  So, just assign one chunk to each
    // due date and leave the remainder of the due dates with no
    // assignments.
    for (let i = 0; i < chunks.length; ++i) {
      calendar[dueDates[i]] = buildGroups(chunks[i]);
    }
  } else {
    // The complicated case.  Try our best to evenly distribute
    // assignments amongst all due dates.
    dueDates.reduce((memo, dueDate, i) => {
      // figure out the average time per due date
      const averageTime = memo.totalTime / (dueDates.length - i);

      // assign enough chunks to each date so there aren't leftover dates
      const result = assign(averageTime, memo.chunks);
      const groups = result[0];

      memo.calendar[dueDate] = groups;

      /* Use the chunk remainder for the next iteration. */
      return {
        chunks: result[1],
        totalTime: memo.totalTime - groupsTime(groups),
        calendar: memo.calendar,
      };
    }, {
      chunks: chunks,
      totalTime: chunkTime(assignments),
      calendar: calendar,
    });
  }

  return calendar;
}

/**
 * @typeDef {StrandObject}
 * @type {Object}
 * @property {string} name - name of the strand.
 * @property {string} lesson - lesson name.
 * @property {Array.<AssignmentGroupObject>} groups - groups having
 * having same strand and lesson.
 * @property {number} totalMinutes - total minutes to complete for all
 * assignment groups having same strand and lesson.
 */

/**
 * Converts an array of assignment groups into activities grouped
 * by strand and lesson
 *
 * @param {Array.<AssignmentObject>} groups - array of assignments groups.
 * @return {Array.<StrandObject>}
 */
function groupByStrand(groups) {
  return groups.reduce((memo, group) => {
    const currentStrandGroup = memo[memo.length-1];

    if (currentStrandGroup &&
    (group.strand === currentStrandGroup.name) &&
    (group.lesson === currentStrandGroup.lesson)) {
      currentStrandGroup.totalMinutes += group.totalMinutes;
      currentStrandGroup.groups.push(group);
    } else {
      memo.push({
        name: group.strand,
        lesson: group.lesson,
        totalMinutes: group.totalMinutes,
        groups: [group],
      });
    }
    return memo;
  }, []);
}

/**
 * @private
 * Calculates the total minutes to complete for a chunk.
 *
 * @param {Array.<AssignmentObject>} chunk - array of assignments in a chunk.
 * @return {number}
 */
function chunkTime(chunk) {
  return chunk.reduce((memo, assignment) => {
    return memo + assignment.activity.minutes_to_complete;
  }, 0);
}

/**
 * @private
 * Calculates the total minutes to complete for a group.
 *
 * @param {Array.<Object>} groups - array of assignments groups.
 * @return {number}
 */
function groupsTime(groups) {
  return groups.reduce((memo, group) => {
    return memo + group.totalMinutes;
  }, 0);
}

/**
 * @private
 * Break array into two sub-arrays. Iterator accepts each element of
 * the array in sequence and returns a boolean value. When iterator
 * returns true, the array is split on that element.
 *
 * @param {Array} array
 * @param {Function} iterator
 * @return {Array}
 */
function split(array, iterator) {
  let i;
  for (i = 0; i < array.length; ++i) {
    if (iterator(array[i])) {
      break;
    }
  }

  return [array.slice(0, i), array.slice(i)];
}

export { assign, buildChunks, buildGroups, distribute, groupByStrand };
