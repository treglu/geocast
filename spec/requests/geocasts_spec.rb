require "rails_helper"

RSpec.describe "Geocasts", type: :request do
  describe "GET /geocast?address=:address" do
    context "with non-empty address field" do
      context "containing valid address" do
        before do
          # Stub the WeatherService to return a predictable forecast
          geolocation_double = instance_double(GeolocationService)
          allow(GeolocationService).to receive(:new).with(address).and_return(geolocation_double)
          allow(geolocation_double).to receive(:call).and_return(coordinates)
          allow(geolocation_double).to receive(:located_address).and_return(located_address)
          allow(geolocation_double).to receive(:postal_code).and_return(postal_code)

          weather_service_double = instance_double(WeatherGovService)
          allow(WeatherGovService).to receive(:new).with(coordinates:, postal_code:).and_return(weather_service_double)
          allow(weather_service_double).to receive(:call).and_return(weather_forecast)
          allow(weather_service_double).to receive(:cached).and_return(true)
          allow(weather_service_double).to receive(:summary_forecast).and_return(summary_forecast)
        end

        let(:address) { "1 Apple Park Way, Cupertino, CA" }
        let(:located_address) { "1 Apple Park Way, Cupertino, California, 94087" }
        let(:coordinates) { [37.3362, -122.0070] }
        let(:postal_code) { "94087" }
        let(:summary_forecast) {
          [{date: Date.parse("2024-11-20"), high_temp: 75, low_temp: 55, avg_chance_of_rain: 15}]
        }

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

        before { get geocast_path(address: address) }
        it "returns a successful HTTP response" do
          expect(response).to have_http_status :ok
        end

        it "returns correct weather forecast" do
          expect(response.body).to include(weather_forecast.first[:name])
          expect(response.body).to include(weather_forecast.first[:temperature].to_s)
          expect(response.body).to include(weather_forecast.first[:shortForecast])
          expect(response.body).to include(located_address)
        end
        it "should have cached results indicator" do
          expect(response.body).to include("Cached results")
        end
      end
      context "containing invalid address" do
        before do
          # Stub the WeatherService to return a predictable forecast
          geolocation_double = instance_double(GeolocationService)
          allow(GeolocationService).to receive(:new).with(address).and_return(geolocation_double)
          allow(geolocation_double).to receive(:call).and_return(coordinates)
        end

        let(:address) { "INVALID ADDRESS" }
        let(:coordinates) { [] }

        before { get geocast_path(address: address) }

        it "has alert flash with a message to user" do
          expect(flash[:alert]).to include("Could not process entered text. Please check that you are entering a valid address")
        end
      end
    end
    context "containing valid address outside API geo coverage" do
      before do
        # Stub the WeatherService to return a predictable forecast
        geolocation_double = instance_double(GeolocationService)
        allow(GeolocationService).to receive(:new).with(address).and_return(geolocation_double)
        allow(geolocation_double).to receive(:call).and_return(coordinates)
        allow(geolocation_double).to receive(:located_address).and_return(located_address)
        allow(geolocation_double).to receive(:postal_code).and_return(postal_code)

        weather_service_double = instance_double(WeatherGovService)
        allow(WeatherGovService).to receive(:new).with(coordinates:, postal_code:).and_return(weather_service_double)
        allow(weather_service_double).to receive(:error_message).and_return("Mock error message")
        allow(weather_service_double).to receive(:call).and_return(weather_forecast)
      end

      let(:address) { "Kyiv, Ukraine" }
      let(:located_address) { "Kyiv, Ukraine" }
      let(:coordinates) { [50.4019, 30.3679] }
      let(:postal_code) { "44494087" }

      # let(:postal_code) { "10001" }

      # Return empty forecast
      let(:weather_forecast) { [] }

      before { get geocast_path(address: address) }

      it "has alert flash with a message to user" do
        expect(flash[:alert]).to include("Mock error message")
      end
    end

    context "with empty address field" do
      let(:address) { "" }

      before do
        get root_path # set HTTP Referrer
        get geocast_path(address: address)
      end

      it "redirects back" do
        expect(response).to redirect_to(root_path)
      end
      it "has alert flash with a message to user" do
        expect(flash[:alert]).to eq("Please enter address")
      end
    end
  end
end
