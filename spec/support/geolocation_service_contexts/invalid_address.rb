RSpec.shared_context "with an invalid address" do
  let(:invalid_address) { "Invalid Address" }
  let(:service) { GeolocationService.new(invalid_address) }

  before do
    # Mocking Geocoder to avoid API requests during testing
    allow(Geocoder).to receive(:search).with(invalid_address).and_return([])
  end
end
