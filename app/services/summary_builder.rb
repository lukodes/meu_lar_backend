class SummaryBuilder
  def self.build(school_items, convenience_items, _transport_data)
    {
      qtd_escolas: school_items.first[:total_count],
      qtd_hospitais: find_total_count(convenience_items, 'hospital'),
      qtd_academias: find_total_count(convenience_items, 'academia'),
      qtd_drogarias: find_total_count(convenience_items, 'drogaria'),
      qtd_shoppings: find_total_count(convenience_items, 'shopping'),
      qtd_rests: find_total_count(convenience_items, 'restaurante'),
      qtd_vets: find_total_count(convenience_items, 'veterinario'),
      qtd_postos: find_total_count(convenience_items, 'posto'),
      qtd_mercados: find_total_count(convenience_items, 'mercado')
    }
  end

  def self.find_total_count(items, name)
    item = items.find { |i| i[:name] == name }
    item ? item[:total_count] : 0
  end
end