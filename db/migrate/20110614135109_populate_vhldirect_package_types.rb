class PopulateVhldirectPackageTypes < ActiveRecord::Migration[4.2]
  def self.up
    sql = "INSERT INTO vhldirect_package_types (package_label, edelivery_attribute) " +
          "VALUES ('supersite', 'MaestroSupersite'), " +
          "       ('websam', 'MaestroWebsam'), " +
          "       ('supersite_ancillary', 'MaestroLecturasSupersite'), " +
          "       ('supersite_websam', 'MaestroSupersiteandWebsam'), " +
          "       ('supersite_vtext', 'MaestroVtextandSupersite'), " +
          "       ('supersite_websam_vtext', 'MaestroVtextandSupersiteandWebsam'), " +
          "       ('supersite_short', 'MaestroSupersite12monthaccess'), " +
          "       ('websam_short', 'MaestroWebsam12monthaccess'), " +
          "       ('supersite_websam_short', 'MaestroSupersiteandWebsam12monthaccess');"
    ActiveRecord::Base.connection.execute(sql) 
  end

  def self.down
    sql = "DELETE FROM vhldirect_package_types " +
          "WHERE (package_label = 'supersite' AND edelivery_attribute = 'MaestroSupersite') " +
          "   OR (package_label = 'websam' AND edelivery_attribute = 'MaestroWebsam') " +
          "   OR (package_label = 'supersite_ancillary' AND edelivery_attribute = 'MaestroLecturasSupersite') " +
          "   OR (package_label = 'supersite_websam' AND edelivery_attribute = 'MaestroSupersiteandWebsam') " +
          "   OR (package_label = 'supersite_vtext' AND edelivery_attribute = 'MaestroVtextandSupersite') " +
          "   OR (package_label = 'supersite_websam_vtext' AND edelivery_attribute = 'MaestroVtextandSupersiteandWebsam') " +
          "   OR (package_label = 'supersite_short' AND edelivery_attribute = 'MaestroSupersite12monthaccess') " +
          "   OR (package_label = 'websam_short' AND edelivery_attribute = 'MaestroWebsam12monthaccess') " +
          "   OR (package_label = 'supersite_websam_short' AND edelivery_attribute = 'MaestroSupersiteandWebsam12monthaccess');"
    ActiveRecord::Base.connection.execute(sql) 
  end
end
