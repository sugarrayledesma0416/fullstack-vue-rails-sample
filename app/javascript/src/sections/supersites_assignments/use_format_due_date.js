import { parse, format } from 'date-fns';

const useFormatDueDate = () => {
  const formatDueDate = (dueDate, datePart) => {
    if (dueDate === 'overdue') {
      return dueDate;
    }

    return format(parse(dueDate, 'yyyy-MM-dd', new Date()), datePart);
  };

  return { formatDueDate };
};

export default useFormatDueDate;
