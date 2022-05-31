
# Report 7

root_directory = "./era_audit/"

CSV.open(root_directory + '/report_7_community_collection_pair_no_entities_' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: ["Community Collection pair"]) do |csv|
  Collection.find_each do |collection| 
    csv << [collection.path] if collection.member_objects.size == 0
  end
end
