require "rails_helper"

RSpec.feature "Geocasts", type: :feature do
  context "as anonymous user" do
    scenario "should be able to get weather forecast for valid address" do
      visit root_path
      expect(page).to have_content("Welcome")
    end
  end
end
