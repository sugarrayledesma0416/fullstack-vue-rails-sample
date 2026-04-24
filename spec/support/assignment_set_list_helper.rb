module AssignmentSetListHelpers
  def make_custom_order_expected_entries
    {
      custom_order:
        [
          {
            due_date: due_date_1,
            due_date_string: due_date_1.strftime('%A %b %-d'),
            id: set.id,
            section_id: section.id,
            activities: [
              {
                activity_id: activity_3.id,
                activity_title: 'Activity 3 <b>title</b>',
                activity_type: nil,
                assignment_set_rank: 100,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: activity_3.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_3.id)
              },
              {
                activity_id: activity_2.id,
                activity_title: 'Activity 2 <b>title</b>',
                activity_type: nil,
                assignment_set_rank: 200,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#FFF',
                strand_id: concept_1.id,
                strand_name: 'Strand 1 <b>title</b>',
                toc_location_rank: activity_2.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_2.id)
              }
            ]
          }
        ],
      default_order:
        [
          {
            due_date: due_date_1,
            due_date_string: due_date_1.strftime('%A %b %-d'),
            id: nil,
            section_id: section.id,
            activities: [
              {
                activity_id: activity_2.id,
                activity_title: 'Activity 2 <b>title</b>',
                activity_type: nil,
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#FFF',
                strand_id: concept_1.id,
                strand_name: 'Strand 1 <b>title</b>',
                toc_location_rank: activity_2.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_2.id)
              },
              {
                activity_id: activity_3.id,
                activity_title: 'Activity 3 <b>title</b>',
                activity_type: nil,
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: activity_3.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_3.id)
              }
            ]
          }
        ]
    }
  end

  def make_no_custom_order_assignment_set_expected_entries
    {
      custom_order: [
        {
          due_date: due_date_1,
          due_date_string: due_date_1.strftime('%A %b %-d'),
          id: nil,
          section_id: section.id,
          activities: [
            {
              activity_id: activity_2.id,
              activity_title: 'Activity 2 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#FFF',
              strand_id: concept_1.id,
              strand_name: 'Strand 1 <b>title</b>',
              toc_location_rank: activity_2.toc_location_rank,
              toc_rank: 2,
              url: section_activity_path(0, activity_2.id)
            },
            {
              activity_id: activity_3.id,
              activity_title: 'Activity 3 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#000',
              strand_id: concept_2.id,
              strand_name: 'Strand 2 <b>title</b>',
              toc_location_rank: activity_3.toc_location_rank,
              toc_rank: 3,
              url: section_activity_path(0, activity_3.id)
            }
          ]
        },
        {
          due_date: due_date_2,
          due_date_string: due_date_2.strftime('%A %b %-d'),
          id: nil,
          section_id: section.id,
          activities: [
            {
              activity_id: activity_1.id,
              activity_title: 'Activity 1 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#FFF',
              strand_id: concept_1.id,
              strand_name: 'Strand 1 <b>title</b>',
              toc_location_rank: activity_1.toc_location_rank,
              toc_rank: 1,
              url: section_activity_path(0, activity_1.id)
            }
          ]
        }
      ],
      default_order: [
        {
          due_date: due_date_1,
          due_date_string: due_date_1.strftime('%A %b %-d'),
          id: nil,
          section_id: section.id,
          activities: [
            {
              activity_id: activity_2.id,
              activity_title: 'Activity 2 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#FFF',
              strand_id: concept_1.id,
              strand_name: 'Strand 1 <b>title</b>',
              toc_location_rank: activity_2.toc_location_rank,
              toc_rank: 2,
              url: section_activity_path(0, activity_2.id)
            },
            {
              activity_id: activity_3.id,
              activity_title: 'Activity 3 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#000',
              strand_id: concept_2.id,
              strand_name: 'Strand 2 <b>title</b>',
              toc_location_rank: activity_3.toc_location_rank,
              toc_rank: 3,
              url: section_activity_path(0, activity_3.id)
            }
          ]
        },
        {
          due_date: due_date_2,
          due_date_string: due_date_2.strftime('%A %b %-d'),
          id: nil,
          section_id: section.id,
          activities: [
            {
              activity_id: activity_1.id,
              activity_title: 'Activity 1 <b>title</b>',
              activity_type: nil,
              assignment_set_rank: nil,
              lesson_name: 'Lesson 1 short <b>title</b>',
              strand_color: '#FFF',
              strand_id: concept_1.id,
              strand_name: 'Strand 1 <b>title</b>',
              toc_location_rank: activity_1.toc_location_rank,
              toc_rank: 1,
              url: section_activity_path(0, activity_1.id)
            }
          ]
        }
      ]
    }
  end

  def make_igc_assignment_set_entries
    [
      {
        due_date: due_date_1,
        due_date_string: due_date_1.strftime('%A %b %-d'),
        id: nil,
        section_id: section.id,
        activities: [
          {
            activity_id: activity_1.id,
            activity_title: 'Activity 1 <b>title</b>',
            activity_type: nil,
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: '#FFF',
            strand_id: concept_1.id,
            strand_name: 'Strand 1 <b>title</b>',
            toc_location_rank: activity_1.toc_location_rank,
            toc_rank: 2,
            url: section_activity_path(0, activity_1.id)
          },
          {
            activity_id: activity_2.id,
            activity_title: 'Activity 2 <b>title</b>',
            activity_type: nil,
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: '#FFF',
            strand_id: concept_1.id,
            strand_name: 'Strand 1 <b>title</b>',
            toc_location_rank: activity_2.toc_location_rank,
            toc_rank: 2,
            url: section_activity_path(0, activity_2.id)
          },
          {
            activity_id: instructor_activity_1.id,
            activity_title: 'IGC 1 <b>title</b>',
            activity_type: 'composition',
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: '#000',
            strand_id: concept_2.id,
            strand_name: 'Strand 2 <b>title</b>',
            toc_location_rank: instructor_activity_1.toc_location_rank,
            toc_rank: 1,
            url: section_activity_path(0, instructor_activity_1.id)
          },
          {
            activity_id: instructor_activity_2.id,
            activity_title: 'IGC 2 <b>title</b>',
            activity_type: 'composition',
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: '#000',
            strand_id: concept_2.id,
            strand_name: 'Strand 2 <b>title</b>',
            toc_location_rank: instructor_activity_2.toc_location_rank,
            toc_rank: 1,
            url: section_activity_path(0, instructor_activity_2.id)
          },
          {
            activity_id: activity_3.id,
            activity_title: 'Activity 3 <b>title</b>',
            activity_type: nil,
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: '#000',
            strand_id: concept_2.id,
            strand_name: 'Strand 2 <b>title</b>',
            toc_location_rank: activity_3.toc_location_rank,
            toc_rank: 2,
            url: section_activity_path(0, activity_3.id)
          },
          {
            activity_id: assessment.id,
            activity_title: 'Assesment 1 <b>title</b>',
            activity_type: 'exam',
            assignment_set_rank: nil,
            lesson_name: 'Lesson 1 short <b>title</b>',
            strand_color: assessments_concept.background_color,
            strand_id: assessments_concept.id,
            strand_name: 'Strand Quiz <b>title</b>',
            toc_location_rank: assessment.toc_location_rank,
            toc_rank: 2,
            url: section_activity_path(0, assessment.id)
          }
        ]
      }
    ]
  end

  def make_igc_assessment_set_custom_entries
    {
      custom_order:
        [
          {
            due_date: due_date_1,
            due_date_string: due_date_1.strftime('%A %b %-d'),
            id: assignment_set.id,
            section_id: section.id,
            activities: [
              {
                activity_id: assessment_1.id,
                activity_title: 'Assessment 1 title',
                activity_type: 'exam',
                assignment_set_rank: 1,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: assessments_concept.background_color,
                strand_id: assessments_concept.id,
                strand_name: 'Strand Quiz <b>title</b>',
                toc_location_rank: assessment_1.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, assessment_1.id)
              },
              {
                activity_id: instructor_activity_2.id,
                activity_title: 'IGC 2 <b>title</b>',
                activity_type: 'composition',
                assignment_set_rank: 2,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: instructor_activity_2.toc_location_rank,
                toc_rank: 1,
                url: section_activity_path(0, instructor_activity_2.id)
              },
              {
                activity_id: instructor_activity_1.id,
                activity_title: 'IGC 1 <b>title</b>',
                activity_type: 'composition',
                assignment_set_rank: 3,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: instructor_activity_1.toc_location_rank,
                toc_rank: 1,
                url: section_activity_path(0, instructor_activity_1.id)
              },
              {
                activity_id: activity_1.id,
                activity_title: 'Activity 1 title',
                activity_type: 'composition',
                assignment_set_rank: 4,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: activity_1.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_1.id)
              }
            ]
          }
        ],
      default_order:
        [
          {
            due_date: due_date_1,
            due_date_string: due_date_1.strftime('%A %b %-d'),
            id: nil,
            section_id: section.id,
            activities: [
              {
                activity_id: instructor_activity_1.id,
                activity_title: 'IGC 1 <b>title</b>',
                activity_type: 'composition',
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: instructor_activity_1.toc_location_rank,
                toc_rank: 1,
                url: section_activity_path(0, instructor_activity_1.id)
              },
              {
                activity_id: instructor_activity_2.id,
                activity_title: 'IGC 2 <b>title</b>',
                activity_type: 'composition',
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: instructor_activity_2.toc_location_rank,
                toc_rank: 1,
                url: section_activity_path(0, instructor_activity_2.id)
              },
              {
                activity_id: activity_1.id,
                activity_title: 'Activity 1 title',
                activity_type: 'composition',
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: '#000',
                strand_id: concept_2.id,
                strand_name: 'Strand 2 <b>title</b>',
                toc_location_rank: activity_1.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, activity_1.id)
              },
              {
                activity_id: assessment_1.id,
                activity_title: 'Assessment 1 title',
                activity_type: 'exam',
                assignment_set_rank: nil,
                lesson_name: 'Lesson 1 short <b>title</b>',
                strand_color: assessments_concept.background_color,
                strand_id: assessments_concept.id,
                strand_name: 'Strand Quiz <b>title</b>',
                toc_location_rank: assessment_1.toc_location_rank,
                toc_rank: 2,
                url: section_activity_path(0, assessment_1.id)
              }
            ]
          }
        ]
    }
  end
end
