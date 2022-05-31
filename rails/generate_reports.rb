# This simple program will create the reports needed for the ERA Audit.
# Be sure to run the code under the sandbox rails console on the production
# environment. You can do this by running the console with the following
# command:
# 
# rails console --sandbox


class EraAuditReportGeneration

  def initialize
    # Use this set to keep track of the file types already found so we don't
    # repeat them on the file types report
    @entity_file_types = Set[]

    @item_attributes = Item.first.attributes.keys
    @thesis_attributes = Thesis.first.attributes.keys
    # Set a default initial entity type value
    @entity_type = :item
    # directory where report files will be saved
    @root_directory = "./era_audit/"

    @processed_entity_count = 0
    @testing = {
      enabled?: false,
      max_entities: 100
    }
    # @curent_entity_errors = {}

  end

  def initialize_output_files

    item_headers = @item_attributes.map {|key| Item.rdf_annotation_for_attr(key).present? ? RDF::URI(Item.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
    thesis_headers = @thesis_attributes.map {|key| Thesis.rdf_annotation_for_attr(key).present? ? RDF::URI(Thesis.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }

    Dir.mkdir(@root_directory) unless File.exists?(@root_directory)

    @log_file = File.open(@root_directory + '/report.log', 'w')

    @report_files = {
      item: get_entity_report_files('item', item_headers),
      thesis: get_entity_report_files('thesis', thesis_headers),
      general:  get_general_report_files()
    }; nil

  end

  def get_entity_report_files(entity_type, entity_headers)
    {
      # Report 1 - Metadata-only records
      metadata_only: CSV.open(@root_directory + '/report_1_' + entity_type + '_with_metadata_only.csv', 'wb', write_headers: true, headers: entity_headers),
      
      # Report 3 - List of records containing a zipfile
      with_zip_file: CSV.open(@root_directory + '/report_3_' + entity_type + '_with_zip_file.csv', 'wb', write_headers: true, headers: entity_headers),
      
      # Report 4 - List of all multi-file records
      with_multiple_files: CSV.open(@root_directory + '/report_4_' + entity_type + '_with_multiple_files.csv', 'wb', write_headers: true, headers: entity_headers),
      
      # Report 5 is missing - List of all records missing a required metadata field
      # Adding column to show rails validation errors
      is_valid: CSV.open(@root_directory + '/report_5_' + entity_type + '_missing_required_metadata_field.csv', 'wb', write_headers: true, headers: entity_headers + ['Errors']),

      # Report 6 - List of all community-collection pairs and all items within collections
      # Custom set of headers to include the actual path, entity type, and the rest of the entity values
      community_collection: CSV.open(@root_directory + '/report_6_' + entity_type + '_community_collection.csv', 'wb', write_headers: true, headers: ['Path', 'Type'] + entity_headers),
      
      # Report 8 - List of CCID-protected entities
      ccid_protected: CSV.open(@root_directory + '/report_8_' + entity_type + '_ccid_protected.csv', 'wb', write_headers: true, headers: entity_headers),
      
      # Report 9 - List of embargoed items including embargo lift date
      embargoed: CSV.open(@root_directory + '/report_9_' + entity_type + '_embargoed.csv', 'wb', write_headers: true, headers: entity_headers),
      
      # Reports 10 and 11
      # Report 10 - Items with QDC descriptive metadata
      # Report 11 - Items with ETD-MS descriptive metadata
      entity_type_metadata: CSV.open(@root_directory + '/report_10_11_' + entity_type + '_specific_metadata.csv', 'wb', write_headers: true, headers: entity_headers)

    }
  end

  def get_general_report_files
    {
      # Report 2 - List of all file types
      file_types: CSV.open(@root_directory + '/report_2_' + 'entity_file_types.csv', 'wb', write_headers: true, headers: ["File type"]),
      
      # Report 7 - List of all empty collections, listing community-collection pairs
      community_collection_pair_no_entities: CSV.open(@root_directory + '/report_7_' + 'community_collection_pair_no_entities.csv', 'wb', write_headers: true, headers: ["Community Collection pair"])      
    }
  end

  def is_entity_valid?

    # if @current_entity.invalid?
    #   @report_files[current_entity_type()][:is_valid] << get_entity_information() + [@current_entity.errors.as_json()]
    # end

    system_validation = @current_entity.valid?
    
    @curent_entity_errors[:system] = @current_entity.errors.messages unless system_validation

    manual_validation = if current_entity_type() == :item
      is_item_valid?()
    elsif current_entity_type() == :thesis
      is_thesis_valid?()
    end

    system_validation && manual_validation

  end

  def is_item_valid?
    
    valid = true
    # creator - Checked by system
    # subject - Checked by system
    # created - Checked by system
    # language - Checked by system
    # title - Checked by system
    # @current_entity_errors[:manual] = {} unless @current_entity_errors[:manual]
    item_errors = {}
    # type item_type - Checked by system
    # rights - Checked by system
    # Other required fields:
    #   doi (not user-supplied, created by Jupiter when item is deposited)

    unless @current_entity.doi.present?
      item_errors[:doi] = ["cant' be blank"]
      valid = false
    end

    #   Checked by system
    #   sortYear - this was not required by metadata but needed for UI faceting I think (not user-supplied but rather derived from created date)
    
    #   Checked by system
    #   memberOf (community_id, collection_id)


    #   visibility (before I think this was called status, i.e. published, draft).
    unless @current_entity.visibility.present?
      item_errors[:visibility] = ["cant' be blank"]
      valid = false
    end
    
    @current_entity_errors[:manual] = item_errors unless valid

    valid
  end

  def is_thesis_valid? 

    valid = true
    thesis_errors = {}
    # @current_entity_errors[:manual] = {} unless @current_entity_errors[:manual]
    # title - Checked by system
    # dissertant (not used for items) - Checked by system
    # graduationDate (not used for items) - Checked by system
    # abstract (not required for items)
    unless @current_entity.abstract.present?
      @log_file.puts('Thesis found blank abstract')
      thesis_errors[:abstract] = ["cant' be blank"]
      valid = false
    end

    # type (always set to Thesis, I think)
    # Could not find on model

    # Other required fields are:
    # Checked by system
    #   memberOf (community_id, collection_id)
    # Checked by system
    #   sortYear (derived from graduationDate)
    # Other fields that are not required by Jupiter or by our model but that are required for sharing metadata in ETD-ms format (e.g. via OAI for Library and Archives - Theses Canada) and very often requested by departments or other parties:
    #   Degree (required for ETD-ms)
    unless @current_entity.degree.present?
      @log_file.puts('Thesis found blank degree')
      thesis_errors[:degree] = ["cant' be blank"]
      valid = false
    end

    #   Institution (required for ETD-ms)
    unless @current_entity.institution.present?
      @log_file.puts('Thesis found blank institution')
      thesis_errors[:institution] = ["cant' be blank"]
      valid = false
    end
    # A draft thesis has this value as degree_level, when it is not a draft it is thesis level
    # XXX Ask Mariana about the current value and if drafts are different from published thesis
    #   Degree level -----
    unless @current_entity.thesis_level.present?
      thesis_errors[:thesis_level] = ["cant' be blank"]
      valid = false
    end
    #   Departments -----
    unless @current_entity.departments.present?
      thesis_errors[:departments] = ["cant' be blank"]
      valid = false
    end
    #   Supervisor / Co-supervisor
    unless @current_entity.supervisors.present?
      thesis_errors[:supervisors] = ["cant' be blank"]
      valid = false
    end

    @current_entity_errors[:manual] = thesis_errors unless valid

    valid
  end

  def close_files
    @log_file.close()
    @report_files.each_value do |report|
      report.each_value do |file|
        file.close() if file
      end
    end
  end

  def get_entity_information
    @current_entity.values_at(current_entity_attributes)
  end

  def process_full_entity_report
    @report_files[current_entity_type()][:entity_type_metadata] << get_entity_information()
  end

  def process_visibility_report
    @report_files[current_entity_type()][:embargoed] << get_entity_information() if @current_entity.visibility == JupiterCore::Depositable::VISIBILITY_EMBARGO
    @report_files[current_entity_type()][:ccid_protected]  << get_entity_information() if @current_entity.visibility == JupiterCore::VISIBILITY_AUTHENTICATED
  end

  def process_file_reports
    @current_entity.files.each do |file|
      content_type = file.content_type
      
      # Report of file types
      unless @entity_file_types.include?(content_type)
        @entity_file_types << content_type
        @report_files[:general][:file_types] << [content_type]
      end

      # Report for number of entities with zip files

      if content_type == 'application/zip'
        @report_files[current_entity_type()][:with_zip_file] << get_entity_information()
      end
    end

    if @current_entity.files.count > 1
      # Here is a multifile entity
      @report_files[current_entity_type()][:with_multiple_files] << get_entity_information()
    elsif @current_entity.files.count == 0
      # Entities with just metadata
      @report_files[current_entity_type()][:metadata_only] << get_entity_information()
    end

    # XXX TODO Validation report goes here
    # if @current_entity.invalid?
    #   @report_files[current_entity_type()][:is_valid] << get_entity_information() + [@current_entity.errors.as_json()]
    # end

    unless is_entity_valid?()
      @report_files[current_entity_type()][:is_valid] << get_entity_information() + [@current_entity_errors.to_json]
    end

  end

  def process_entity_reports()
    process_full_entity_report()
    process_file_reports()
    process_visibility_report()
  end

  def current_entity_type
    @current_entity.class.name.underscore.to_sym
  end

  def current_entity_attributes
    case current_entity_type
    when :item
      @item_attributes
    when :thesis
      @thesis_attributes
    else
      []
    end
  end

  def set_current_entity(entity)
    @current_entity = entity
    @current_entity_errors = {}
  end

  def run_reports

    begin

      initialize_output_files()

      Collection.find_each do |collection| 
        if collection.member_objects.size > 0
          collection.member_objects.each do |entity|
            
            set_current_entity(entity)

            process_entity_reports()
            @report_files[current_entity_type()][:community_collection] << [collection.path, @current_entity.class.name] + get_entity_information()
            @processed_entity_count += 1
            
            if @testing[:enabled?]
              close_files() and return if @processed_entity_count >= @testing[:max_entities]
            end
          end
        else 
          # The collection is empty so we can add it to the empty community collection report
          @report_files[:general][:community_collection_pair_no_entities] << [collection.path]
        end
      end
    rescue TypeError, NameError => e
      puts "Generic error: #{e.message}"
    ensure 
      close_files()
    end
    
  end

  def output_result
    print @processed_entity_count
  end

end

p = EraAuditReportGeneration.new
p.run_reports
p.output_result


