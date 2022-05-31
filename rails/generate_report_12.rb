# Check if meber of path has correct information
missing_community_collection = false
missing_community_collection_report = {community: [], collection: []}

entity.member_of_paths.each do |pair|
  
  community_collection = pair.split('/')
  unless Community.find community_collection[0]
    missing_community_collection_report[:community] << "Community Id %{community_id} does not exist" % {community_id: community_collection[0]}
    missing_community_collection = true
  end

  unless Collection.find community_collection[1]
    missing_community_collection_report[:collection] << "Collection Id %{collection_id} does not exist" % {collection_id: community_collection[1]}
    missing_community_collection = true
  end

end
