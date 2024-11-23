require "rails_helper"

RSpec.describe GeolocationService, type: :service do
  describe "#call" do
    context "with a valid address" do
      let(:valid_address) { "1 Apple Park Way, Cupertino, CA" }
      let(:coordinates) { [37.3362065, -122.0069962] }
      let(:service) { GeolocationService.new(valid_address) }

      before do
        # Mocking Geocoder to avoid API requests during testing
        allow(Geocoder).to receive(:search).with(valid_address).and_return([double(coordinates: coordinates)])
      end

      it "returns the coordinates" do
        expect(service.call).to eq(coordinates)
      end
    end
    context "with an invalid address" do
      let(:invalid_address) { "Invalid Address" }
      let(:service) { GeolocationService.new(invalid_address) }

      before do
        # Mocking Geocoder to avoid API requests during testing
        allow(Geocoder).to receive(:search).with(invalid_address).and_return([])
      end

      it "call response should be nil" do
        expect(service.call).to eq([])
      end
    end
    context "with an empty address" do
      let(:empty_address) { "" }
      let(:service) { GeolocationService.new(empty_address) }

      before do
        # Mocking Geocoder to avoid API requests during testing
        allow(Geocoder).to receive(:search).with(empty_address).and_return([])
      end

      it "call response should be nil" do
        expect(service.call).to eq([])
      end
    end
  end
end
