require "rails_helper"

RSpec.feature "Geocasts", type: :feature do
  context "with valid address" do
    let(:valid_address) { "1 Apple Park Way, Cupertino" }
    let(:full_address) { "1 Apple Park Way, Cupertino, California, 94087" }
    let(:long_coordinates) { [37.3362065, -122.0069962] }
    let(:short_coordinates) { [37.3362, -122.0070] }

    let(:expected_response) {
      {coordinates: long_coordinates,
       house_number: "1",
       street: "Apple Park Way",
       city: "Cupertino",
       county: "Santa Clara County",
       state: "California",
       postal_code: "94087",
       country: "United States",
       country_code: "us"}
    }

    let(:forecast) {
      [
        {name: "This Afternoon",
         temperature: 75,
         shortForecast: "Sunny",
         icon: "https://api.weather.gov/icons/land/day/wind_skc?size=medium",
         startTime: "2024-11-20T10:00:00-06:00",
         probabilityOfPrecipitation: {
           unitCode: "wmoUnit:percent",
           value: nil
         }},
        {name: "Tonight",
         temperature: 55,
         shortForecast: "Clear",
         startTime: "2024-11-20T18:00:00-06:00",
         icon: "https://api.weather.gov/icons/land/day/wind_skc?size=medium",
         probabilityOfPrecipitation: {
           unitCode: "wmoUnit:percent",
           value: 30
         }}
      ]
    }

    let(:first_endpoint) { "https://api.weather.gov/points/#{short_coordinates[0]},#{short_coordinates[1]}" }
    let(:first_response) { {properties: {forecast: second_endpoint}} }

    let(:second_endpoint) { "https://api.weather.gov/gridpoints/MTR/93,87/forecast" }
    let(:second_response) { {properties: {periods: forecast}} }

    # Mocking only external APIs, so the test can validate the end to end functionality
    before do
      # Mocking Geocoder to avoid API requests during testing
      allow(Geocoder).to receive(:search).with(valid_address).and_return([double(expected_response)])

      # Mock the Faraday connection
      connection = instance_double(Faraday::Connection)
      allow(Faraday).to receive(:new).and_return(connection)

      # Mock the first API call
      allow(connection).to receive(:get).with(first_endpoint).and_return(
        instance_double(Faraday::Response, success?: true, body: first_response.to_json)
      )
      # Mock the second API call
      allow(connection).to receive(:get).with(second_endpoint).and_return(
        instance_double(Faraday::Response, success?: true, body: second_response.to_json)
      )
    end

    before do
      visit root_path
      expect(page).to have_content("Geocast App")

      fill_in :address, with: valid_address
      click_button "Check Weather"
    end
    it "should be able to get weather forecast" do
      expect(page).to have_content(forecast.first[:name])
      expect(page).to have_content(forecast.first[:temperature].to_s)
      expect(page).to have_content(forecast.first[:shortForecast])
    end

    it "should be able to show full address" do
      expect(page).to have_content(full_address)
    end

    it "should be able to show summary forecast" do
      expect(page).to have_content("High: 75")
      expect(page).to have_content("Low: 55")
    end
  end
  context "with empty address" do
    it "should see an error for empty address" do
      visit root_path
      expect(page).to have_content("Geocast App")

      fill_in :address, with: ""
      click_button "Check Weather"

      expect(current_path).to eq(root_path)
    end
  end

  context "with invalid address" do
    let(:invalid_address) { "INVALID ADDRESS" }
    before do
      # Mocking Geocoder to avoid API requests during testing
      allow(Geocoder).to receive(:search).with(invalid_address).and_return([])
    end

    it "should see an error for invalid address" do
      visit root_path
      expect(page).to have_content("Geocast App")

      fill_in :address, with: invalid_address
      click_button "Check Weather"

      expect(page).to have_content("Could not load the forecast")
    end
  end
end
