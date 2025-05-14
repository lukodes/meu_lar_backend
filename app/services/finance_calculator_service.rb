class FinanceCalculatorService
  def self.calculate_sac(valor_imovel)
    percentual_renda = 0.30
    percentual_entrada = 0.20
    taxa_juros = 0.11
    meses = 420

    valor_entrada = valor_imovel * percentual_entrada
    valor_financiado = valor_imovel - valor_entrada
    amortizacao_mensal = valor_financiado / meses
    valor_primeira_parcela = valor_financiado * (taxa_juros / 12) + amortizacao_mensal
    valor_renda = valor_primeira_parcela / percentual_renda
    valor_ultima_parcela = (valor_financiado - amortizacao_mensal * (meses - 1)) * (taxa_juros / 12) + amortizacao_mensal
    valor_total_pago = (valor_primeira_parcela + valor_ultima_parcela) / 2 * meses
    valor_total_juros = valor_total_pago - valor_financiado

    {
      valor_imovel: format_currency(valor_imovel),
      valor_entrada: format_currency(valor_entrada),
      valor_financiado: format_currency(valor_financiado),
      valor_primeira_parcela: format_currency(valor_primeira_parcela),
      valor_ultima_parcela: format_currency(valor_ultima_parcela),
      valor_total_financiamento: format_currency(valor_financiado),
      valor_renda: format_currency(valor_renda),
      valor_total_juros: format_currency(valor_total_juros),
      valor_total_pago: format_currency(valor_total_pago + valor_entrada)
    }
  end

  def self.format_currency(value)
    ActionController::Base.helpers.number_to_currency(value, unit: 'R$ ', separator: ',', delimiter: '.')
  end
end