class DemoCourse < Course

  default_scope { where(is_demo: true) }

  def demo_section
    sections.first
  end
end
