module MockResultsHelper
  def mock_results(points_possible = 10, score = 0.5, instructor_graded_score_pending = false, instructor_points_possible = 10)
    results = double(MaestroActivityEngine::ActivityContent::Results, :total_points_possible => points_possible,
                                                   :score => score,
                                                   :instructor_graded_points_possible => instructor_points_possible)
    allow(results).to receive(:instructor_graded_score_pending?).and_return(instructor_graded_score_pending)
    results
  end
end
