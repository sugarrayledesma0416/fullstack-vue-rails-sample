import { pick } from 'shared/utils';
const filterRequestProperties = (obj) => {
  return pick(
    obj,
    'activity_id', 'activity_state', 'created_at', 'helpable_item_id',
    'helpable_item_type', 'id', 'instructor_comment', 'instructor_name',
    'processed_at', 'program_id', 'read_by_student', 'request_type',
    'section_id', 'status', 'student_comment', 'student_name', 'user_id'
  );
};
export { filterRequestProperties };
