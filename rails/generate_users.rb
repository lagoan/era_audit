# Users

CSV.open('./era_audit/users_report.csv', 'wb', write_headers: true, headers: ['id', 'email']) do |csv|
  User.find_each do |user|
    csv << [user.id, user.email]
  end
end
