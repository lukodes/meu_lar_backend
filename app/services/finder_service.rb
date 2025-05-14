class FinderService < ApplicationService

  def initialize(property, work)
    @property = property
    @work = work
    @property_coordinates = Geocoder.search(property[:zip_code]).first.coordinates
    @work_coordinates = Geocoder.search(work[:zip_code]).first.coordinates
    @google_places = GooglePlacesService.new(@property_coordinates)
    @google_maps = MapsService.new(@property_coordinates, @work_coordinates)
  end

  def convenience(place_list)
    place_list.map { |place| @google_places.fetch_place_data(place) }
  end

  def transport
    @google_maps.calculate_transport
  end

  def calcula_financiamento_SAC(valor_imovel)
    FinanceCalculatorService.calculate_sac(valor_imovel)
  end
end
