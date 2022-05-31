
# Report 5

root_directory = "./era_audit/"
$custom_error_report = {custom: {}, oai: {}}

def is_entity_valid?(entity)
  # Clear custom error report so we can use it for each class instance
  $custom_error_report = {custom: {}, oai: {}}


  is_valid = if entity.class == Item
    is_item_valid?(entity)
  elsif entity.class == Thesis
    is_thesis_valid?(entity)
  end

  # Cleanup unused error messages
  $custom_error_report.delete(:custom) if $custom_error_report[:custom].length == 0
  $custom_error_report.delete(:oai) if $custom_error_report[:oai].length == 0

  is_valid

end

def is_item_valid?(entity)
  valid = true
    # creator - Checked by system
    # subject - Checked by system
    # created - Checked by system
    # language - Checked by system
    # title - Checked by system
    # entity_errors[:manual] = {} unless entity_errors[:manual]

    # type item_type - Checked by system
    # rights - Checked by system
    # Other required fields:
    #   doi (not user-supplied, created by Jupiter when item is deposited)

    unless entity.doi.present?
      $custom_error_report[:doi] = ["cant' be blank"]
      valid = false
    end

    #   Checked by system
    #   sortYear - this was not required by metadata but needed for UI faceting I think (not user-supplied but rather derived from created date)
    
    #   Checked by system
    #   memberOf (community_id, collection_id)


    #   visibility (before I think this was called status, i.e. published, draft).
    unless entity.visibility.present?
      $custom_error_report[:visibility] = ["cant' be blank"]
      valid = false
    end

    valid
  
end

def is_thesis_valid?(entity)
  valid = true
  # entity_errors[:manual] = {} unless entity_errors[:manual]
  # title - Checked by system
  # dissertant (not used for items) - Checked by system
  # graduationDate (not used for items) - Checked by system
  # abstract (not required for items)
  unless entity.abstract.present?
    $custom_error_report[:custom][:abstract] = ["cant' be blank"]
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
  unless entity.degree.present?
    $custom_error_report[:oai][:degree] = ["cant' be blank"]
    valid = false
  end

  #   Institution (required for ETD-ms)
  unless entity.institution.present?
    $custom_error_report[:oai][:institution] = ["cant' be blank"]
    valid = false
  end
  # A draft thesis has this value as degree_level, when it is not a draft it is thesis level
  #   Degree level -----
  unless entity.thesis_level.present?
    $custom_error_report[:oai][:thesis_level] = ["cant' be blank"]
    valid = false
  end
  #   Departments -----
  unless entity.departments.present?
    $custom_error_report[:oai][:departments] = ["cant' be blank"]
    valid = false
  end
  #   Supervisor / Co-supervisor
  unless entity.supervisors.present?
    $custom_error_report[:oai][:supervisors] = ["cant' be blank"]
    valid = false
  end

  valid
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map {|key| klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
  file_name = root_directory + '/report_5_' + entity_type + '_missing_required_metadata_field_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['Errors']) do |csv|
    klass.find_each do |entity|
      error_report = {}
      system_valid = entity.valid?
      manual_invalid = is_entity_valid?(entity)

      # entity.valid?
      unless system_valid
        error_report[:system] = entity.errors.messages
      end

      unless manual_invalid
        error_report[:manual] = $custom_error_report
      end

      unless system_valid && manual_invalid
        csv << entity.values_at(entity_attributes) + [error_report.to_json]
      end
      
    end
  end
end
