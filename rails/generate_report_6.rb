# Report 6

begin
  root_directory = './era_audit/'
  item_headers = Item.first.attributes.keys.map do |key|
    Item.rdf_annotation_for_attr(key).present? ? RDF::URI(Item.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  thesis_headers = Thesis.first.attributes.keys.map do |key|
    Thesis.rdf_annotation_for_attr(key).present? ? RDF::URI(Thesis.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end

  item_csv = CSV.open(
    root_directory + '/report_6_item' + + '_community_collection_' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: [
      'Community Collection pair', 'URL'
    ] + item_headers
  )
  thesis_csv = CSV.open(
    root_directory + '/report_6_thesis' + + '_community_collection' + Time.now.to_formatted_s(:number) + '.csv', 'wb', write_headers: true, headers: [
      'Community Collection pair', 'URL'
    ] + thesis_headers
  )

  def get_collection_url(collection)
    # URL example: https://era.library.ualberta.ca/communities/34de6895-e488-440b-b05c-75efe26c4971/collections/67e0ecb3-05b7-4c9a-bf82-31611e2dc0ce
    format('https://era.library.ualberta.ca/communities/%{community_id}/collections/%{collection_id}',
           community_id: collection.community.id, collection_id: collection.id)
  end

  Collection.find_each do |collection|
    collection.member_objects.each do |entity|
      if entity.instance_of?(Item)
        item_csv << [collection.path, get_entity_url(entity)] + entity.values_at(Item.first.attributes.keys)
      elsif entity.instance_of?(Thesis)
        thesis_csv << [collection.path, get_entity_url(entity)] + entity.values_at(Thesis.first.attributes.keys)
      end
    end
  end
ensure
  item_csv.close
  thesis_csv.close
end
