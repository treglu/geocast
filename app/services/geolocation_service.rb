class GeolocationService
  def initialize(address)
    @address = address
    @results = nil
  end

  def call
    return [] unless results.any?
    results.first.coordinates
  end

  private

  def results
    @results ||= Geocoder.search(@address)
  end
end
