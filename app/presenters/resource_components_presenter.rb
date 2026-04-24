class ResourceComponentsPresenter
  attr_accessor :program_id

  def initialize(program_id)
    self.program_id = program_id
  end

  def populate
    components.each do |component|
      component.extend DeleteLinkDisplayable
      component.set_display_delete_link
    end
    self
  end

  def components
     @components ||= ResourceComponent.by_program(program_id)
  end

  module DeleteLinkDisplayable
    attr_writer :display_delete_link

    def set_display_delete_link
      self.display_delete_link = !resources.exists?
    end

    def display_delete_link?
      @display_delete_link
    end
  end
end
