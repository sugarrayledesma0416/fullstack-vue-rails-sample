module StandardsMapping
  class StandardsProcessor
    attr_reader :standards, :ab_client
    attr_accessor :errors

    ENDS_IN_CHARACTER = /[a-zA-Z]+$/
    ENDS_IN_ELLIPSIS = /(.*([.]{3}|…))$/

      def initialize
      @standards = []
      @ab_client = MaestroActivityEngine::ABConnect::Client.new
      @errors = []
    end

    def save_process
      # fetch_all_standards method returns a batch of standards
      # base based on a defined limit of 100 standard per batch.
      standards_content = @ab_client.fetch_all_standards(0, 100)
      @count = standards_content['meta']['count']
      @limit = standards_content['meta']['limit']
      fetch_next_batch(standards_content)

      @standards.each do |standard|
        Rails.logger.info "Starting standards load of #{@standards.size} standards"
        p "Starting standards load of #{@standards.size} standards"

        attributes = standard['attributes']
        document = attributes['document']

        ancestors = standard['relationships']['ancestors']['data'].map do |data|
          data['id']
        end.join(',')

        children = standard['relationships']['children']['data'].map do |data|
          data['id']
        end.join(',')

        additional_info = {
          additional_info: {
            ancestors: ancestors,
            children: children,
            grade_levels: attributes['education_levels']['grades'].map { |grade| grade['code'] }.join(','),
            parent_guid: standard['relationships']['parent']['data']['id'] || ''
          }
        }

        Rails.logger.info "Saving standard with guid: #{attributes['guid']}"
        p "Saving standard with guid: #{attributes['guid']}"

        save_standard_set_record(document)
        Rails.logger.info "Standard set with guid: #{document['guid']} was saved successfully."
        save_standard_record(attributes, document, additional_info)
        Rails.logger.info "Standard with guid: #{attributes['guid']} was saved successfully."
      end
    end

    def number_standards(vendor_standard_set_guid)
      unnumbered = Standard.where(number:'', vendor_standard_set_guid: vendor_standard_set_guid)
      puts "StandardSet vendor_guid: #{vendor_standard_set_guid} has #{unnumbered.count} unnumbered Standards"
      Rails.logger.info "StandardSet vendor_guid: #{vendor_standard_set_guid} has #{unnumbered.count} unnumbered Standards"
      @children_processed_list = []
      unnumbered.map do |std|
        number_unnumbered_std(std)
      end
    end

    # find all standards that do not end with a number;
    # for each, find all the children and prepend the parent's
    # description onto each child's
    def prepend_parent_description(vendor_standard_set_guid)
      parent_standards = Standard.where(vendor_standard_set_guid: vendor_standard_set_guid)
      parent_standards.map do |parent|
        # find the ones whose number ends with a character,
        # not an integer
        if parent.number =~ ENDS_IN_CHARACTER
          parent_add_info = JSON.parse(parent.additional_info, symbolize_names: true)
          children_guids = parent_add_info[:additional_info][:children].split(',')
          children_guids.map do |child_guid|
            child = Standard.where(vendor_guid: child_guid).first
            new_parent_descr = parent.description
            if parent.description =~ ENDS_IN_ELLIPSIS
              # remove the ellipsis character
              new_parent_descr = parent.description[0..parent.description.length-2]
            else
              new_parent_descr = parent.description
            end
            puts "Child vendor_guid: #{child_guid} old description: #{child.description}"
            Rails.logger.info "Child vendor_guid: #{child_guid} old description: #{child.description}"
            child.description = new_parent_descr + ' ' + child.description.downcase
            puts "New description: #{child.description}"
            Rails.logger.info "New description: #{child.description}"
            child.save
          end
        end
      end
    end

    # if a child node is a leaf node, append its description to its parent
    # and make it unsearchable - this was written for WIDA but we pass in the std set
    # in case there is occasion to use it for other std sets
    def append_leaf_node_descriptions(vendor_std_set_guid)
      parent_standards = Standard.where(vendor_standard_set_guid: vendor_std_set_guid)
      parent_standards.map do |parent|
        parent_add_info = JSON.parse(parent.additional_info, symbolize_names: true)
        children_guids = parent_add_info[:additional_info][:children].split(',')
        total_count = children_guids.count
        count = 0
        children_guids.map do |child_guid|
          child = Standard.where(vendor_guid: child_guid).first
          if !have_children?(child)
            if count == 0
              parent.description = parent.description + ' through:'
            end
            parent.description = parent.description + ' ' + child.description.downcase + ';'
            child.searchable = false
            child.save
            count = count + 1
            if count == total_count
              # replace semicolon at the end with a period
              parent.description = parent.description[0..parent.description.length-2]
              parent.description = parent.description + '.'
              parent.save
            end
          end
        end
      end
    end

    # Fetches the IDs of all leaf node child standards for a given vendor standard set GUID.
    # Returns an array of IDs for the leaf node standards.
    def fetch_leaf_node_child_ids(vendor_std_set_guid)
      leaf_node_child_ids = []
      parent_standards = Standard.where(vendor_standard_set_guid: vendor_std_set_guid)
      parent_standards.map do |parent|
        parent_add_info = JSON.parse(parent.additional_info, symbolize_names: true)
        children_guids = parent_add_info[:additional_info][:children].split(',')
        children_guids.map do |child_guid|
          child = Standard.where(vendor_guid: child_guid).first
          leaf_node_child_ids << child.id unless have_children?(child)
        end
      end
      leaf_node_child_ids
    end

      private def have_children?(standard)
        add_info = JSON.parse(standard.additional_info, symbolize_names: true)
        children_guids = add_info[:additional_info][:children].split(',')
        children_guids.any?
      end


    private def number_unnumbered_std(std)
      return if std.additional_info.empty?

      additional_info = JSON.parse(std.additional_info, symbolize_names: true)
      parent = Standard.where(vendor_guid: additional_info[:additional_info][:parent_guid]).first
      return if @children_processed_list.include?(parent.vendor_guid)
      if parent.number == ''
        number_unnumbered_std(parent)
        parent.reload
          if parent.number == ''
            throw StandardError
          end
        end
      parent_add_info = JSON.parse(parent.additional_info, symbolize_names: true)
      children_guids = parent_add_info[:additional_info][:children].split(',')
      count = 1
      puts "Processing children of Parent number: #{parent.number} id: #{parent.id} vendor_guid: #{parent.vendor_guid}"
      Rails.logger.info "Processing children of Parent number: #{parent.number} id: #{parent.id} vendor_guid: #{parent.vendor_guid}"
      children_guids.map do |child_guid|
        child = Standard.where(vendor_guid: child_guid).first
        # skip if child already has a number
        next if child.number != ''
        child.number = parent.number + ".#{count}"
        puts "Child id #{child.id } vendor_guid: #{child_guid} new number: #{child.number}"
        Rails.logger.info "Child id #{child.id } vendor_guid: #{child_guid} new number: #{child.number}"
        child.save
        count = count + 1
      end
      @children_processed_list << parent.vendor_guid
    end

    private def save_standard_record(attributes, document, additional_info)
      # check if standard exists, if so then update all relevant fields
      standard = Standard.where(vendor_guid: attributes['guid'])&.first
      if standard
        verb = 'updated'
        standard.name = document['descr']
        standard.description = attributes['statement']['descr']
        standard.label = attributes['label']
        standard.number = attributes['number']['enhanced']
        standard.additional_info = additional_info.to_json
        standard.save!
      else
        verb = 'saved'
        Standard.new(
          vendor_guid: attributes['guid'],
          vendor_standard_set_guid: document['guid'],
          name: document['descr'],
          description: attributes['statement']['descr'],
          label: attributes['label'],
          number: attributes['number']['enhanced'],
          additional_info: additional_info.to_json
        ).save!
      end
    rescue ActiveRecord::RecordNotSaved
      error_msg = "Standard with guid: #{attributes['guid']} could not be #{verb}."
      report_error(error_msg)
    rescue ActiveRecord::RecordInvalid => e
      error_msg =  "Standard with guid: #{attributes['guid']} has an error. #{e.message}"
      report_error(error_msg)
    end

    private def save_standard_set_record(document)
      return if StandardSet.find_by(vendor_guid: document['guid'])

      begin
        StandardSet.new(
          vendor_guid: document['guid'],
          issuer: document['publication']['authorities'].first['descr'],
          name: document['descr'],
          adopt_year: document['adopt_year'],
          state: document['publication']['regions'].map { |region| region['code'] }.join(','),
          acronym: document['publication']['acronym'],
          description: document['publication']['descr']
        ).save!
      rescue ActiveRecord::RecordNotSaved
        error_msg = "Standard set with guid: #{document['guid']} could not be saved."
        report_error(error_msg)
      rescue ActiveRecord::RecordInvalid => e
        error_msg = "Standard set with guid: #{document['guid']} has an error. #{e.message}"
        report_error(error_msg)
      end
    end

    private def fetch_next_batch(standards_content)
      if standards_content['errors'].nil?
        @standards += standards_content['data']
        @offset = standards_content['meta']['offset']

        if @offset < @count
          @offset += @limit
          standards_content = @ab_client.fetch_all_standards(@offset, @limit)
          fetch_next_batch(standards_content)
        end
      else
        error_msg = "there was an error calling the API #{standards_content['errors']}"
        report_error(error_msg)
      end
    end

    private def report_error(error_msg)
      Rails.logger.error(error_msg)
      p error_msg
      errors << error_msg
      end
  end
end
