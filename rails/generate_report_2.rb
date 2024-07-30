# Report 2

root_directory = './era_audit/'

entity_file_types = {}

file_name = root_directory + '/report_2_' + 'entity_file_types_' + Time.now.to_formatted_s(:number) + '.csv'

[Item, Thesis].each do |klass|
  klass.find_each do |entity|
    entity.files.each do |file|
      content_type = file.content_type
      entity_file_types[content_type] = 0 unless entity_file_types.include?(content_type)
      entity_file_types[content_type] += 1
    end
  end
end

CSV.open(file_name, 'wb', write_headers: true, headers: ['File types', 'Count']) do |csv|
  entity_file_types.each do |content_type, count|
    csv << [content_type, count]
  end
end
