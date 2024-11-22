class GeocastsController < ApplicationController

  def home
  end

  def create
    @forecast = WeatherGovService.new(address_params).call
    render :show
  end

  private

  def address_params
    params.permit(:address)

  end
end
