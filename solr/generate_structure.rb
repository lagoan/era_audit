#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'byebug'
require 'logger'
require 'set'

# file = File.open('generator.log', File::WRONLY | File::APPEND | File::CREAT)
# logger = Logger.new(file)
logger = Logger.new($stdout)

# Load Community, Collection, Item, Thesis, Filesets seperatedly
# and add to hash by id

data = {
  communities: {},
  collections: {},
  items: {},
  theses: {},
  # entities: {},
  filesets: {}
}

files = {
  communities: 'all_communities.csv',
  collections: 'all_collections.csv',
  items: 'reports/report_10.csv',
  theses: 'reports/report_11.csv',
  filesets: 'all_filesets.csv'
}

# relations = {
#   community_collection: {},
#   # Merging items and thesis for simplicity
#   collection_item: {},
#   item_fileset: {}
# }

data.each_key do |key|
  logger.info("Loading #{key}")
  CSV.foreach(files[key], headers: true) do |row|
    data[key][row['id']] = row
  end
end

logger.info('Merging items and theses into entities')

data[:communities].each_value do |community|
  community[:collections] = {}
end

data[:collections].each_value do |collection|
  collection[:items] = {}
  collection[:theses] = {}
  collection[:entities] = {}
end

data[:entities] = data[:items].merge(data[:theses])

data[:entities].each_value do |entity|
  entity[:filesets] = {}
end

# Create relations
# byebug
logger.info('Linking communities and collections')
data[:collections].each_value do |collection|
  community = data[:communities][collection['community_id_dpsim']]
  community[:collections][collection['id']] = collection
end

