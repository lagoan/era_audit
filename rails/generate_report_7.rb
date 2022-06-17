# Report 7

root_directory = './era_audit/'

def get_collection_url(collection)
  # URL example: https://era.library.ualberta.ca/communities/34de6895-e488-440b-b05c-75efe26c4971/collections/67e0ecb3-05b7-4c9a-bf82-31611e2dc0ce
  format('https://era.library.ualberta.ca/communities/%{community_id}/collections/%{collection_id}',
         community_id: collection.community.id, collection_id: collection.id)
end

CSV.open(
  root_directory + '/report_7_community_collection_pair_no_entities_' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: [
    'Community Collection pair', 'URL'
  ]
) do |csv|
  Collection.find_each do |collection|
    csv << [collection.path, get_collection_url(collection)] if collection.member_objects.size.zero?
  end
end
