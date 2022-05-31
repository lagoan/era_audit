
# Report 6

begin

  root_directory = "./era_audit/"
  item_headers = Item.first.attributes.keys.map {|key| Item.rdf_annotation_for_attr(key).present? ? RDF::URI(Item.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }
  thesis_headers = Thesis.first.attributes.keys.map {|key| Thesis.rdf_annotation_for_attr(key).present? ? RDF::URI(Thesis.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key }

  item_csv = CSV.open(root_directory + '/report_6_item' +  + '_community_collection_' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: ["Community Collection pair"] + item_headers)
  thesis_csv = CSV.open(root_directory + '/report_6_thesis' +  + '_community_collection' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: ["Community Collection pair"] + thesis_headers)

  Collection.find_each do |collection| 
    collection.member_objects.each do |entity|
      if entity.class == Item
        item_csv << [collection.path] + entity.values_at(Item.first.attributes.keys)
      elsif entity.class == Thesis
        thesis_csv << [collection.path] + entity.values_at(Thesis.first.attributes.keys)
      end
    end
  end

ensure
  item_csv.close()
  thesis_csv.close()
end
