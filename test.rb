require 'csv'

File.open("test.csv", "r") do |f|
    CSV.foreach(f, :headers => true) do |row|
        u = User.create(email: row[0], name: row[1], password: row[2], password_confirmation: row[3], role: row[4])
        u.save
    end
    # p CSV.read(f)
end
