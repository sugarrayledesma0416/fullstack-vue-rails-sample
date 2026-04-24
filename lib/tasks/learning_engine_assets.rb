require_relative 'example_data_utils'

class LearningEngineAssets
  include ::ExampleDataUtils

  def initialize(program_id)
    @program_id = program_id
  end

  def import(activity_xml = "learning_engine_activity.xml")
    Activity.where(activity_type: 'learning_engine').map(&:destroy)
    copy_media_from_cms(media_list)
    MediaItem.find(136475).update!(:width => 900, :height => 526)
    MediaItem.find(137867).update!(:height => 486, :width => 864)
    MediaItem.find(138152).update!(:height => 486, :width => 864)
    # create json version of subtitles
    MediaItem.where(id: [119605, 119604]).map{ |mi| mi.send(:create_json_version) }

    activity = create_activity
    copy_learning_engine_xml(activity.content_filepath, activity_xml)
    # Save after we have written the xml file to disk!
    activity.save
    # purge existing attempts for the activity
    # (the activity isn't submittable)
    purge_attempts_for(activity)
    activity
  end

  def purge_attempts_for(activity)
    Attempt.where(activity_id: activity.id).destroy_all
  end

  def import_with_one_checkpoint(activity_xml)
    import(activity_xml)
  end

  def copy_learning_engine_xml(content_filepath, activity_xml)
    input_file = File.join('db', 'example_data', activity_xml)
    file_contents = File.read( input_file )
    File.open( content_filepath, 'w' ) { | file | file.puts file_contents }
  end

  def create_activity
    lesson = Program.find(@program_id).units.first.lessons.first
    strand = lesson.strands.first
    copy_from_activity = strand.descendant_activities.first

    activity = Activity.new
    copy_from_activity.attributes.each do |attr, val|
      activity[attr] = val
    end
    activity.activity_type = "learning_engine"
    activity.title = "Example Learning Engine Activity"
    activity.cms_activity_id = 3
    activity.cms_revision_id = 40000 + activity.cms_activity_id
    activity.points_possible = 12
    activity.id = nil

    activity
  end


  def media_list
   [ "0013/6797/3images.png",
     "0013/6798/AVE4e_L05_APP_P002_CO_68003_las_vacaciones.jpg",
     "0013/6799/AVE4e_L05_APP_P010_MF_649-03292476_estar_de_vacaciones.jpg",
     "0013/6800/AVE4e_L05_APP_P011_DR_2984579_ir_de_vacaciones.jpg",
     "0013/6801/AVE4e_L05_APP_P028_CU_CZP100808-149_ir_en_automovil.jpg",
     "0013/6802/AVE4e_L05_APP_P031_CU_OAS0949_ir_en_taxi.jpg",
     "0013/6803/AVE4e_L05_APP_P033_DR_26281386_ir_en_barco.jpg",
     "0013/6804/AVE4e_L05_APP_P035_DR_2659262_ir_en_motocicleta.jpg",
     "0013/6805/AVE4e_L05_APP_P036_CU_VAB090430-842_la_estacion_de_autobuses.jpg",
     "0013/6806/AVE4e_L05_APP_P037_CU_OAS0916_ir_en_autobus.jpg",
     "0013/6807/AVE4e_L05_APP_P040_CO_CB052579_la_estacion_del_metro.jpg",
     "0013/6808/AVE4e_L05_APP_P042_CU_GUH100922-027_la_estacion_del_tren.jpg",
     "0013/6809/AVE4e_L05_APP_P043_CU_TD121013_001_el_aeropuerto.jpg",
     "0013/6810/AVE4e_L05_APP_P044_CU_VAB090409-052_ir_en_avion.jpg",
     "0013/6811/AVE4e_L05_APP_P046_CU_P08-C-4_el_equipaje.jpg",
     "0013/6812/AVE4e_L05_APP_P047_CU_VAB090409-036_el_pasaje.jpg",
     "0013/6813/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
     "0013/6814/AVE4e_L05_APP_VOC_el_equipaje.mp3",
     "0013/6815/AVE4e_L05_APP_VOC_el_pasaje.mp3",
     "0013/6816/AVE4e_L05_APP_VOC_estar_de_vacaciones.mp3",
     "0013/6817/AVE4e_L05_APP_VOC_ir_de_vacaciones.mp3",
     "0013/6818/AVE4e_L05_APP_VOC_ir_en_autobus.mp3",
     "0013/6819/AVE4e_L05_APP_VOC_ir_en_automovil.mp3",
     "0013/6820/AVE4e_L05_APP_VOC_ir_en_avion.mp3",
     "0013/6821/AVE4e_L05_APP_VOC_ir_en_barco.mp3",
     "0013/6822/AVE4e_L05_APP_VOC_ir_en_motocicleta.mp3",
     "0013/6823/AVE4e_L05_APP_VOC_ir_en_taxi.mp3",
     "0013/6824/AVE4e_L05_APP_VOC_la_estacion_de_autobuses.mp3",
     "0013/6825/AVE4e_L05_APP_VOC_la_estacion_del_metro.mp3",
     "0013/6826/AVE4e_L05_APP_VOC_la_estacion_del_tren.mp3",
     "0013/6827/AVE4e_L05_APP_VOC_las_vacaciones.mp3",
     "0013/7813/VOL1e_L05_EXPLORE_VEPI_EU_tenemos_una_reservacion_UPDATE.mp3",
     "0013/7819/VOL1e_L05_EXPLORE_VEPI_EU_en_que_puedo_servirles_UPDATE.mp3",
     "0013/6475/SGT_proto_011614_Andy.mp4",
     "0013/8699/SpGT_L05.1_040614.mp4",
     "0013/7739/empleado.png",
     "0013/7819/VOL1e_L05_EXPLORE_VEPI_EU_en_que_puedo_servirles_UPDATE.mp3",
     "0013/7813/VOL1e_L05_EXPLORE_VEPI_EU_tenemos_una_reservacion_UPDATE.mp3",
     "0013/7790/VOL1e_L05_EXPLORE_VEPI_EU_a_nombre_de_quien_UPDATE.mp3",
     "0013/6828/postcard_collage.png",
     "0013/6829/vocab_grammar_chart.mp4",
     '0013/7867/VOL1e_L05_LEARN_VEPI_clip03_hi.mp4',
     "0013/7746/miguel.png",
     "0013/7745/maru.png",
     "0013/7744/marisa.png",
     "0013/7743/marie_fuentes.png",
     "0013/8152/present_progressive_tutorial_initial_screen.png",
     # video reference with subtitles
     "0011/9439/M3_PAN4e_L08_TXT_PANO_video_L.mp4",
     "0011/9604/M3_VIS4e_L08_TXT_PANO_eng.xml",
     "0011/9605/M3_VIS4e_L08_TXT_PANO_spa.xml"]
  end
end
