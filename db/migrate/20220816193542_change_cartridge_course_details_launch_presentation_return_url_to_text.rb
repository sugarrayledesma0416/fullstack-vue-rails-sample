class ChangeCartridgeCourseDetailsLaunchPresentationReturnUrlToText < ActiveRecord::Migration[5.2]
  def change
    safety_assured { change_column :cartridge_course_context_details, :launch_presentation_return_url, :text }
  end
end
