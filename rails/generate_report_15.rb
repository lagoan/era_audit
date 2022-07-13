# Report 15
root_directory = './era_audit/'

def get_collection_url(collection)
  # URL example: https://era.library.ualberta.ca/communities/34de6895-e488-440b-b05c-75efe26c4971/collections/67e0ecb3-05b7-4c9a-bf82-31611e2dc0ce
  format('https://era.library.ualberta.ca/communities/%{community_id}/collections/%{collection_id}',
         community_id: collection.community.id, collection_id: collection.id)
end

file_name = root_directory + '/report_15_' + 'collections_with_5_or_fewer_entities_' + Time.now.to_formatted_s(:number) + '.csv'

CSV.open(file_name, 'wb', write_headers: true, headers: ['Collection title', 'Collection URL', 'id']) do |csv|
  Collection.find_each do |collection|
    csv << [collection.title, get_collection_url(collection), collection.id] unless collection.member_objects.length > 5
  end
end
