class ReportGeneratorService < ApplicationService
  REPORT_PATH = '/tmp'

  def initialize
    @template_path = Rails.root.join('app/assets/templates')
  end

  def generate(item)
    report = ODFReport::Report.new("#{@template_path}/#{item[:name]}.odt") do |r|
      r.add_field :total_count, item[:total_count]
      r.add_field :closest_name, item[:closest][:name]
      r.add_field :closest_by_foot, item[:closest][:by_foot]
      r.add_field :closest_by_car, item[:closest][:by_foot]
      r.add_field :top_name, item[:top][:name]
      r.add_field :top_by_foot, item[:top][:by_foot]
      r.add_field :top_by_car, item[:top][:by_foot]

      r.add_table('TABLE', item[:items], header: true) do |t|
        t.add_column(:name) { |table_item| table_item[:name].to_s }
        t.add_column(:by_foot) { |table_item| table_item[:by_foot].to_s }
        t.add_column(:by_car) { |table_item| table_item[:by_car].to_s }
        t.add_column(:total_rating) { |table_item| table_item[:total_rating].to_s }
        t.add_column(:rating) { |table_item| table_item[:rating].to_s }
      end
    end

    file_path = generate_report_path
    report.generate(file_path)

    file_path.to_s
  end

  def generate_school(items)
    report = ODFReport::Report.new("#{@template_path}/ensino_other.odt") do |r|
      items.each do |item|
        r.add_table(item[:name].upcase, item[:items], header: true) do |t|
          t.add_column(:name) { |table_item| table_item[:name].to_s }
          t.add_column(:by_foot) { |table_item| table_item[:by_foot].to_s }
          t.add_column(:by_car) { |table_item| table_item[:by_car].to_s }
          t.add_column(:total_rating) { |table_item| table_item[:total_rating].to_s }
          t.add_column(:rating) { |table_item| table_item[:rating].to_s }
        end
      end
    end

    file_path = generate_report_path
    report.generate(file_path)

    file_path.to_s
  end

  def generate_transport(item)
    report = ODFReport::Report.new("#{@template_path}/transporte.odt") do |r|
      r.add_field :distancia_trabalho, item[:work_distance]
      r.add_field :car_peak, item[:duration_peak]
      r.add_field :car_nopeak, item[:duration_nopeak]

      r.add_table('TABLE_TRANSPORTE', item[:instructions_public], header: true) do |t|
        t.add_column(:step) { |table_item| table_item[:index].to_s }
        t.add_column(:dist) { |table_item| table_item[:distance].to_s }
        t.add_column(:instruction) { |table_item| table_item[:instruction].to_s }
      end
    end

    file_path = generate_report_path
    report.generate(file_path)

    file_path.to_s
  end

  private

  def generate_report_path
    filename = "new_property_report_#{Time.zone.now.strftime('%Y_%m_%d_%H_%M_%S')}_#{SecureRandom.uuid}.odt"
    "#{REPORT_PATH}/#{filename}"
  end
end
