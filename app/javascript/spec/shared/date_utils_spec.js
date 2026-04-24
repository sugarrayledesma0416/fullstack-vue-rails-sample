import {
  firstDayOfMonthFromDate,
  lastDayOfMonthFromDate,
  dateFromCourseDateString,
  sectionTimezone,
} from 'shared/date_utils';

describe('date_utils', () => {
  describe(
    'firstDayOfMonthFromDate',
    () => {
      describe(
        'when given a date',
        () => {
          it(
            'returns the first day of the month for that date',
            () => {
              const date = new Date(2022, 6, 15);
              const firstDay = new Date(2022, 6, 1);

              expect(firstDayOfMonthFromDate(date)).toEqual(firstDay);
            }
          );
        }
      );

      describe(
        'when given something other than a date',
        () => {
          it(
            'returns null',
            () => {
              expect(firstDayOfMonthFromDate(null)).toEqual(null);
            }
          );
        }
      );
    }
  );

  describe(
    'lastDayOFMonthFromDate',
    () => {
      describe(
        'when given a date',
        () => {
          it(
            'returns the last day of the month for that date',
            () => {
              const date = new Date(2022, 6, 15);
              const lastDay = new Date(2022, 6, 31);

              expect(lastDayOfMonthFromDate(date)).toEqual(lastDay);
            }
          );
        }
      );

      describe(
        'when given something other than a date',
        () => {
          it(
            'returns null',
            () => {
              expect(lastDayOfMonthFromDate(null)).toEqual(null);
            }
          );
        }
      );
    }
  );

  describe(
    'dateFromCourseDateString',
    () => {
      describe(
        'when given a date string formatted YYYY-MM-DD',
        () => {
          it(
            'returns a Date object for that date string at midnight',
            () => {
              const dateString = '2022-07-02';
              const date = dateFromCourseDateString(dateString);

              expect(date.toISOString())
                .toEqual('2022-07-02T04:00:00.000Z');
            }
          );
        }
      );

      describe(
        'when given a string with bad formatting',
        () => {
          it(
            'throws an error',
            () => {
              expect(() => dateFromCourseDateString('2022/12/10'))
                .toThrowError('Malformatted date string, use "YYYY-MM-DD"');
            }
          );
        }
      );
    }
  );

  describe(
    'sectionTimezone',
    () => {
      describe(
        'when the VHL.section_tz_info meta tag exists and has content',
        () => {
          beforeEach(() => {
            const meta = document.createElement('meta');
            meta.setAttribute('name', 'VHL.section_tz_info');
            meta.setAttribute('content', 'Some/timezone');
            document.head.appendChild(meta);
          });

          it(
            'returns the content value',
            () => {
              expect(sectionTimezone()).toEqual('Some/timezone');
            }
          );
        }
      );

      describe(
        'when there is no VHL.section_tz_info meta tag',
        () => {
          beforeEach(() => {
            // Ensure no meta exists
            const metaTag = document.querySelector('meta[name="VHL.section_tz_info"]');
            if (metaTag) {
              metaTag.parentElement.removeChild(metaTag);
            }
          });
          it(
            'returns the the browser default',
            () => {
              expect(sectionTimezone()).toEqual('America/New_York');
            }
          )
        }
      );
    }
  );
});
