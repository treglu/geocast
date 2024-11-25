# GeocastsController
# Handles the display of geolocation-based weather forecasts based on user-provided addresses.
# This controller is responsible for processing a given address, retrieving geographic coordinates,
# and displaying the relevant weather forecast using external services for geolocation and weather.
#
# Actions:
# - `show`: Accepts an address as a parameter, fetches its geolocation, and displays the corresponding weather forecast.
#
# Dependencies:
# - GeolocationService: A service that converts addresses into geographic coordinates.
# - WeatherGovService: A service that fetches weather forecasts from the NOAA Weather API based on geographic coordinates.
class GeocastsController < ApplicationController
  # GET /geocasts/show
  # Displays weather information for a given address.
  # If no address is provided, or if the address is invalid, appropriate error messages are displayed.
  # @param [String] address - The address to be geocoded (optional).
  #
  # Workflow:
  # - If no address is provided, redirect the user with an alert.
  # - Instantiate GeolocationService to retrieve geographic coordinates.
  # - If coordinates cannot be retrieved, show an error message and re-render the form.
  # - Instantiate WeatherGovService to get the weather forecast for the provided coordinates.
  # - If the weather forecast retrieval fails, display the error message.
  # - If successful, process and display the detailed and summarized forecast.
  def show
    @address = params[:address] || ""

    # Ensure an address is provided; otherwise, redirect the user back.
    unless @address.present?
      flash[:alert] = "Please enter address"
      redirect_back(fallback_location: root_path) and return
    end

    # Use GeolocationService to convert the provided address into geographic coordinates.
    geolocation_service = GeolocationService.new(@address)
    coordinates = geolocation_service.call

    # Handle invalid address inputs or geolocation errors.
    unless coordinates.any?
      flash[:alert] = "Could not process entered text. Please check that you are entering a valid address"
      render :show and return
    end

    # Retrieve additional information like the located address and postal code.
    @located_address = geolocation_service.located_address
    postal_code = geolocation_service.postal_code

    # Use WeatherGovService to fetch the weather forecast for the given coordinates.
    weather_service = WeatherGovService.new(coordinates:, postal_code:)
    @forecast = weather_service.call

    # Handle errors when fetching the weather forecast.
    unless @forecast.any?
      flash[:alert] = weather_service.error_message
      render :show and return
    end

    # Set an indicator to show whether the weather forecast was cached or fetched live.
    @cache_indicator = "#{weather_service.cached ? "Cached" : "Live"} results"

    # Process the grouped data to create a daily summary.
    @summary_forecast = weather_service.summary_forecast
  end
end
