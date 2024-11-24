class GeocastsController < ApplicationController
  def show
    @address = params[:address] || ""

    unless @address.present?
      flash[:alert] = "Please enter address"
      redirect_back(fallback_location: root_path) and return
    end

    geolocation_service = GeolocationService.new(@address)
    coordinates = geolocation_service.call

    unless coordinates.any?
      flash[:alert] = "Could not process entered text. Please check that you are entering a valid address"
      render :show and return
    end

    @located_address = geolocation_service.located_address
    postal_code = geolocation_service.postal_code

    weather_service = WeatherGovService.new(coordinates:, postal_code:)
    @forecast = weather_service.call

    unless @forecast.any?
      flash[:alert] = weather_service.error_message
      render :show and return

    end

    @cache_indicator = "#{weather_service.cached ? "Cached" : "Live"} results"

    # Group forecasts by day
    grouped_forecasts = @forecast.group_by do |entry|
      Time.parse(entry[:startTime]).strftime("%Y-%m-%d")
    end

    # Process grouped data
    @summary_forecast = grouped_forecasts.map do |day, forecasts|
      # Extract the temperatures for the current day
      temperatures = forecasts.map { |f| f[:temperature] }

      # Find the highest and lowest temperatures for the day
      high_temp = temperatures.max
      low_temp = temperatures.min

      # Calculate the average chance of rain for the day
      total_chance_of_rain = forecasts.sum { |f| f[:probabilityOfPrecipitation][:value].to_i }
      avg_chance_of_rain = (total_chance_of_rain.to_f / forecasts.size).round(0)

      # Create a hash for the day's summary
      {
        date: Date.parse(day),
        high_temp: high_temp,
        low_temp: low_temp,
        avg_chance_of_rain: avg_chance_of_rain
      }
    end
  end
end
