module LiveData
  class ContentStats
    attr_reader :program

    def initialize(program_id)
      begin
        @program = Program.find(program_id)
      rescue
        puts "Invalid Program id #{program_id}"
        exit
      end
    end

    def export
      output_file do |f|
        f << csv_header
        f << program_content
        f.close
        puts "Program #{program.title} stats can be found in file #{file_path}" 
      end
    end

    def file_path
      @file_path ||= "#{Rails.root}/tmp/program_#{program.id}_#{Time.now.to_i}.csv"
    end

    def output_file(&blk)
      begin 
        @file = File.open(file_path, "w+")
      rescue
        puts "Unable to create output file #{file_path}"
      end
      yield(@file)
    end

    def program_content
      program.activities(nil).sort.collect { |a| 
                                      [
                                        safe_method_handler(a.lesson,'lesson_name'),
                                        safe_method_handler(a,'strand'),
                                        safe_method_handler(a,'sub_strand'),
                                        a.component,
                                        safe_method_handler(a,'title'),
                                        a.activity_type,
                                        a.id,
                                        a.cms_activity_id,
                                        safe_method_handler(a,'icon'),
                                        a.submittable ? "Y" : "N",
                                        safe_method_handler(a,'direction_line'),
                                        safe_method_handler(a,'items')
                                      ].join(",") if valid?(a)
      }.compact.join("\n")
    end

    def valid?(obj)
      obj.listed? && !obj.assessment?
    end

    def csv_header
      "Lesson, Strand, Substrand, Component, Activity Name, Activity Type, M3 Activity Id, CMS Actvity Id, Properties (Icons), Submittable, Direction Line, Number of Items\n"
    end

    def csvize(data)
      data.gsub(/,/,' ').strip_tags.html_decode.strip.squeeze
    end

    def safe_method_handler(obj, action)
      ret = " "
      begin
        case action
        when 'lesson_name'
          ret = csvize(obj.name)
        when 'title'
          ret = csvize(obj.title)
        when 'strand'
          ret = csvize(obj.strand.name)
        when 'sub_strand'
          ret = csvize(obj.sub_strand.name) if obj.sub_strand
        when 'icon'
          ret = obj.icon.gsub(/,/,' ')
        when 'direction_line'
          ret = csvize(obj.direction_line)
        when 'items'
          ret = obj.items_count
        end
      rescue
        p "Error in getting #{action} for #{obj.id} , #{get_description(obj)}" 
      end
      ret
    end


    def get_description(obj)
      return obj.title if obj.respond_to?(:title)
      return obj.name if obj.respond_to?(:name)
      obj.class 
    end

  end
end
