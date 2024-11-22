RSpec.shared_context "with an empty address" do
  let(:empty_address) { "" }
  let(:service) { GeolocationService.new(empty_address) }

  before do
    # Mocking Geocoder to avoid API requests during testing
    allow(Geocoder).to receive(:search).with(empty_address).and_return([])
  end
end
