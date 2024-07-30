# Report 3

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  "https://era.library.ualberta.ca/items/#{entity.id}"
end

compressed_file_types = [
  'application/zip',
  'application/x-7z-compressed',
  'application/gzip',
  'application/x-xz',
  'application/x-rar-compressed;version=5',
  'application/x-tar',
  'application/x-rar'
]

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_3_' + entity_type + '_with_zip_file_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL', 'Files metadata']) do |csv|
    klass.find_each do |entity|
      file_metadata = []

      entity.files.each do |file|
        content_type = file.content_type
        file_metadata << file.blob.to_json if compressed_file_types.include?(content_type)
      end

      csv << entity.values_at(entity_attributes) + [get_entity_url(entity), file_metadata] unless file_metadata.empty?
    end
  end
end
