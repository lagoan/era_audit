# Report 3

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

compressed_file_types = [
  'application/zip',
  'application/x-7z-compressed',
  'application/gzip',
  'application/x-xz',
  'application/x-rar-compressed;version=5',
  'application/x-tar',
  'application/x-rar'
]

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_3_' + entity_type + '_with_zip_file_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL', 'Files metadata']) do |csv|
    klass.find_each do |entity|
      file_metadata = []

      entity.files.each do |file|
        content_type = file.content_type
        file_metadata << file.blob.to_json if compressed_file_types.include?(content_type)
      end

      csv << entity.values_at(entity_attributes) + [get_entity_url(entity), file_metadata] unless file_metadata.empty?
    end
  end
end
# Report 9

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_9_' + entity_type + '_embargoed_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      if entity.visibility == JupiterCore::Depositable::VISIBILITY_EMBARGO
        csv << entity.values_at(entity_attributes) + [get_entity_url(entity)]
      end
    end
  end
end
# Report 5

root_directory = './era_audit/'
$custom_error_report = { custom: {}, oai: {} }

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

def is_entity_valid?(entity)
  # Clear custom error report so we can use it for each class instance
  $custom_error_report = { custom: {}, oai: {} }

  is_valid = if entity.instance_of?(Item)
               is_item_valid?(entity)
             elsif entity.instance_of?(Thesis)
               is_thesis_valid?(entity)
             end

  # Cleanup unused error messages
  $custom_error_report.delete(:custom) if $custom_error_report[:custom].length.zero?
  $custom_error_report.delete(:oai) if $custom_error_report[:oai].length.zero?

  is_valid
end

def is_item_valid?(entity)
  valid = true
  # creator - Checked by system
  # subject - Checked by system
  # created - Checked by system
  # language - Checked by system
  # title - Checked by system
  # entity_errors[:manual] = {} unless entity_errors[:manual]

  # type item_type - Checked by system
  # rights - Checked by system
  # Other required fields:
  #   doi (not user-supplied, created by Jupiter when item is deposited)

  unless entity.doi.present?
    $custom_error_report[:doi] = ["cant' be blank"]
    valid = false
  end

  #   Checked by system
  #   sortYear - this was not required by metadata but needed for UI faceting I think (not user-supplied but rather derived from created date)

  #   Checked by system
  #   memberOf (community_id, collection_id)

  #   visibility (before I think this was called status, i.e. published, draft).
  unless entity.visibility.present?
    $custom_error_report[:visibility] = ["cant' be blank"]
    valid = false
  end

  valid
end

def is_thesis_valid?(entity)
  valid = true
  # entity_errors[:manual] = {} unless entity_errors[:manual]
  # title - Checked by system
  # dissertant (not used for items) - Checked by system
  # graduationDate (not used for items) - Checked by system
  # abstract (not required for items)
  unless entity.abstract.present?
    $custom_error_report[:custom][:abstract] = ["cant' be blank"]
    valid = false
  end

  # type (always set to Thesis, I think)
  # Could not find on model

  # Other required fields are:
  # Checked by system
  #   memberOf (community_id, collection_id)
  # Checked by system
  #   sortYear (derived from graduationDate)
  # Other fields that are not required by Jupiter or by our model but that are required for sharing metadata in ETD-ms format (e.g. via OAI for Library and Archives - Theses Canada) and very often requested by departments or other parties:
  #   Degree (required for ETD-ms)
  unless entity.degree.present?
    $custom_error_report[:oai][:degree] = ["cant' be blank"]
    valid = false
  end

  #   Institution (required for ETD-ms)
  unless entity.institution.present?
    $custom_error_report[:oai][:institution] = ["cant' be blank"]
    valid = false
  end
  # A draft thesis has this value as degree_level, when it is not a draft it is thesis level
  #   Degree level -----
  unless entity.thesis_level.present?
    $custom_error_report[:oai][:thesis_level] = ["cant' be blank"]
    valid = false
  end
  #   Departments -----
  unless entity.departments.present?
    $custom_error_report[:oai][:departments] = ["cant' be blank"]
    valid = false
  end
  #   Supervisor / Co-supervisor
  unless entity.supervisors.present?
    $custom_error_report[:oai][:supervisors] = ["cant' be blank"]
    valid = false
  end

  valid
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_5_' + entity_type + '_missing_required_metadata_field_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + %w[Errors URL]) do |csv|
    klass.find_each do |entity|
      error_report = {}
      rails_valid = entity.valid?
      additional_valid = is_entity_valid?(entity)

      # entity.valid?
      error_report[:rails_validation] = entity.errors.messages unless rails_valid

      error_report[:additional_validation] = $custom_error_report unless additional_valid

      unless rails_valid && additional_valid
        csv << entity.values_at(entity_attributes) + [error_report.to_json, get_entity_url(entity)]
      end
    end
  end
end
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
# Report 17
root_directory = './era_audit/'

def get_community_url(community)
  # URL example: https://era.library.ualberta.ca/communities/d1640717-da95-4963-9242-68065fece5f4
  format('https://era.library.ualberta.ca/communities/%{id}', id: community.id)
end

file_name = root_directory + '/report_17_' + 'communities_with_no_collections_' + Time.now.to_formatted_s(:number) + '.csv'

CSV.open(file_name, 'wb', write_headers: true, headers: ['Community title', 'Community URL', 'id']) do |csv|
  Community.find_each do |community|
    csv << [community.title, get_community_url(community), community.id] unless community.collections.present?
  end
