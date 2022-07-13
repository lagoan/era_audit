# Report 13
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
