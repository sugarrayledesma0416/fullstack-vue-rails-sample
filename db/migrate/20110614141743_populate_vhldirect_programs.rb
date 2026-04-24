class PopulateVhldirectPrograms < ActiveRecord::Migration[4.2]
  def self.up
    sql = "INSERT INTO vhldirect_programs (program_id, name) " +
          "VALUES (1, 'aventuras2e'), " +
          "       (2, 'espaces'), " +
          "       (3, 'imagina'), " +
          "       (4, 'suena'), " +
          "       (5, 'vistas3e'), " +
          "       (6, 'revista2e'), " +
          "       (7, 'enfoques2e'), " +
          "       (8, 'imaginez'), " +
          "       (9, 'facetas2e'), " +
          "       (10, 'descubreone'), " +
          "       (11, 'viva'), " +
          "       (12, 'descubrethree'), " +
          "       (13, 'descubretwo'), " +
          "       (15, 'ventanas2e'), " +
          "       (16, 'adelanteuno'), " +
          "       (17, 'adelantedos'), " +
          "       (18, 'adelantetres'), " +
          "       (19, 'panorama3e'), " +
          "       (20, 'aventuras3e'), " +
          "       (21, 'promenades'), " +
          "       (22, 'revista3e'), " +
          "       (23, 'invitaciones2e'), " +
          "       (24, 'invitaciones2e'), " +
          "       (25, 'holaquetal'), " +
          "       (26, 'imagina2e'), " +
          "       (27, 'suena2e'), " +
          "       (28, 'viva2e'), " +
          "       (29, 'immagina'), " +
          "       (30, 'espaces2e'), " +
          "       (31, 'faceaface'), " +
          "       (32, 'sentieri'), " +
          "       (33, 'daccordone'), " +
          "       (34, 'daccordtwo'), " +
          "       (35, 'daccordthree'), " +
          "       (37, 'denk mal'), " +
          "       (38, 'enfoques3e'), " +
          "       (39, 'facetas3e'), " +
          "       (40, 'vistas4e'), " +
          "       (41, 'imaginez2e'), " +
          "       (42, 'revez'), " +
          "       (43, 'Intrigas'), " +
          "       (44, 'protagonistas'), " +
          "       (45, 'handbook of spanish grammar'), " +
          "       (46, 'taller de escritores');"
    ActiveRecord::Base.connection.execute(sql) 
  end

  def self.down
    sql = "DELETE FROM vhldirect_programs " +
          "WHERE (program_id = 1  AND name = 'aventuras2e') " +
          "   OR (program_id = 2  AND name = 'espaces') " +
          "   OR (program_id = 3  AND name = 'imagina') " +
          "   OR (program_id = 4  AND name = 'suena') " +
          "   OR (program_id = 5  AND name = 'vistas3e') " +
          "   OR (program_id = 6  AND name = 'revista2e') " +
          "   OR (program_id = 7  AND name = 'enfoques2e') " +
          "   OR (program_id = 8  AND name = 'imaginez') " +
          "   OR (program_id = 9  AND name = 'facetas2e') " +
          "   OR (program_id = 10 AND name = 'descubreone') " +
          "   OR (program_id = 11 AND name = 'viva') " +
          "   OR (program_id = 12 AND name = 'descubrethree') " +
          "   OR (program_id = 13 AND name = 'descubretwo') " +
          "   OR (program_id = 15 AND name = 'ventanas2e') " +
          "   OR (program_id = 16 AND name = 'adelanteuno') " +
          "   OR (program_id = 17 AND name = 'adelantedos') " +
          "   OR (program_id = 18 AND name = 'adelantetres') " +
          "   OR (program_id = 19 AND name = 'panorama3e') " +
          "   OR (program_id = 20 AND name = 'aventuras3e') " +
          "   OR (program_id = 21 AND name = 'promenades') " +
          "   OR (program_id = 22 AND name = 'revista3e') " +
          "   OR (program_id = 23 AND name = 'invitaciones2e') " +
          "   OR (program_id = 24 AND name = 'invitaciones2e') " +
          "   OR (program_id = 25 AND name = 'holaquetal') " +
          "   OR (program_id = 26 AND name = 'imagina2e') " +
          "   OR (program_id = 27 AND name = 'suena2e') " +
          "   OR (program_id = 28 AND name = 'viva2e') " +
          "   OR (program_id = 29 AND name = 'immagina') " +
          "   OR (program_id = 30 AND name = 'espaces2e') " +
          "   OR (program_id = 31 AND name = 'faceaface') " +
          "   OR (program_id = 32 AND name = 'sentieri') " +
          "   OR (program_id = 33 AND name = 'daccordone') " +
          "   OR (program_id = 34 AND name = 'daccordtwo') " +
          "   OR (program_id = 35 AND name = 'daccordthree') " +
          "   OR (program_id = 37 AND name = 'denk mal') " +
          "   OR (program_id = 38 AND name = 'enfoques3e') " +
          "   OR (program_id = 39 AND name = 'facetas3e') " +
          "   OR (program_id = 40 AND name = 'vistas4e') " +
          "   OR (program_id = 41 AND name = 'imaginez2e') " +
          "   OR (program_id = 42 AND name = 'revez') " +
          "   OR (program_id = 43 AND name = 'Intrigas') " +
          "   OR (program_id = 44 AND name = 'protagonistas') " +
          "   OR (program_id = 45 AND name = 'handbook of spanish grammar') " +
          "   OR (program_id = 46 AND name = 'taller de escritores');"
    ActiveRecord::Base.connection.execute(sql) 
  end
end
