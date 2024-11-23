require "rails_helper"

RSpec.describe "Geocasts", type: :request do
  describe "POST /geocast" do
    context "with non-empty address field" do
      context "containing valid address" do
        before do
          # Stub the WeatherService to return a predictable forecast
          geolocation_double = instance_double(GeolocationService)
          allow(GeolocationService).to receive(:new).with(address).and_return(geolocation_double)
          allow(geolocation_double).to receive(:call).and_return(coordinates)

          weather_service_double = instance_double(WeatherGovService)
          allow(WeatherGovService).to receive(:new).with(coordinates).and_return(weather_service_double)
          allow(weather_service_double).to receive(:call).and_return(weather_forecast)
        end

        let(:address) { "1 Apple Park Way, Cupertino, CA" }
        let(:coordinates) { [37.3362, -122.0070] }
        let(:weather_forecast) { [{name: "This Afternoon", temperature: 75, shortForecast: "Sunny"}] }

        before { post geocast_path, params: {address: address} }
        it "returns a successful HTTP response" do
          expect(response).to have_http_status :ok
        end

        it "returns correct weather forecast" do
          expect(response.body).to include(weather_forecast.first[:name])
          expect(response.body).to include(weather_forecast.first[:temperature].to_s)
          expect(response.body).to include(weather_forecast.first[:shortForecast])
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

        before do
          post geocast_path, params: {address: address}
        end
        it "redirects back" do
          expect(response).to redirect_to(root_path)
        end

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

        weather_service_double = instance_double(WeatherGovService)
        allow(WeatherGovService).to receive(:new).with(coordinates).and_return(weather_service_double)
        allow(weather_service_double).to receive(:error_message).and_return("Mock error message")
        allow(weather_service_double).to receive(:call).and_return(weather_forecast)
      end

      let(:address) { "Kyiv, Ukraine" }
      let(:coordinates) { [50.4019, 30.3679] }

      # Return empty forecast
      let(:weather_forecast) { [] }

      before do
        post geocast_path, params: {address: address}
      end
      it "redirects back" do
        expect(response).to redirect_to(root_path)
      end

      it "has alert flash with a message to user" do
        expect(flash[:alert]).to include("Mock error message")
      end
    end

    context "with empty address field" do
      let(:address) { "" }
      before do
        get root_path
        post geocast_path, params: {address: address}
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
