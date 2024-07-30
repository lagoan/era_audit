# Report 12
root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  "https://era.library.ualberta.ca/items/#{entity.id}"
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_12_' + entity_type + '_community_collection_pairs_that_dont_exist_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true,
                            headers: entity_headers + ['Community errors', 'Collection errors', 'Pair errors', 'URL']) do |csv|
    klass.find_each do |entity|
      # Check if meber of path has correct information
      missing_community_collection = false
      missing_community_collection_report = { community: [], collection: [], pair: [] }

      entity.member_of_paths.each do |pair|
        missing_community_collection = false
        # When splitting the member of paths pair, the first id is for community
        # and second one is for collection
        community_collection = pair.split('/')

        community = nil
        collection = nil

        begin
          community = Community.find community_collection[0]
        rescue ActiveRecord::RecordNotFound
          missing_community_collection_report[:community] << format('Community Id %{community_id} does not exist',
                                                                    community_id: community_collection[0])
          missing_community_collection = true
        end

        begin
          collection = Collection.find community_collection[1]
        rescue ActiveRecord::RecordNotFound
          missing_community_collection_report[:collection] << format('Collection Id %{collection_id} does not exist',
                                                                     collection_id: community_collection[1])
          missing_community_collection = true
        end

        if community && collection && !(collection.community == community)
          missing_community_collection_report[:pair] << format('Pair %{pair} does not exist', pair: pair)
          missing_community_collection = true
        end

        next unless missing_community_collection

        extra_values = [missing_community_collection_report[:community].join(', '),
                        missing_community_collection_report[:collection].join(', '), missing_community_collection_report[:pair].join(', '), get_entity_url(entity)]
        csv << entity.values_at(entity_attributes) + extra_values
      end
    end
  end
end
