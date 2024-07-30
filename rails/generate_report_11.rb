# Report 11

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  "https://era.library.ualberta.ca/items/#{entity.id}"
end

[Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_11_' + entity_type + '_etd_ms_metadata_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      csv << entity.values_at(entity_attributes) + [get_entity_url(entity)]
    end
  end
end
