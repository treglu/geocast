require "rails_helper"

RSpec.describe WeatherGovService, type: :service do
  describe "#call" do
    before { Rails.cache.clear }
    let(:service) { WeatherGovService.new(coordinates:, postal_code:) }

    context "with valid coordinates" do
      let(:coordinates) { [37.3362, -122.0070] }
      let(:postal_code) { "94087" }
      let(:forecast) { {name: "This Afternoon", temperature: 75, shortForecast: "Sunny"} }

      let(:first_endpoint) { "https://api.weather.gov/points/#{coordinates[0]},#{coordinates[1]}" }
      let(:first_response) { {properties: {forecast: second_endpoint}} }

      let(:second_endpoint) { "https://api.weather.gov/gridpoints/MTR/93,87/forecast" }
      let(:second_response) { {properties: {periods: [forecast]}} }

      let(:service) { WeatherGovService.new(coordinates:, postal_code:) }

      before do
        # Mock the first API call
        allow(Faraday).to receive(:get).with(first_endpoint).and_return(
          instance_double(Faraday::Response, success?: true, body: first_response.to_json)
        )
        # Mock the second API call
        allow(Faraday).to receive(:get).with(second_endpoint).and_return(
          instance_double(Faraday::Response, success?: true, body: second_response.to_json)
        )
      end

      it "returns weather data for valid coordinates" do
        results = service.call
        expect(results).to_not be_nil
        expect(results.first).to include(forecast)
      end
    end

    context "with super precise coordinates" do
      let(:coordinates) { [37.3362065555555555555, -122.00699625555555555] }
      let(:postal_code) { "94087" }

      it "during inintialization coordinates must be rounded to max 4 digits, due to API limitations" do
        expect(service.instance_variable_get(:@coordinates)).to eq([37.3362, -122.0070])
      end
    end

    context "with the connection issues" do
      let(:coordinates) { [37.3362, -122.0070] }
      let(:postal_code) { "94087" }
      let(:error_message) { "Mock Connection Error" }

      before do
        allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed.new(error_message))
      end

      it "returns empty array" do
        results = service.call
        expect(results).to eq []
      end

      it "should give error details in #error_message" do
        service.call
        expect(service.error_message).to eq(error_message)
      end
    end

    context "with invalid coordinates" do
      let(:coordinates) { [999, 999] }
      let(:postal_code) { "94087" }

      let(:first_endpoint) { "https://api.weather.gov/points/#{coordinates[0]},#{coordinates[1]}" }
      let(:first_response) { {properties: {forecast: second_endpoint}} }

      let(:error_message) { "Invalid Coordinates" }
      let(:status) { 400 }

      before do
        allow(Faraday).to receive(:get).with(first_endpoint).and_return(
          instance_double(Faraday::Response, success?: false, status:, body: {
            status:,
            detail: error_message
          }.to_json)
        )
      end

      it "returns empty array" do
        results = service.call
        expect(results).to eq []
      end

      it "includes error message details in the #error_message" do
        service.call
        expect(service.error_message).to eq("HTTP Error: #{status} - #{error_message}")
      end
    end

    context "with malformed JSON response" do
      let(:coordinates) { [37.3362, -122.0070] }
      let(:postal_code) { "94087" }

      let(:first_endpoint) { "https://api.weather.gov/points/#{coordinates[0]},#{coordinates[1]}" }
      let(:first_response) { {properties: {forecast: second_endpoint}} }

      let(:second_endpoint) { "https://api.weather.gov/gridpoints/MTR/93,87/forecast" }
      let(:second_response) { {properties: {periods: [forecast]}} }

      let(:json_parse_error) { "Invalid JSON response from API" }
      context "in first API response" do
        before do
          allow(Faraday).to receive(:get).with(first_endpoint).and_return(
            instance_double(Faraday::Response, success?: false, body: "<< invalid JSON >>")
          )
        end

        it "returns empty array" do
          results = service.call
          expect(results).to eq []
        end

        it "the #error_message should explain the error" do
          service.call
          expect(service.error_message).to eq(json_parse_error)
        end
      end

      context "in second API response" do
        before do
          # Mock the first API call
          allow(Faraday).to receive(:get).with(first_endpoint).and_return(
            instance_double(Faraday::Response, success?: true, body: first_response.to_json)
          )

          allow(Faraday).to receive(:get).with(second_endpoint).and_return(
            instance_double(Faraday::Response, success?: false, body: "<< invalid JSON >>")
          )
        end

        it "returns empty array" do
          results = service.call
          expect(results).to eq []
        end

        it "the #error_message should explain the error" do
          service.call
          expect(service.error_message).to eq(json_parse_error)
        end
      end
    end

    context "with caching enabled" do
      let(:coordinates) { [37.3362, -122.0070] }
      let(:postal_code) { "94087" }
      let(:forecast) { {name: "This Afternoon", temperature: 75, shortForecast: "Sunny"} }

      let(:first_endpoint) { "https://api.weather.gov/points/#{coordinates[0]},#{coordinates[1]}" }
      let(:first_response) { {properties: {forecast: second_endpoint}} }

      let(:second_endpoint) { "https://api.weather.gov/gridpoints/MTR/93,87/forecast" }
      let(:second_response) { {properties: {periods: [forecast]}} }

      let(:service) { WeatherGovService.new(coordinates:, postal_code:) }

      before do
        # Mock the first API call
        allow(Faraday).to receive(:get).with(first_endpoint).and_return(
          instance_double(Faraday::Response, success?: true, body: first_response.to_json)
        )
        # Mock the second API call
        allow(Faraday).to receive(:get).with(second_endpoint).and_return(
          instance_double(Faraday::Response, success?: true, body: second_response.to_json)
        )
      end

      it "caches the result for subsequent calls within the expiration time" do
        # First call to populate the cache
        first_results = service.call
        expect(first_results.first).to include(forecast)
        expect(service.cached).to be false

        # Stub Faraday again to ensure no API call is made on second request
        allow(Faraday).to receive(:get).and_raise("Unexpected API call")

        # Second call should fetch from cache
        second_results = service.call
        expect(second_results).to eq(first_results)
        expect(service.cached).to be true
      end
    end
  end
end
