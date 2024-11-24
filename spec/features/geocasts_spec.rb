require "rails_helper"

RSpec.feature "Geocasts", type: :feature do
  context "with valid address" do
    before do
      # Stub the WeatherService to return a predictable forecast
      geolocation_double = instance_double(GeolocationService)
      allow(GeolocationService).to receive(:new).with(address).and_return(geolocation_double)
      allow(geolocation_double).to receive(:call).and_return(coordinates)
      allow(geolocation_double).to receive(:located_address).and_return(located_address)
      allow(geolocation_double).to receive(:postal_code).and_return(postal_code)
      allow(geolocation_double).to receive(:postal_code).and_return(postal_code)

      weather_service_double = instance_double(WeatherGovService)
      allow(WeatherGovService).to receive(:new).with(coordinates:, postal_code:).and_return(weather_service_double)
      allow(weather_service_double).to receive(:call).and_return(weather_forecast)
      allow(weather_service_double).to receive(:cached).and_return(true)
    end

    let(:address) { "1 Apple Park Way, Cupertino, CA" }
    let(:located_address) { "1 Apple Park Way, Cupertino, California, 94087" }
    let(:coordinates) { [37.3362, -122.0070] }
    let(:postal_code) { "94087" }

    let(:weather_forecast) {
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

    it "should be able to get weather forecast" do
      visit root_path
      expect(page).to have_content("Geocast App")

      fill_in :address, with: address
      click_button "Check Weather"

      expect(page).to have_content(weather_forecast.first[:name])
      expect(page).to have_content(weather_forecast.first[:temperature].to_s)
      expect(page).to have_content(weather_forecast.first[:shortForecast])
      expect(page).to have_content(located_address)
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
    before do
      # Stub the WeatherService to return a predictable forecast
      geolocation_double = instance_double(GeolocationService)
      allow(GeolocationService).to receive(:new).with(invalid_address).and_return(geolocation_double)
      allow(geolocation_double).to receive(:call).and_return(coordinates)
    end

    let(:invalid_address) { "INVALID ADDRESS" }
    let(:coordinates) { [] }

    it "should see an error for invalid address" do
      visit root_path
      expect(page).to have_content("Geocast App")

      fill_in :address, with: invalid_address
      click_button "Check Weather"

      expect(page).to have_content("Could not load the forecast")
    end
  end
end
