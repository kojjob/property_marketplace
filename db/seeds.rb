# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample users
user1 = User.find_or_create_by!(email_address: 'seller1@example.com') do |user|
  user.password = 'password123'
end

user2 = User.find_or_create_by!(email_address: 'seller2@example.com') do |user|
  user.password = 'password123'
end

buyer = User.find_or_create_by!(email_address: 'buyer@example.com') do |user|
  user.password = 'password123'
end

puts "Created #{User.count} users"

# Create sample properties
properties_data = [
  {
    user: user1,
    title: 'Beautiful 3-Bedroom House in Downtown',
    description: 'This stunning 3-bedroom house features modern amenities, a spacious backyard, and is located in the heart of downtown. Perfect for families looking for convenience and comfort.',
    price: 450000,
    property_type: 'House',
    bedrooms: 3,
    bathrooms: 2,
    square_feet: 2200,
    address: '123 Main Street',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94102',
    status: 'active'
  },
  {
    user: user1,
    title: 'Modern Apartment with City Views',
    description: 'Luxurious apartment on the 15th floor with stunning city views. Features include granite countertops, stainless steel appliances, and in-unit laundry.',
    price: 325000,
    property_type: 'Apartment',
    bedrooms: 2,
    bathrooms: 2,
    square_feet: 1100,
    address: '456 High Street',
    city: 'New York',
    state: 'NY',
    zip_code: '10001',
    status: 'active'
  },
  {
    user: user2,
    title: 'Spacious Condo Near the Beach',
    description: 'Wake up to ocean views in this beautiful beachfront condo. Walking distance to restaurants and shopping. HOA includes pool and gym access.',
    price: 550000,
    property_type: 'Condo',
    bedrooms: 2,
    bathrooms: 2,
    square_feet: 1500,
    address: '789 Ocean Drive',
    city: 'Miami',
    state: 'FL',
    zip_code: '33139',
    status: 'active'
  },
  {
    user: user2,
    title: 'Family-Friendly Townhouse',
    description: 'Perfect for growing families, this townhouse features 4 bedrooms, a modern kitchen, and a private garage. Located in a quiet neighborhood with excellent schools.',
    price: 380000,
    property_type: 'Townhouse',
    bedrooms: 4,
    bathrooms: 3,
    square_feet: 2800,
    address: '321 Elm Street',
    city: 'Austin',
    state: 'TX',
    zip_code: '78701',
    status: 'active'
  },
  {
    user: user1,
    title: 'Investment Opportunity - Commercial Space',
    description: 'Prime commercial real estate in busy shopping district. Currently leased to stable tenant. Great cash flow and appreciation potential.',
    price: 750000,
    property_type: 'Commercial',
    square_feet: 3500,
    address: '555 Commerce Way',
    city: 'Seattle',
    state: 'WA',
    zip_code: '98101',
    status: 'active'
  },
  {
    user: user2,
    title: 'Charming Starter Home',
    description: 'Cozy 2-bedroom house perfect for first-time buyers. Recently renovated kitchen and bathroom. Large fenced backyard.',
    price: 225000,
    property_type: 'House',
    bedrooms: 2,
    bathrooms: 1,
    square_feet: 1200,
    address: '999 Oak Lane',
    city: 'Portland',
    state: 'OR',
    zip_code: '97201',
    status: 'active'
  }
]

properties_data.each do |property_data|
  Property.find_or_create_by!(title: property_data[:title]) do |property|
    property.assign_attributes(property_data)
  end
end

puts "Created #{Property.count} properties"

# Add some favorites
Favorite.find_or_create_by!(user: buyer, property: Property.first)
Favorite.find_or_create_by!(user: buyer, property: Property.third)

puts "Created #{Favorite.count} favorites"

puts "Seeding completed!"
puts "You can sign in with:"
puts "  - seller1@example.com / password123 (has properties)"
puts "  - seller2@example.com / password123 (has properties)"
puts "  - buyer@example.com / password123 (has favorites)"