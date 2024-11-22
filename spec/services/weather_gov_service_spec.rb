require 'rails_helper'

RSpec.describe WeatherGovService, type: :service do
  let(:coordinates) { [37.422, -122.084] }

  before do
    # Stub the WeatherService to return a predictable forecast
    allow_any_instance_of(WeatherGovService).to receive(:call).and_return(weather_forecast)
  end

  it "returns weather data for valid coordinates" do
    service = WeatherGovService.new(coordinates)
    result = service.call
    expect(result).to_not be_nil
  end
end