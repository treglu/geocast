class WeatherGovService
  class APIError < StandardError; end
  ENDPOINT = "https://api.weather.gov"
  CACHE_EXPIRATION = 30.minutes

  attr_reader :error_message, :cached

  def initialize(coordinates:, postal_code: nil)
    @coordinates = coordinates.map { |item| item.round(4) }
    @postal_code = postal_code || "00000"
    @gridpoints_results = nil
    @forecast_results = nil
  end

  def call
    cached_result = Rails.cache.read(cache_key)
    if cached_result
      @cached = true
      cached_result
    else
      @cached = false
      fresh_result = fetch_and_process_weather
      Rails.cache.write(cache_key, fresh_result, expires_in: CACHE_EXPIRATION)
      fresh_result
    end
  rescue => e
    log_error(e)
    @error_message = e.message
    []
  end

  private

  def fetch_and_process_weather
    gridpoints_response = fetch_gridpoints(@coordinates)
    forecast_url = gridpoints_response.dig("properties", "forecast")
    return [] unless forecast_url

    forecast_response = fetch_forecast(forecast_url)
    forecasts = forecast_response.dig("properties", "periods")
    forecasts.map(&:symbolize_keys)
  end

  def fetch_gridpoints(coordinates)
    response = gridpoints_results(coordinates)
    validate_response!(response)
    JSON.parse(response.body)
  end

  def fetch_forecast(forecast_url)
    response = forecast_results(forecast_url)
    validate_response!(response)
    JSON.parse(response.body)
  end

  def gridpoints_results(coordinates)
    @gridpoints_results ||= Faraday.get("#{ENDPOINT}/points/#{coordinates[0]},#{coordinates[1]}")
  end

  def forecast_results(forecast_url)
    @forecast_results ||= Faraday.get(forecast_url)
  end

  def validate_response!(response)
    json_body = JSON.parse(response.body)

    unless response.success?
      error_detail = json_body["detail"] || "Unknown error"
      raise APIError.new("HTTP Error: #{response.status} - #{error_detail}")
    end
  rescue JSON::ParserError
    raise StandardError.new("Invalid JSON response from API")
  end

  def cache_key
    "weather_forecast:#{@postal_code}"
  end

  def log_error(error)
    Rails.logger.error("WeatherGovService Error: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end
end
