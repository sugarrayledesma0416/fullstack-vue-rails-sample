import GrowthAssessmentChartConfigurator, { consolidateSeriesData } from
  'features/gradebook/standards/student_detail_report/models/growth_assessment_chart_configurator';

describe('GrowthAssessmentChartConfigurator', () => {
  describe('consolidateSeriesData', () => {
    describe('when all the series have null values', () => {
      const seriesData = [
        [
          { category: 'Unit 1', isNull: true },
          { category: 'Unit 2', isNull: true },
          { category: 'Unit 3', isNull: true },
        ],
        [
          { category: 'Unit 1', isNull: true },
          { category: 'Unit 2', isNull: true },
          { category: 'Unit 3', isNull: true },
        ],
        [
          { category: 'Unit 1', isNull: true },
          { category: 'Unit 2', isNull: true },
          { category: 'Unit 3', isNull: true },
        ],
      ];
      const expectedConsolidatedData = [
        { category: 'Unit 1', isNull: true },
        { category: 'Unit 2', isNull: true },
        { category: 'Unit 3', isNull: true },
      ];

      it('should handle all null values correctly', () => {
        const consolidatedData = consolidateSeriesData(seriesData);

        expect(consolidatedData).toEqual(expectedConsolidatedData);
      });
    });

    describe('when all the series have no-null values', () => {
      const seriesData = [
        [
          { category: 'Unit 1', isNull: false },
          { category: 'Unit 2', isNull: false },
          { category: 'Unit 3', isNull: false },
        ],
        [
          { category: 'Unit 1', isNull: false },
          { category: 'Unit 2', isNull: false },
          { category: 'Unit 3', isNull: false },
        ],
        [
          { category: 'Unit 1', isNull: false },
          { category: 'Unit 2', isNull: false },
          { category: 'Unit 3', isNull: false },
        ],
      ];
      const expectedConsolidatedData = [
        { category: 'Unit 1', isNull: false },
        { category: 'Unit 2', isNull: false },
        { category: 'Unit 3', isNull: false },
      ];

      it('should handle all no-null values correctly', () => {
        const consolidatedData = consolidateSeriesData(seriesData);

        expect(consolidatedData).toEqual(expectedConsolidatedData);
      });
    });

    describe('when the series have mixed null and non-null values', () => {
      const seriesData = [
        [
          { category: 'Unit 1', isNull: true },
          { category: 'Unit 2', isNull: true },
          { category: 'Unit 3', isNull: true },
        ],
        [
          { category: 'Unit 1', isNull: false },
          { category: 'Unit 2', isNull: true },
          { category: 'Unit 3', isNull: true },
        ],
        [
          { category: 'Unit 1', isNull: true },
          { category: 'Unit 2', isNull: false },
          { category: 'Unit 3', isNull: true },
        ],
      ];
      const expectedConsolidatedData = [
        { category: 'Unit 1', isNull: false },
        { category: 'Unit 2', isNull: false },
        { category: 'Unit 3', isNull: true },
      ];

      it('should handle mixed null and non-null values correctly', () => {
        const consolidatedData = consolidateSeriesData(seriesData);

        expect(consolidatedData).toEqual(expectedConsolidatedData);
      });
    });
  });
});