# Merge items and thesis
logger.info('Linking communities and items/theses')
def add_entities_to_collections(entity_type, data)
  CSV.open("reports/report_12_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
    data[entity_type.to_sym].each_value do |entity|
      multiple_collections = entity['member_of_paths_dpsim'].split(',')
      multiple_collections.each do |pair|
        collection_id = pair.split('/')[1]
        collection = data[:collections][collection_id]
        # Here we have to question if we found the collection because at least one
        # collection is missing
        if collection
          collection[entity_type.to_sym][entity['id']] = entity
          collection[:entities][entity['id']] = entity
        else
          csv << [entity['id']]
        end
      end
    end
  end
end

logger.info('Generating report 12')
add_entities_to_collections('items', data)
add_entities_to_collections('theses', data)
# data[:theses].each_value do |item|
#   collection_id = item['member_of_paths_dpsim'].split('/')[1]
#   relations[:collection_item][collection_id] = item['id']
# end

logger.info('Linking items and filesets')
data[:filesets].each_value do |fileset|
  entity_id = fileset['item_tesim']
  entity = data[:entities][entity_id]

  next unless entity

  entity[:filesets][fileset['id']] = fileset
  # Ignoring filesets with no existing item as they may be coming from other sources
  # else
  #   logger.error("Found a fileset #{fileset['id']} with a non existing item #{entity_id}")
  #   logger.error(fileset.inspect)
  # relations[:item_fileset][fileset['item_tesim']] = fileset['id']
end

# + Report 1: Metadata only records

def get_report_1(entity_type, data)
  CSV.open("reports/report_1_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
    data[entity_type.to_sym].each_value do |entity|
      csv << [entity['id']] if entity[:filesets].count.zero?
    end
  end
end

logger.info('Generating report 1')
get_report_1('items', data)
get_report_1('theses', data)

# + Report 2: List of file types
logger.info('Generating report 2')
def get_report_2(data)
  file_types = Set.new
  CSV.open('reports/report_2.csv', 'wb', write_headers: true, headers: ['File types']) do |csv|
    data[:entities].each_value do |entity|
      entity[:filesets].each_value do |fileset|
        m = fileset['sitemap_link_ssim'].match(/.+type="(.*)".+/)

        if m.captures.count.zero?
          logger.warn('Found fileset without type')
        else
          unless file_types.include?(m[1])
            csv << [m[1]]
            file_types << m[1]
          end
        end
      end
    end
  end
end

get_report_2(data)

# + Report 3: List of records containing compressed files

def get_report_3(entity_type, data)
  compressed_file_types = [
    'application/zip',
    'application/x-7z-compressed',
    'application/gzip',
    'application/x-xz',
    'application/x-rar-compressed;version=5',
    'application/x-tar',
    'application/x-rar'
  ]

  CSV.open("reports/report_3_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
    data[entity_type.to_sym].each_value do |entity|
      catch :found_compressed_file do
        entity[:filesets].each_value do |fileset|
          m = fileset['sitemap_link_ssim'].match(/.+type="(.*)".+/)
          # ^.+type=\\?"(.+)\\"?.+?$
          # m = fileset['sitemap_link_ssim'].match(/^.+type=\\?"(.+)\\"?.+?$/)
          # m = fileset['sitemap_link_ssim'].match(/^.+type="(.+)".+$/)

          if !m.captures.count.zero? && compressed_file_types.include?(m[1])
            csv << [entity['id']]
            throw :found_compressed_file
          end
        end
      end
    end
  end
end

logger.info('Generating report 3')
get_report_3('items', data)
get_report_3('theses', data)

# + Report 4: List of all multi file records
# 00008f02-90ff-47b9-bc41-a88293393ce2 missing from solr
def get_report_4(entity_type, data)
  CSV.open("reports/report_4_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
    # byebug
    data[entity_type.to_sym].each_value do |entity|
      csv << [entity['id']] if entity[:filesets].count > 1
    end
  end
end

logger.info('Generating report 4')
get_report_4('items', data)
get_report_4('theses', data)

# + Report 5(MISSING): List of records missing a required metadata field

logger.info('Missing report 5')

# + Report 6: List of all community-collection pairs and all items within collections

def get_report_6(entity_type, data)
  CSV.open("reports/report_6_#{entity_type}.csv", 'wb', write_headers: true,
                                                        headers: ['community id', 'collection id', 'id']) do |csv|
    data[:communities].each_value do |community|
      # byebug
      community[:collections].each_value do |collection|
        collection[entity_type.to_sym].each_value do |entity|
          csv << [community['id'], collection['id'], entity['id']]
        end
      end
    end
  end
end

logger.info('Generating report 6')
get_report_6('items', data)
get_report_6('theses', data)

# + Report 7: List of all empty collections, listing community-collection pairs

def get_report_7(data)
  CSV.open('reports/report_7.csv',
           'wb',
           write_headers: true,
           headers: ['community id', 'collection id', 'Community Collection pair']) do |csv|
    data[:communities].each_value do |community|
      community[:collections].each_value do |collection|
        pair = "#{community['id']}/#{collection['id']}"
        csv << [community['id'], collection['id'], pair] if collection[:entities].count.zero?
      end
    end
  end
end

logger.info('Generating report 7')
get_report_7(data)

# + Report 8: List CCID-protected items

# def get_report_8(entity_type, data)
#   # visibility_ssim:%22http://terms.library.ualberta.ca/authenticated
#   CSV.open("reports/report_8_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[entity_type.to_sym].each_value do |entity|
#       csv << [entity['id']] if entity['visibility_ssim'] == 'http://terms.library.ualberta.ca/authenticated'
#     end
#   end
# end

# logger.info('Generating report 8')
# get_report_8('items', data)
# get_report_8('theses', data)

# + Report 9: List of embargoed items including embargo lift date

# def get_report_9(entity_type, data)
#   # http://terms.library.ualberta.ca/embargo
#   CSV.open("reports/report_9_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[entity_type.to_sym].each_value do |entity|
#       csv << [entity['id']] if entity['visibility_ssim'] == 'http://terms.library.ualberta.ca/embargo'
#     end
#   end
# end

# logger.info('Generating report 9')
# get_report_9('items', data)
# get_report_9('theses', data)

# + Report 10: Items with QDC descriptive metadata

# def get_report_10(data)
#   CSV.open("reports/report_10.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[:items].each_value do |entity|
#       csv << [entity['id']]
#     end
#   end
# end

logger.info('Skipping report 8')
logger.info('Skipping report 9')
logger.info('Skipping report 10')
logger.info('Skipping report 11')

# logger.info("Generating report 10")
# get_report_10(data)

# # + Report 11: Items with ETD-MS descriptive metadata
# def get_report_11(data)
#   CSV.open("reports/report_10.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[:theses].each_value do |entity|
#       csv << [entity['id']]
#     end
#   end
# end

# logger.info("Generating report 11")
# get_report_11(data)

# + Report 12: Items with community-collection path that does not exist

# def get_report_12(entity_type, data)
#   CSV.open("reports/report_12_#{entity_type}.csv", 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[entity_type.to_sym].each_value do |entity|
#       # Check errors
#     end
#   end
# end

# logger.info('Missing report 12')

# + Report 13: List of communities with no description (community name, URL)

# def get_report_13(data)
#   CSV.open('reports/report_13.csv', 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[:communities].each_value do |community|
#       csv << [community['id']] if community['description_tesim'].nil? || community['description_tesim'].empty?
#     end
#   end
# end

logger.info('Skipping report 13')
# logger.info('Generating report 13')
# get_report_13(data)

# + Report 14: List of communities with no logo image (community name, URL)
# Solr index does not include logo information

# + Report 15: List of collections with 5 or fewer items (collection name, URL)

def get_report_15(data)
  CSV.open('reports/report_15.csv', 'wb', write_headers: true, headers: ['id']) do |csv|
    data[:collections].each_value do |collection|
      csv << [collection['id']] if collection[:entities].count <= 5
    end
  end
end

logger.info('Generating report 15')
get_report_15(data)

# + Report 16: List of collections with no description (collection name, URL)

# def get_report_16(data)
#   CSV.open('reports/report_16.csv', 'wb', write_headers: true, headers: ['id']) do |csv|
#     data[:collections].each_value do |collection|
#       csv << [collection['id']] if collection['description_tesim'].nil? || collection['description_tesim'].empty?
#     end
#   end
# end

# logger.info('Generating report 16')
# get_report_16(data)

logger.info('Skipping 16')

# + Report 17: List of communities with no collections (community name, URL)

def get_report_17(data)
  CSV.open('reports/report_17.csv', 'wb', write_headers: true,
                                          headers: ['community id', 'collection id', 'id']) do |csv|
    data[:communities].each_value do |community|
      csv << [community['id']] if community[:collections].count.zero?
    end
  end
end

logger.info('Generating report 17')
get_report_17(data)
