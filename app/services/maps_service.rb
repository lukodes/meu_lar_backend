class MapsService
  def initialize(property_coordinates, work_coordinates)
    @client = GoogleMapsService::Client.new
    @property_coordinates = property_coordinates
    @work_coordinates = work_coordinates
  end

  def calculate_transport
    peak_time = calculate_peak_time
    driving_directions = fetch_directions('driving', peak_time)
    public_directions = fetch_directions('transit', peak_time)

    {
      work_distance: driving_directions[:distance],
      duration_peak: driving_directions[:duration_in_traffic],
      duration_nopeak: driving_directions[:duration],
      instructions_public: parse_public_instructions(public_directions)
    }
  end

  private

  def calculate_peak_time
    date = Date.tomorrow.next_weekday
    DateTime.new(date.year, date.month, date.day, 11, 0, 0) # 11 AM
  end

  def fetch_directions(mode, departure_time)
    directions = @client.directions(
      "#{@property_coordinates[0]},#{@property_coordinates[1]}",
      "#{@work_coordinates[0]},#{@work_coordinates[1]}",
      mode: mode,
      departure_time: departure_time,
      language: 'pt-BR'
    )
    directions[0][:legs][0]
  end

  def parse_public_instructions(directions)
    directions[:steps].each_with_index.map do |step, index|
      {
        index: index,
        instruction: step[:html_instructions],
        distance: step[:distance][:text]
      }
    end
  end
end