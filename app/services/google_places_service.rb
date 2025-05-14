class GooglePlacesService
  MIN_RATING = 10

  def initialize(coordinates)
    @client = GooglePlaces::Client.new(Settings.google_places_api_key)
    @coordinates = coordinates
  end

  def fetch_place_data(place)
    result = { name: place[:name] }
    google_data = fetch_google_data(place)
    result[:total_count] = google_data.count
    items = google_data.take(place[:count]).map { |item| populate_item(item) }
    result[:items] = items
    result[:top] = items.max_by { |x| x[:total_rating] }
    result[:closest] = items.first
    result
  end

  private

  def fetch_google_data(place)
    @client.spots(
      @coordinates[0], @coordinates[1],
      keyword: place[:keyword],
      types: place[:type],
      rankby: 'distance',
      language: 'pt-BR'
    ).select { |item| (item.json_result_object['user_ratings_total'] || 0) > MIN_RATING }
  end

  def populate_item(item)
    distance = DistanceCalculator.calculate(@coordinates, [item.lat, item.lng])
    {
      name: item.name,
      rating: item.rating,
      total_rating: item.json_result_object['user_ratings_total'],
      by_foot: distance[:walking],
      by_car: distance[:car]
    }
  end
end