require "rails_helper"

RSpec.describe "Geocasts", type: :request do
  context "with a valid address" do
    let(:valid_address) { "1600 Amphitheatre Parkway, Mountain View, CA" }
    let(:weather_forecast) { "Sunny with a high of 75F" }

    before do
      # Stub the WeatherService to return a predictable forecast
      allow_any_instance_of(WeatherGovService).to receive(:call).and_return(weather_forecast)
    end
    describe "POST /geocast" do
      before { post geocast_path, params: {address: valid_address} }
      it "renders the show template" do
        expect(response).to have_http_status :ok
      end

      it "returns correct weather forecast" do
        expect(response.body).to include(weather_forecast)
      end
    end
  end

  context "without an address" do
    it "renders the show template with an empty forecast" do
      post :create, params: {address: ""}

      expect(assigns(:weather_forecast)).to be_nil
      expect(response).to render_template(:show)
    end
  end
  describe "POST /geocast (with address)" do
    it "should return successful response" do
      expect(response).to have_http_status :ok
    end
  end
end
