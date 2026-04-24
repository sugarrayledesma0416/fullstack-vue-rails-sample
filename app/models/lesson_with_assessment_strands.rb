module LessonWithAssessmentStrands
  
  def strands 
    toc_entries.select{ |toc_entry| toc_entry.assessment? }
  end

end
