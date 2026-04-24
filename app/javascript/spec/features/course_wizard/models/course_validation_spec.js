import { CourseValidation } from 'features/course_wizard/models/course_validation';

describe('CourseValidation', () => {
  it('Creates a Course Validation', () => {
    const errorHandler = jest.fn();
    const options = { alias: 'foo', status: 'valid', description: 'bar', errorHandler };
    const validation = new CourseValidation(options);
    expect(validation.alias).toBe('foo');
    expect(validation.description).toBe('bar');
    expect(validation.status).toBe('valid');
  });

  it('Calls the error handler when the alias is invalid.', () => {
    const errorHandler = jest.fn();
    const options = { alias: undefined, status: 'valid', errorHandler };
    const validation = new CourseValidation(options);
    expect(errorHandler).toHaveBeenCalled();
  });

  it('Calls the error handler when the status is invalid.', () => {
    const errorHandler = jest.fn();
    const options = { alias: 'foo', status: 'bar', errorHandler };
    const validation = new CourseValidation(options);
    expect(errorHandler).toHaveBeenCalled();
  });

  it('Calls the error handler when the status requires a description.', () => {
    const errorHandler = jest.fn();
    const options = { alias: 'foo', status: 'invalid', errorHandler };
    const validation = new CourseValidation(options);
    expect(errorHandler).toHaveBeenCalled();
  });
});
