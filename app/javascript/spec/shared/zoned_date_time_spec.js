import ZonedDateTime from 'shared/zoned_date_time';

// mock date-fns module to simulate the local time zone
jest.mock('date-fns', () => {
  const actualDateFns = jest.requireActual('date-fns');
  return {
    ...actualDateFns,
    format: (date, formatStr) => {
      // redefine result when callling format with 'XXX'
      if (formatStr === 'XXX') {
        return '-05:00';
      }
     
      // when calling format with a format different than 'XXX',
      // execute the acatual function implementation
      return actualDateFns.format(date, formatStr);
    },
  };
});

describe('ZonedDateTime', () => {
  describe('when the date has time zone', () => {
    const dateString = '2025-03-11T13:28:11-07:00';
    const zonedDateTime = new ZonedDateTime(dateString);

    test('should detect is not an empty date', () => {
      expect(zonedDateTime.isEmpty()).toBe(false);
    });

    test('should return the correct time zone', () => {
      expect(zonedDateTime.getTimeZone()).toBe('-07:00')
    });
    
    test('should detect valid timezone', () => {
      expect(zonedDateTime.isValidTimeZoneOffset()).toBe(true);
    });

    test('should correctly format the date', () => {
      expect(zonedDateTime.formattedDate()).toBe('March 11, 2025');
    });

    test('should correctly format the time', () => {
      expect(zonedDateTime.formattedTime()).toBe('1:28:11 PM');
    });
  });

  describe ('when the date has no time zone', () => {
    const dateString = '2025-03-11 13:28:11';
    const zonedDateTime = new ZonedDateTime(dateString);

    test('should detect is not an empty date', () => {
      expect(zonedDateTime.isEmpty()).toBe(false);
    });

    test('should detect invalid timezone', () => {
      expect(zonedDateTime.isValidTimeZoneOffset()).toBe(false);
    });

    test('should return empty time zone', () => {
       expect(zonedDateTime.getTimeZone()).toBe('')
    })

    test('should return the local time zone', () => {
       expect(zonedDateTime.getLocalTimeZone()).toBe('-05:00')
    })

    test('should correctly format the date', () => {
      expect(zonedDateTime.formattedDate()).toBe('March 11, 2025');
    });

    test('should correctly format the time', () => {
      expect(zonedDateTime.formattedTime()).toBe('8:28:11 AM');
    });
  });
  
  describe ('when the date is empty or null', () =>{
    const dateString = null;
    const zonedDateTime = new ZonedDateTime(dateString);

    test('should detect is an empty date', () => {
      expect(zonedDateTime.isEmpty()).toBe(true);
    });
    
    test('should detect invalid timezone', () => {
      expect(zonedDateTime.isValidTimeZoneOffset()).toBe(false);
    });

    test('should return empty time zone', () => {
       expect(zonedDateTime.getTimeZone()).toBe('')
    })

    test('should return empty formatted date', () => {
      expect(zonedDateTime.formattedDate()).toBe('');
    });

    test('should return empty formatted time', () => {
      expect(zonedDateTime.formattedTime()).toBe('');
    });

    test('should return empty parsed date', () => {
      expect(zonedDateTime.parsedDate()).toBe('');
    });
  });

  describe ('when the date is invalid', () => {
    const dateString = 'invalid-date';
    const zonedDateTime = new ZonedDateTime(dateString);

    test('should detect is not an empty date', () => {
      expect(zonedDateTime.isEmpty()).toBe(false);
    });

    test('should detect invalid timezone', () => {
      expect(zonedDateTime.isValidTimeZoneOffset()).toBe(false);
    });

    test('should return empty time zone', () => {
       expect(zonedDateTime.getTimeZone()).toBe('')
    })

    test('should throw error for invalid date format', () => {
      expect(() => zonedDateTime.parsedDate()).toThrowError(`Invalid date format ${dateString}`);
    });
  });
});
