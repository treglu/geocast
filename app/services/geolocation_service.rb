# GeolocationService
#
# A service class to interact with the Geocoder API and provide
# geolocation data based on a given address.
# This class is responsible for retrieving geolocation coordinates,
# formatted address, and postal code for a specified address.
#
# This class will return _only the first result_ from Geocoder API.
#
# This service could be exteded to support smart search that presents
# a list of addresses based on partial user entry.
#
# Example usage:
#   geo_service = GeolocationService.new("1 Apple Park Way, Cupertino, CA")
#   coordinates = geo_service.call
#   full_address = geo_service.located_address
#   postal_code = geo_service.postal_code
#
# Dependencies:
# - Geocoder gem: Ensure the Geocoder gem is included in the Gemfile to support the API queries.
class GeolocationService
  # Initializes a new instance of GeolocationService
  # @param address [String] The address to be geocoded
  def initialize(address)
    @address = address
    @results = nil
  end

  # Main method to fetch geolocation data based on the provided address
  # Example result:
  #   [37.3362065, -122.0069962]
  # @return [Array<Float>] The latitude and longitude coordinates of the address, or an empty array if no results are found
  def call
    return [] unless results.any?

    results.first.coordinates
  end

  # Retrieves the full formatted address of the first geocoded result
  # @return [String, nil] The formatted address, or nil if no results are available
  def located_address
    return unless results.any?

    addr = results.first
    if addr
      [
        format_street_address(addr),
        addr.city || addr.county,
        addr.state,
        addr.postal_code
      ].compact.join(", ")
    end
  end

  # Retrieves the postal code of the address if available
  # @return [String, nil] The postal code, or nil if no results are available
  def postal_code
    return unless results.any?

    results.first.postal_code
  end

  private

  # Memoizes and fetches geolocation results from the Geocoder API
  # Geocoder API performs its own caching, when caching is enabled
  # @return [Array<Geocoder::Result>] The geocoded results based on the provided address
  def results
    @results ||= Geocoder.search(@address)
  end

  # Helper method to format street address
  # @param addr [Geocoder::Result] The geocoded address object
  # @return [String] The formatted street address
  def format_street_address(addr)
    [addr.house_number, addr.street].compact.join(" ")
  end
end
