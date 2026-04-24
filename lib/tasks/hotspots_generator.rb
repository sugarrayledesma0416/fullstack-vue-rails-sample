require_relative 'example_data_utils'

class HotspotsGenerator
  include ::ExampleDataUtils

  def generate(program_id, activity_xml = "hotspot.xml")
    Activity.where(activity_type: 'hotspot').map(&:destroy)
    copy_media_from_cms(media_list)
    MediaItem.find(119938).update!(:height => 842, :width => 800)
    activity = create_activity(program_id)
    copy_xml(activity.content_filepath, activity_xml)
    activity.save
    activity
  end

  def copy_xml(content_filepath, activity_xml)
    input_file = File.join('db', 'example_data', activity_xml)
    file_contents = File.read( input_file )
    File.open( content_filepath, 'w' ) { | file | file.puts file_contents }
  end

  def create_activity(program_id)
    lesson = Program.find(program_id).units.first.lessons.first
    strand = lesson.strands.first
    copy_from_activity = strand.descendant_activities.first

    activity = Activity.new
    copy_from_activity.attributes.each do |attr, val|
      activity[attr] = val
    end
    activity.activity_type = "reference"
    activity.title = "Example Reference Activity with Hotspots"
    activity.cms_activity_id = 6
    activity.cms_revision_id = 40000 + activity.cms_activity_id
    activity.points_possible = 12
    activity.id = nil

    activity
  end

  def media_list
    ["0011/9938/DES2e_V1_TXT_L05_CO_p153.png",
    "0011/9955/DES2e_V1_L05_VOC__agente_viajes_.mp3",
    "0011/9976/DES2e_V1_L05_VOC__pasaporte_.mp3",
    "0011/9956/DES2e_V1_L05_VOC__ascensor_.mp3",
    "0011/9957/DES2e_V1_L05_VOC__avion_.mp3",
    "0011/9958/DES2e_V1_L05_VOC__botones_.mp3",
    "0011/9960/DES2e_V1_L05_VOC__confirma_reservacion_confirmar_.mp3",
    "0011/9962/DES2e_V1_L05_VOC__el_huesped_.mp3",
    "0011/9963/DES2e_V1_L05_VOC__empleado_.mp3",
    "0011/9965/DES2e_V1_L05_VOC__inspectora_aduanas_.mp3",
    "0011/9968/DES2e_V1_L05_VOC__juegan_cartas_jugar_.mp3",
    "0011/9970/DES2e_V1_L05_VOC__la_huesped_.mp3",
    "0011/9971/DES2e_V1_L05_VOC__llave_.mp3",
    "0011/9972/DES2e_V1_L05_VOC__mar_.mp3",
    "0011/9974/DES2e_V1_L05_VOC__monta_a_caballo_montar_.mp3",
    "0011/9964/DES2e_V1_L05_VOC__habitacion_.mp3",
    "0011/9978/DES2e_V1_L05_VOC__pesca_pescar_.mp3",
    "0011/9980/DES2e_V1_L05_VOC__playa_.mp3",
    "0011/9983/DES2e_V1_L05_VOC__saca_fotos_sacar_toma_fotos_tomar_.mp3",
    "0011/9985/DES2e_V1_L05_VOC__viajero_.mp3",
    "0011/9990/DES2e_V1_L05_VOC__va_barco_ir_.mp3"]
  end

end