end
# Report 16
root_directory = './era_audit/'

def get_collection_url(collection)
  # URL example: https://era.library.ualberta.ca/communities/34de6895-e488-440b-b05c-75efe26c4971/collections/67e0ecb3-05b7-4c9a-bf82-31611e2dc0ce
  format('https://era.library.ualberta.ca/communities/%{community_id}/collections/%{collection_id}',
         community_id: collection.community.id, collection_id: collection.id)
end

file_name = root_directory + '/report_16_' + 'collections_with_no_description_' + Time.now.to_formatted_s(:number) + '.csv'

CSV.open(file_name, 'wb', write_headers: true, headers: ['Collection title', 'Collection URL', 'id']) do |csv|
  Collection.where(description: ['', nil]).in_batches do |group|
    group.each do |collection|
      csv << [collection.title, get_collection_url(collection), collection.id]
    end
  end
end
# root_directory = './era_audit/'

# file_name = ''

# CSV.open(file_name, 'wb', write_headers: true, headers: ['Testing']]) do |csv|

#   ActiveStorage::Attachment.find_each
# FileSet.find_each do |file_set|

# end# Report 13
root_directory = './era_audit/'

def get_community_url(community)
  # URL example: https://era.library.ualberta.ca/communities/d1640714-da95-4963-9242-68065fece5f4
  format('https://era.library.ualberta.ca/communities/%{id}', id: community.id)
end

file_name = root_directory + '/report_13_' + 'communities_with_no_description_' + Time.now.to_formatted_s(:number) + '.csv'

CSV.open(file_name, 'wb', write_headers: true, headers: ['Community title', 'Community URL', 'id']) do |csv|
  Community.where(description: ['', nil]).in_batches do |group|
    group.each do |community|
      csv << [community.title, get_community_url(community), community.id]
    end
  end
end
# Report 1

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_1_' + entity_type + '_with_metadata_only_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      csv << entity.values_at(entity_attributes) + [get_entity_url(entity)] if entity.files.count.zero?
    end
  end
end
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
# Report 10

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Item].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_10_' + entity_type + '_qdc_metadata_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      csv << entity.values_at(entity_attributes) + [get_entity_url(entity)]
    end
  end
end
# Report 12
root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
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
# Report 4

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_4_' + entity_type + '_with_multiple_files_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL', 'Files metadata']) do |csv|
    klass.find_each do |entity|
      if entity.files.count > 1
        files_metadata = []
        entity.files.each do |file|
          files_metadata << file.blob.to_json
        end
        csv << entity.values_at(entity_attributes) + [get_entity_url(entity), files_metadata]
      end
    end
  end
end
# Report 2

root_directory = './era_audit/'

entity_file_types = {}

file_name = root_directory + '/report_2_' + 'entity_file_types' + Time.now.to_formatted_s(:number) + '.csv'

[Item, Thesis].each do |klass|
  klass.find_each do |entity|
    entity.files.each do |file|
      content_type = file.content_type
      entity_file_types[content_type] = 0 unless entity_file_types.include?(content_type)
      entity_file_types[content_type] += 1
    end
  end
end

CSV.open(file_name, 'wb', write_headers: true, headers: ['File types', 'Count']) do |csv|
  entity_file_types.each do |content_type, count|
    csv << [content_type, count]
  end
end
# Report 11

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_11_' + entity_type + '_etd_ms_metadata_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      csv << entity.values_at(entity_attributes) + [get_entity_url(entity)]
    end
  end
end
# Report 8

root_directory = './era_audit/'

def get_entity_url(entity)
  # Example
  # https://era.library.ualberta.ca/items/864711f5-3021-455d-9483-9ce956ee4e78
  format('https://era.library.ualberta.ca/%{entity_type}/%{entity_id}', entity_type: entity.class.table_name,
                                                                        entity_id: entity.id)
end

[Item, Thesis].each do |klass|
  entity_type = klass.name.underscore
  entity_attributes = klass.first.attributes.keys
  entity_headers = entity_attributes.map do |key|
    klass.rdf_annotation_for_attr(key).present? ? RDF::URI(klass.rdf_annotation_for_attr(key).first.predicate).pname.to_s : key
  end
  file_name = root_directory + '/report_8_' + entity_type + '_ccid_protected_' + Time.now.to_formatted_s(:number) + '.csv'
  CSV.open(file_name, 'wb', write_headers: true, headers: entity_headers + ['URL']) do |csv|
    klass.find_each do |entity|
      if entity.visibility == JupiterCore::VISIBILITY_AUTHENTICATED
        csv << entity.values_at(entity_attributes) + [get_entity_url(entity)]
      end
    end
  end
end
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
      Rails.application.routes.url_helpers.community_collection_url(community.id, collection.id),
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
# Report 14
root_directory = './era_audit/'

def get_community_url(community)
  # URL example: https://era.library.ualberta.ca/communities/d1640714-da95-4963-9242-68065fece5f4
  format('https://era.library.ualberta.ca/communities/%{id}', id: community.id)
end

file_name = root_directory + '/report_14_' + 'communities_with_no_logo_' + Time.now.to_formatted_s(:number) + '.csv'

CSV.open(file_name, 'wb', write_headers: true, headers: ['Community title', 'Community URL', 'id']) do |csv|
  Community.find_each do |community|
    csv << [community.title, get_community_url(community), community.id] unless community.logo.attached?
  end
end
