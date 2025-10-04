require 'rails_helper'

RSpec.describe "API V1 Properties", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.id.to_s }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Host' => 'localhost' } }

  describe "GET /api/v1/properties" do
    let!(:property1) { create(:property, user: user) }
    let!(:property2) { create(:property) }

    it "returns paginated properties" do
      get "/api/v1/properties", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to have_key('properties')
      expect(JSON.parse(response.body)['properties'].count).to eq(2)
    end

    it "filters by location" do
      get "/api/v1/properties?city=#{property1.city}", headers: headers

      expect(response).to have_http_status(:ok)
      properties = JSON.parse(response.body)['properties']
      expect(properties.count).to eq(1)
      expect(properties.first['city']).to eq(property1.city)
    end

    it "works without authentication" do
      get "/api/v1/properties", headers: { 'Host' => 'localhost' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/properties/:id" do
    let(:property) { create(:property, user: user) }

    it "returns the property" do
      get "/api/v1/properties/#{property.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(property.id)
    end

    it "works without authentication" do
      get "/api/v1/properties/#{property.id}", headers: { 'Host' => 'localhost' }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/properties" do
    let(:valid_params) do
      {
        property: {
          title: "New Property",
          description: "A great property",
          price: 100000,
          property_type: "House",
          bedrooms: 3,
          bathrooms: 2,
          square_feet: 1500,
          address: "123 Main St",
          city: "Test City",
          state: "TS",
          postal_code: "12345",
          country: "US"
        }
      }
    end

    it "creates a new property" do
      expect {
        post "/api/v1/properties", params: valid_params, headers: headers
      }.to change(Property, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['title']).to eq("New Property")
    end

    it "returns errors for invalid data" do
      invalid_params = valid_params.deep_merge(property: { title: "" })

      post "/api/v1/properties", params: invalid_params, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)).to have_key('errors')
    end

    it "requires authentication" do
      post "/api/v1/properties", params: valid_params, headers: { 'Host' => 'localhost' }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PUT /api/v1/properties/:id" do
    let(:property) { create(:property, user: user) }
    let(:update_params) do
      {
        property: {
          title: "Updated Property",
          price: 150000
        }
      }
    end

    it "updates the property" do
      put "/api/v1/properties/#{property.id}", params: update_params, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['title']).to eq("Updated Property")
      expect(property.reload.price).to eq(150000)
    end

    it "requires authentication" do
      put "/api/v1/properties/#{property.id}", params: update_params, headers: { 'Host' => 'localhost' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
