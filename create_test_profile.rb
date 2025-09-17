user = User.first
if user.profile.blank?
  Profile.create!(
    user: user,
    first_name: 'John',
    last_name: 'Doe',
    phone_number: '+1234567890',
    bio: 'Experienced real estate agent with over 10 years in the industry. Specializing in luxury homes and investment properties.',
    role: 'agent',
    company_name: 'ABC Realty',
    position: 'Senior Agent',
    years_experience: 10,
    languages: 'English, Spanish',
    address: '123 Main St',
    city: 'New York',
    state: 'NY',
    country: 'USA',
    website: 'https://johndoe.com'
  )
  puts "Profile created for #{user.email}"
else
  puts "Profile already exists for #{user.email}"
end

puts "Profile ID: #{user.profile.id}"