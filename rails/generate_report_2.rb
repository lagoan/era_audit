
# Report 2

root_directory = "./era_audit/"

entity_file_types = Set[]

file_name = root_directory + '/report_2_' + 'entity_file_types' + Time.now.to_formatted_s(:number) + '.csv'
    
CSV.open(file_name, 'wb', write_headers: true, headers: ["File types"]) do |csv|
  [Item, Thesis].each do |klass|
    klass.find_each do |entity|
      entity.files.each do |file|
        content_type = file.content_type
        unless entity_file_types.include?(content_type)
          entity_file_types << content_type
          csv << [content_type]
        end
      end
    end
  end
end
