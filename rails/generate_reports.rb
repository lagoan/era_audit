class ReportGeneration

  def initialize
    @entity_file_types = Set[]

    @item_attributes = Item.first.attributes.keys
    @thesis_attributes = Thesis.first.attributes.keys   
    # These attributes will be used when we are listing both Item and Thesis in
    # the same CSV file so we have a shared set of columns
    @entity_attributes_intersection = @item_attributes & @thesis_attributes

    initialize_output_files()

  end

  def initialize_output_files
    
    item_headers = @item_attributes.map {|key| Item.rdf_annotation_for_attr(key).present? ? RDF::URI(Item.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
    thesis_headers = @thesis_attributes.map {|key| Thesis.rdf_annotation_for_attr(key).present? ? RDF::URI(Thesis.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
    # The headers for entities are currently not set to their RDF counterparts
    entity_headers = @entity_attributes_intersection

    # Report 1 - Metadata-only records
    @csv_entities_with_metadata_only = CSV.open('entities_with_metadata_only.csv', 'wb',
      write_headers: true,
      headers: entity_headers)

    # Report 2 - List of all file types
    @csv_entity_file_types = CSV.open('entity_file_types.csv', 'wb',
      write_headers: true,
      headers: ["File type"])

    # Report 3 - List of records containing a zipfile
    @csv_entity_with_zip_file = CSV.open('entity_with_zip_file.csv', 'wb',
      write_headers: true,
      headers: entity_headers)

    # Report 4 - List of all multi-file records
    @csv_entities_with_multiple_files = CSV.open('entities_with_multiple_files.csv', 'wb',
      write_headers: true,
      headers: entity_headers)

    # Report 5 is missing - List of all records missing a required metadata field

    # Report 6 - List of all community-collection pairs and all items within collections
    @csv_community_collection_entities = CSV.open('csv_community_collection_entities.csv', 'wb',
      write_headers: true,
      # Custom set of headers to include the actual path, entity type, and the
      # rest of the entity values
      headers: ['Path', 'Type'] + @entity_attributes_intersection)

    # Report 7 - List of all empty collections, listing community-collection pairs
    @csv_community_collection_pair_no_entities = CSV.open('community_collection_pair_no_entities.csv', 'wb',
      write_headers: true,
      headers: ["Community Collection pair"])

    # Report 8 - List of CCID-protected items
    @csv_entities_ccid_protected = CSV.open('entities_ccid_protected.csv', 'wb',
      write_headers: true,
      headers: entity_headers)

    # Report 9 - List of embargoed items including embargo lift date
    @csv_entities_embargoed = CSV.open('entities_embargoed.csv', 'wb',
      write_headers: true,
      headers: entity_headers)
    
    # Report 10 - Items with QDC descriptive metadata
    @csv_entities_with_qdc_metadata = CSV.open('entities_with_qdc_metadata.csv', 'wb',
      write_headers: true,
      headers: item_headers)

    # Report 11 - Items with ETD-MS descriptive metadata
    @csv_entities_with_etd_ms_metadata = CSV.open('entities_with_etd_ms_metadata.csv', 'wb',
      write_headers: true,
      headers: thesis_headers)

  end

  def close_files
    @csv_community_collection_pair_no_entities.close
    @csv_entity_file_types.close
    @csv_entity_with_zip_file.close
    @csv_entities_with_multiple_files.close
    @csv_entities_with_metadata_only.close
    @csv_entities_ccid_protected.close
    @csv_entities_embargoed.close
    @csv_entities_with_qdc_metadata.close
    @csv_entities_with_etd_ms_metadata.close
    @csv_community_collection_entities.close
  end

  def get_item_information(item)
    item.values_at(@item_attributes)
  end

  def get_thesis_information(thesis)
    thesis.values_at(@thesis_attributes)
  end

  def get_entity_information(entity)
    entity.values_at(@entity_attributes_intersection)
  end

  def process_item_entity(entity)
    @csv_entities_with_qdc_metadata << get_item_information(entity)
  end

  def process_thesis_entity(entity)
    @csv_entities_with_etd_ms_metadata << get_thesis_information(entity)
  end

  def process_full_entity_report(entity)
    case entity.class.name
    when 'Item'
      process_item_entity(entity)
    when 'Thesis'
      process_thesis_entity(entity)
    end
  end

  def process_visibility_report(entity)
    @csv_entities_embargoed << get_entity_information(entity) if entity.visibility == JupiterCore::Depositable::VISIBILITY_EMBARGO
    @csv_entities_ccid_protected << get_entity_information(entity) if entity.visibility == JupiterCore::VISIBILITY_AUTHENTICATED
  end

  def process_file_reports(entity)
    entity.files.each do |file|
      content_type = file.content_type
      
      # Report of file types
      unless @entity_file_types.include?(content_type)
        @entity_file_types << content_type
        @csv_entity_file_types << [content_type]
      end

      # Report for number of entities with zip files

      if content_type == 'application/zip'
        @csv_entity_with_zip_file << get_entity_information(entity)
      end
    end

    if entity.files.count > 1
      # Here is a multifile entity
      @csv_entities_with_multiple_files << get_entity_information(entity)
    elsif entity.files.count == 0
      # Entities with just metadata
      @csv_entities_with_metadata_only << get_entity_information(entity)
    end
  end

  def process_entity_reports(entity)
    process_full_entity_report(entity)
    process_file_reports(entity)
    process_visibility_report(entity)
  end

  def run_reports
    Collection.find_each do |collection| 
      if collection.member_objects.size > 0
        collection.member_objects.each do |entity|
          process_entity_reports(entity)
          @csv_community_collection_entities << [collection.path, entity.class.name] + get_entity_information(entity)
        end
      else 
        # The collection is empty so we can add it to the empty community collection report
        @csv_community_collection_pair_no_entities << [collection.path]
      end
    end
    close_files()
  end

end


p = ReportGeneration.new

p.run_reports
