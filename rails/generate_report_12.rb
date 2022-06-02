# Report 12
root_directory = "./era_audit/"

# Check if meber of path has correct information
missing_community_collection = false
missing_community_collection_report = {community: [], collection: []}

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map {|key| klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
  file_name = root_directory + '/report_12_' + entity_type + '_community_collection_pairs_that_dont_exist' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['Community errors', 'Collection errors']) do |csv|
    klass.find_each do |entity|
      entity.member_of_paths.each do |pair|
        missing_community_collection = false
        community_collection = pair.split('/')

        begin 
          Community.find community_collection[0]
        rescue ActiveRecord::RecordNotFound
          missing_community_collection_report[:community] << "Community Id %{community_id} does not exist" % {community_id: community_collection[0]}
          missing_community_collection = true
        end

        begin 
          Collection.find community_collection[1]
        rescue ActiveRecord::RecordNotFound
          missing_community_collection_report[:collection] << "Collection Id %{collection_id} does not exist" % {collection_id: community_collection[1]}
          missing_community_collection = true
        end

        if missing_community_collection
          csv << entity.values_at(entity_attributes) + [missing_community_collection_report[:community].to_json, missing_community_collection_report[:collection].to_json]
        end
      end
    end
  end
end
