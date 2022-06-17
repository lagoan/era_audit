# Report 6

begin
  root_directory = './era_audit/'
  item_headers = Item.first.attributes.keys.map do |key|
    Item.rdf_annotation_for_attr(key).present? ? RDF::URI(Item.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  thesis_headers = Thesis.first.attributes.keys.map do |key|
    Thesis.rdf_annotation_for_attr(key).present? ? RDF::URI(Thesis.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end

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
      Rails.application.routes.url_helpers.collection_url(collection.id),
      collection.path
    ]
  end

  item_csv = CSV.open(
    root_directory + '/report_6_item' + + '_community_collection_' + Time.now.to_formatted_s(:number) + '.csv', 'wb',
    write_headers: true,
    # headers: ['Community Collection pair', 'URL'] + item_headers
    headers: community_collection_headers + ['URL'] + item_headers
  )
  thesis_csv = CSV.open(
    root_directory + '/report_6_thesis' + + '_community_collection' + Time.now.to_formatted_s(:number) + '.csv', 'wb',
    write_headers: true,
    # headers: ['Community Collection pair', 'URL'] + thesis_headers
    headers: community_collection_headers + ['URL'] + thesis_headers
  )

  Collection.find_each do |collection|
    collection.member_objects.each do |entity|
      if entity.instance_of?(Item)
        item_csv << get_community_collection_values(collection) + [get_entity_url(entity)] + entity.values_at(Item.first.attributes.keys)
      elsif entity.instance_of?(Thesis)
        thesis_csv << get_community_collection_values(collection) + [get_entity_url(entity)] + entity.values_at(Thesis.first.attributes.keys)
      end
    end
  end
ensure
  item_csv.close
  thesis_csv.close
end
