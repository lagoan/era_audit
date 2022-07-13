#!/usr/bin/env ruby
require 'csv'
require 'logger'
require 'byebug'

def get_id_count_from_path(path, column_comparisson)
  result = {}
  CSV.foreach(path, headers: true) do |row|
    if !result.key?(row[:id])
      result[row[column_comparisson]] = 1
    else
      ``
      result[row[column_comparisson]] += 1
    end
  end

  result
end

logger = Logger.new($stdout)

column_comparisson = ARGV[0]
file_path_1 = ARGV[1]
file_path_2 = ARGV[2]

file_1_ids = get_id_count_from_path(file_path_1, column_comparisson)
file_2_ids = get_id_count_from_path(file_path_2, column_comparisson)

file_1_errors = 0
file_2_errors = 0
count_errors = 0

logger.warn('Different number of ids') unless file_1_ids.length == file_2_ids.length

file_1_ids.each do |id, count|
  unless file_2_ids.key?(id)
    logger.warn(format('File 1 id %<id>s is not on both files', id: id))
    file_1_errors += 1
  end

  next if count == file_2_ids[id]

  logger.warn(format('Key %<id>s does not have the same count: File 1 = %<file_1_count>s - File 2 = %<file_2_count>s',
                     id: id, file_1_count: count, file_2_count: file_2_ids[id]))
  count_errors += 1
end

file_2_ids.each do |id, _count|
  unless file_1_ids.key?(id)
    logger.warn(format('File 2 id %<id>s is not on both files', id: id))
    file_2_errors += 1
  end
end

logger.info("Number of keys on file 1 not present on file 2 #{file_1_errors}")
logger.info("Number of keys on file 2 not present on file 1 #{file_2_errors}")
logger.info("Number of keys with different count on both files #{count_errors}")

# begin
#   csv_file_1 = CSV.open(file_path_1, headers: true, header_converters: :symbol)
#   csv_file_2 = CSV.open(file_path_2, headers: true, header_converters: :symbol)
# ensure
#   csv_file_1.close()
#   csv_file_2.close()
# end
