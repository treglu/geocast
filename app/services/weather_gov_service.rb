# WeatherGovService
# A service class to interact with the NOAA National Weather Service
# (api.weather.gov) API and provide weather forecast data based on given
# geographic coordinates. This class handles fetching and processing
# weather information, including caching the data for a specified duration
# to minimize redundant API calls.
#
# NOAA Weather API is available at https://www.weather.gov/documentation/services-web-api
#
# NOAA Weather API does not require authentication, it requires using contact information
# Update API_CLIENT_* constants as needed.
#
# Service provides `#error_message` read-only attribute, populated with error explanation,
# designed for end-user consumption.
#
# Service also provides `#cached` read-only attribute to indicate whether the successful
# request was cached or live API was used.
#
# Example usage:
#   weather_service = WeatherGovService.new(coordinates: [37.3362, -122.007])
#   forecast = weather_service.call
#
#   puts weather_service.cached  # returns => false
#   puts forecast
#   # returns => [
#     {
#       name: "This Afternoon",
#       temperature: 75,
#       shortForecast: "Sunny",
#       icon: "https://api.weather.gov/icons/land/day/wind_skc?size=medium",
#       startTime: "2024-11-20T10:00:00-06:00",
#       probabilityOfPrecipitation: {
#         unitCode: "wmoUnit:percent",
#         value: nil
#       }
#     },
#     {
#       name: "Tonight",
#       temperature: 55,
#       shortForecast: "Clear",
#       startTime: "2024-11-20T18:00:00-06:00",
#       icon: "https://api.weather.gov/icons/land/day/wind_skc?size=medium",
#       probabilityOfPrecipitation: {
#         unitCode: "wmoUnit:percent",
#         value: 30
#       }
#     }
#   ]
#
#   With invalid coordinates:
#   weather_service = WeatherGovService.new(coordinates: [999, -999])
#   weather_service.call  # returns => []
#   weather_service.error_message  # returns => "Error message details.."
#
# Dependencies:
# - Faraday gem: Ensure the Faraday gem is included in the Gemfile
#                to support HTTP requests to the Weather.gov API.
# - Rails: This service uses Rails caching and logging mechanisms.
class WeatherGovService
  # Custom error class for handling API-specific errors
  class APIError < StandardError; end

  # Constants for the Weather.gov API endpoint and cache expiration time
  ENDPOINT = "https://api.weather.gov"
  CACHE_EXPIRATION = 30.minutes

  # App identification defaults as required by NOAA Weather API
  API_CLIENT = "geocast.andreykireev.com"
  API_CLIENT_CONTACT = ["andreykireev", "gmail.com"].join("@")  # fight email address scraping from public repos

  # Attributes accessible to users
  attr_reader :error_message, :cached

  # Initializes a new instance of WeatherGovService
  # @param coordinates [Array<Float>] The latitude and longitude coordinates rounded to 4 decimal places as required by API
  # @param postal_code [String, nil] Optional postal code for caching purposes, defaults to "00000" if not provided
  def initialize(coordinates:, postal_code: nil)
    @coordinates = coordinates.map { |item| item.round(4) }
    @postal_code = postal_code || "00000"
    @gridpoints_results = nil
    @forecast_results = nil
    @result = nil
  end

  # Main method to retrieve weather data
  # This method will cache the response based on `postal_code` provided together with the coordinates data
  # @return [Array<Hash>] The processed weather forecast data, or an empty array if an error occurs
  def call
    get_result
  end

  # Summarizes the forecast by grouping it by day
  # @return [Array<Hash>] Summary of daily high/low temperatures and average chance of rain
  def summary_forecast
    # Group forecasts by day
    grouped_forecasts = @result.group_by do |entry|
      Time.parse(entry[:startTime]).strftime("%Y-%m-%d")
    end

    # Process grouped data
    grouped_forecasts.map do |day, forecasts|
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

  private

  # Fetches and processes weather forecast data
  # @return [Array<Hash>] A list of weather forecast periods or an empty array if an error occurs
  def fetch_and_process_weather
    gridpoints_response = fetch_gridpoints(@coordinates)
    forecast_url = gridpoints_response.dig(:properties, :forecast)
    return [] unless forecast_url

    forecast_response = fetch_forecast(forecast_url)
    forecasts = forecast_response.dig(:properties, :periods)
    forecasts.map(&:symbolize_keys)
  end

  # Fetches grid points for the given coordinates
  # @param coordinates [Array<Float>] The latitude and longitude coordinates
  # @return [Hash] The parsed JSON response containing grid point information
  def fetch_gridpoints(coordinates)
    response = gridpoints_results(coordinates)
    validate_response!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  # Fetches the weather forecast using the provided forecast URL
  # @param forecast_url [String] The URL to fetch forecast data
  # @return [Hash] The parsed JSON response containing forecast information
  def fetch_forecast(forecast_url)
    response = forecast_results(forecast_url)
    validate_response!(response)
    JSON.parse(response.body, symbolize_names: true)
  end

  # Retrieves grid point data, memoized to avoid redundant API calls
  # @param coordinates [Array<Float>] The latitude and longitude coordinates
  # @return [Faraday::Response] The HTTP response from the Weather.gov API
  def gridpoints_results(coordinates)
    @gridpoints_results ||= faraday_connection.get("#{ENDPOINT}/points/#{coordinates[0]},#{coordinates[1]}")
  end

  # Retrieves forecast data, memoized to avoid redundant API calls
  # @param forecast_url [String] The URL to fetch forecast data
  # @return [Faraday::Response] The HTTP response from the Weather.gov API
  def forecast_results(forecast_url)
    @forecast_results ||= faraday_connection.get(forecast_url)
  end

  # Validates the API response and raises an error if the response is unsuccessful
  # @param response [Faraday::Response] The HTTP response to validate
  # @raise [APIError] If the response status is not successful or if JSON parsing fails
  def validate_response!(response)
    json_body = JSON.parse(response.body, symbolize_names: true)

    unless response.success?
      error_detail = json_body[:detail] || "Unknown error"
      raise APIError.new("HTTP Error: #{response.status} - #{error_detail}")
    end
  rescue JSON::ParserError
    raise StandardError.new("Invalid JSON response from API")
  end

  # Generates a unique cache key for storing the weather forecast data
  # @return [String] The generated cache key
  def cache_key
    "weather_forecast:#{@postal_code}"
  end

  # Logs an error message and backtrace for debugging purposes
  # @param error [StandardError] The error object to log
  def log_error(error)
    Rails.logger.error("WeatherGovService Error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end

  # Creates a new Faraday connection with default headers used for client identification
  # @return [Faraday::Connection] A configured Faraday connection instance
  def faraday_connection
    Faraday.new do |conn|
      conn.headers["User-Agent"] = "(#{API_CLIENT}, #{API_CLIENT_CONTACT})"
    end
  end

  # Retrieves and caches the weather forecast data
  # @return [Array<Hash>] The processed weather forecast data, or an empty array if an error occurs
  def get_result
    if @result
      @cached = true
      @result
    else
      cached_result = Rails.cache.read(cache_key)
      if cached_result
        @cached = true
        @result = cached_result
      else
        @cached = false
        fresh_result = fetch_and_process_weather
        Rails.cache.write(cache_key, fresh_result, expires_in: CACHE_EXPIRATION)
        @result = fresh_result
      end
    end
  rescue => e
    log_error(e)
    @error_message = e.message
    []
  end
end
