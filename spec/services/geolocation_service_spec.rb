require "rails_helper"

RSpec.describe GeolocationService, type: :service do
  describe "#call" do
    context "with a valid address" do
      include_context "with a valid address"
      it "returns the coordinates" do
        expect(service.call).to eq(coordinates)
      end
    end
    context "with an invalid address" do
      include_context "with an invalid address"
      it "call response should be nil" do
        expect(service.call).to be nil
      end
    end
    context "with an empty address" do
      include_context "with an empty address"
      it "call response should be nil" do
        expect(service.call).to be nil
      end
    end
  end

  describe "#valid?" do
    context "with a valid address" do
      include_context "with a valid address"
      it "returns valid response" do
        expect(service.valid?).to be true
      end
    end
    context "with an invalid address" do
      include_context "with an invalid address"
      it "response should be invalid" do
        expect(service.valid?).to be false
      end
    end

    context "with an empty address" do
      include_context "with an empty address"
      it "response should be invalid" do
        expect(service.valid?).to be false
      end
    end
  end
end
