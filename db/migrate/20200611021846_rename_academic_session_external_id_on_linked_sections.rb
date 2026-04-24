class RenameAcademicSessionExternalIdOnLinkedSections < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_column :one_roster_linked_sections, :academic_session_external_id, :academic_session
    end
  end
end
