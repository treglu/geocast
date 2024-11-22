RSpec.shared_context "with a valid address" do
  let(:valid_address) { "1600 Amphitheatre Parkway, Mountain View, CA" }
  let(:coordinates) { [37.422, -122.084] }
  let(:service) { GeolocationService.new(valid_address) }

  before do
    # Mocking Geocoder to avoid API requests during testing
    allow(Geocoder).to receive(:search).with(valid_address).and_return([double(coordinates: coordinates)])
  end
end
