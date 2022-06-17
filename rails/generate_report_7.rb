# Report 7

root_directory = './era_audit/'


community_collection_headers = [
  'Community title',
  'Community URL',
  'Collection title',
  'Collection URL',
  'Community Collection pair'
]

def get_community_collection_values(collection)
  community = collection.community

  [
    community.title,
    Rails.application.routes.url_helpers.community_url(community.id),
    collection.title,
    Rails.application.routes.url_helpers.community_collection_url(community.id, collection.id),
    collection.path
  ]
end

CSV.open(
  root_directory + '/report_7_community_collection_pair_no_entities_' + Time.now.to_formatted_s(:number) + '.csv', 'wb',
  write_headers: true,
  headers: community_collection_headers
) do |csv|
  Collection.find_each do |collection|
    csv << get_community_collection_values(collection) if collection.member_objects.size.zero?
  end
end
