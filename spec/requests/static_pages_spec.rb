require 'rails_helper'

RSpec.describe "StaticPages", type: :request do

  describe "GET #home" do
    before { get root_path }
    it "should be successful" do
      expect(response).to have_http_status :ok
    end
  end
  
end
