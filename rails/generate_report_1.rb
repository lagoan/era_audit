
# Report 1

root_directory = "./era_audit/"

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map {|key| klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
  file_name = root_directory + '/report_1_' + entity_type + '_with_metadata_only_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers) do |csv|
    klass.find_each do |entity|
      if entity.files.count == 0
        csv << entity.values_at(entity_attributes)
      end
    end
  end
end
