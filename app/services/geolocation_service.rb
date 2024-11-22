class GeolocationService
  def initialize(address)
    @address = address
    @results = nil
  end

  def call
    results.first.coordinates if valid?
  end

  def valid?
    results.any?
  end

  private

  def results
    @results ||= Geocoder.search(@address)
  end
end
