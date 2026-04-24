class WorksetPresenter

  attr_accessor :activity, :checkmark_role, :class_attr, :group, :is_current, :lang_attr, 
     :status_label, :strand_style, :vista_online_learning, :workset

  def initialize(activity, workset, vista_online_learning)
    self.activity = activity
    self.workset = workset
    self.vista_online_learning = vista_online_learning
  end

  def group_name_color
    if vista_online_learning
      self.lang_attr = 'en'
      self.strand_style = '--group-color: #666;'
    else
      self.lang_attr = activity.language
      self.strand_style = "--group-color: #{group[:assignments].first[0].concept.background_color}"
    end
  end

  def group_name
    name = group.fetch(:name, nil)
    if name
        name.gsub(/(<br\s*\/?>){1}.*/, '').html_safe
    else
        'activities'
    end
  end

  def assignment_list_styles(workset_activity)
    attempt = workset.attempt(workset_activity)
    self.is_current = (workset_activity.id == activity.id)
    self.status_label = (attempt ? attempt.expanded_status.to_s : 'unopened')
    self.checkmark_role = (status_label == 'completed') ? 'img' : 'presentation'
    self.class_attr = "  is-#{status_label}"
    if is_current
      self.class_attr = "#{class_attr}  is-current"
      self.status_label = 'In Progress'
    end

    # Set box color:
    self.strand_style = if status_label == 'unopened'
                          '--activity-color: white;'
                        # Define color for each assignment. In supersites it's the same as the group.
                        elsif vista_online_learning
                          # We need to override the colour and opacity this way, becase VOL programs
                          # have a 20 % opacity applied to all colours across the activity shell.
                          'background-color: #eee; opacity: 1'
                        else
                          "--activity-color: #{workset_activity.concept.background_color}"
                        end
  end

end
