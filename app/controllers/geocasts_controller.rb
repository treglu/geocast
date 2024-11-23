class GeocastsController < ApplicationController
  def create
    unless address_params[:address].present?
      flash[:alert] = "Please enter address"
      redirect_back(fallback_location: root_path) and return
    end

    geolocation_service = GeolocationService.new(address_params[:address])
    coordinates = geolocation_service.call

    unless coordinates.any?
      flash[:alert] = "Could not process entered text. Please check that you are entering a valid address"
      redirect_back(fallback_location: root_path) and return
    end

    weather_service = WeatherGovService.new(coordinates)
    @forecast = weather_service.call

    unless @forecast.any?
      flash[:alert] = weather_service.error_message
      redirect_back(fallback_location: root_path) and return

    end
    render :show
  end

  private

  def address_params
    params.permit(:address)
  end

  def coordinates
    service = GeolocationService.new(address_params[:address])
  end
end
