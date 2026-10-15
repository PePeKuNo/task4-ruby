# This file loads the users from users.json into the database
# Run with: rails db:seed

require 'json'

# NOTE: Path to the users.json file
users_file = Rails.root.join('db', 'users.json')

unless File.exist?(users_file)
  puts "ERROR: users.json not found at #{users_file}"
  exit 1
end

# IMPORTANT: Read and parse the JSON file
users_data = JSON.parse(File.read(users_file))

puts "Loading #{users_data.size} users from #{users_file}..."

# NOTE: Track statistics
created_count = 0
skipped_count = 0
error_count = 0

users_data.each do |user_data|
  begin
    # IMPORTANT: Email is the unique identifier - downcase for consistency
    email = user_data['email'].downcase.strip

    # NOTE: Check if user already exists (idempotent seed)
    user = User.find_by(email: email)

    if user
      # Update existing user's attributes
      user.update!(
        full_name: user_data['full_name'],
        job_position: user_data['job_position'],
        last_seen: user_data['last_seen'],
        status: user_data['status']
      )
      skipped_count += 1
    else
      # Create new user with a default password
      # NOTA BENE: Password is 'password123' for all seeded users
      # In production, users would set their own passwords on registration
      User.create!(
        full_name: user_data['full_name'],
        email: email,
        job_position: user_data['job_position'],
        last_seen: user_data['last_seen'],
        status: user_data['status'],
        password: 'password123',
        password_confirmation: 'password123'
      )
      created_count += 1
    end
  rescue ActiveRecord::RecordInvalid => e
    puts "ERROR creating/updating #{user_data['email']}: #{e.message}"
    error_count += 1
  rescue StandardError => e
    puts "UNEXPECTED ERROR with #{user_data['email']}: #{e.message}"
    error_count += 1
  end
end

puts "\n=== Seed Summary ==="
puts "Created:  #{created_count}"
puts "Updated:  #{skipped_count}"
puts "Errors:   #{error_count}"
puts "Total:    #{User.count} users in database"

# IMPORTANT: Verify unique index on email
puts "\n=== Database Index Verification ==="
indexes = ActiveRecord::Base.connection.indexes('users')
email_index = indexes.find { |i| i.columns.include?('email') }
if email_index&.unique
  puts "✓ Unique index on email exists: #{email_index.name}"
else
  puts "✗ WARNING: Unique index on email NOT found!"
end

# Show status distribution
status_counts = User.group(:status).count
puts "\n=== User Status Distribution ==="
status_counts.each { |status, count| puts "#{status.capitalize}: #{count}" }