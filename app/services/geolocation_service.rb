class GeolocationService
  def initialize(address)
    @address = address
    @results = nil
  end

  def call
    return [] unless results.any?
    results.first.coordinates
  end

  def located_address
    return unless results.any?
    addr = results.first

    "#{addr.house_number} #{addr.street}, #{addr.city}, #{addr.state}, #{addr.postal_code}" if addr
  end

  private

  def results
    @results ||= Geocoder.search(@address)
  end
end
