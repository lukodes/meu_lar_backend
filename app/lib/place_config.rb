module PlaceConfig
  def self.place_list
    [
      { name: 'academia', keyword: 'academia', type: 'gym', count: 12 },
      { name: 'drogaria', keyword: 'farmácia', type: 'pharmacy', count: 12 },
      { name: 'shopping', keyword: 'shopping', type: 'shopping_mall', count: 11 },
      { name: 'restaurante', keyword: 'restaurante', type: 'restaurant', count: 11 },
      { name: 'veterinario', keyword: 'veterinario', type: 'veterinary_care', count: 11 },
      { name: 'posto', keyword: 'posto de gasolina', type: 'gas_station', count: 11 },
      { name: 'mercado', keyword: 'mercado', type: 'supermarket', count: 11 },
      { name: 'hospital', keyword: 'hospital', type: 'hospital', count: 11 }
    ].freeze
  end

  def self.school_list
    [
      { name: 'ensino_main', keyword: 'berçario', type: 'school', count: 7 },
      { name: 'ensino_fundamental', keyword: 'ensino fundamental', type: 'school', count: 5 },
      { name: 'ensino_medio', keyword: 'ensino médio', type: 'school', count: 5 },
      { name: 'ensino_superior', keyword: 'faculdade', type: 'university', count: 5 }
    ].freeze
  end
end