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
    if addr
      [
        "#{addr.house_number} #{addr.street}",
        addr.city || addr.county,
        addr.state,
        addr.postal_code
      ].join(", ")
    end
    # "#{addr.house_number} #{addr.street}, #{addr.city}, #{addr.state}, #{addr.postal_code}" if addr
  end

  def postal_code
    return unless results.any?
    results.first.postal_code
  end

  private

  def results
    @results ||= Geocoder.search(@address)
  end
end
