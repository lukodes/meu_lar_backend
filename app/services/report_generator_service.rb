class ReportGeneratorService < ApplicationService
  def initialize(path, items)
    @path = path
    @items = items
  end

  def call
    @top_rating_by_type = top_rating_by_type
    tables = build_tables
    tables = fill_table_values(tables, @items)

    report = ODFReport::Report.new(@path) do |r|
      r.add_field :dt_c, "2017"
      r.add_field :m1, rand(10.0..100.0).round(2)
      r.add_field :m2, rand(10.0..100.0).round(2)
      r.add_field :avg_price, rand(10.0..100.0).round(2)
      r.add_field :school_num, @items["school"].count
      r.add_field :hospital_num, @items["hospital"].count
      r.add_field :gym_num, @items["gym"].count
      r.add_field :market_num, @items["supermarket"].count
      r.add_field :gym_top_rating, @top_rating_by_type["gym"][:name]
      r.add_field :gym_top_rating_distance, @top_rating_by_type["gym"][:distance]
      r.add_field :gym_top_rating_time_walking, @top_rating_by_type["gym"][:time_walking]
      r.add_field :gym_top_rating_time_car, @top_rating_by_type["gym"][:time_car]
      r.add_field :market_top_rating, @top_rating_by_type["supermarket"][:name]
      r.add_field :market_top_rating_distance, @top_rating_by_type["supermarket"][:distance]
      r.add_field :market_top_rating_time_walking, @top_rating_by_type["supermarket"][:time_walking]
      r.add_field :market_top_rating_time_car, @top_rating_by_type["supermarket"][:time_car]
      r.add_field :closest_hospital, 'Hospital São Paulo'
      r.add_field :closest_hospital_distance, 13

      tables.each do |table|
        r.add_table(table[:name], table[:values]) do |t|
          table[:fields].each do |field|
            t.add_column(field.to_sym, field.to_sym)
          end
        end
      end
    end

    report.generate("#{Rails.root}/tmp/reports/new_property_report_#{Time.zone.now.strftime('%s%L')}.odt")
  end

  private

  def top_rating_by_type
    types = @items.keys

    top_rating_by_type = {}

    types.each do |type|
      top_rating_by_type[type] = {}
      ratings = @items[type].sort_by { |item| item.rating.to_i }
      top_rating_by_type[type][:name] = ratings.last.name
      top_rating_by_type[type][:distance] = ratings.last.json_result_object["distance"]
      top_rating_by_type[type][:time_walking] = ratings.last.json_result_object["walking_time"]
      top_rating_by_type[type][:time_car] = ratings.last.json_result_object["car_time"]
    end

    return top_rating_by_type
  end

  def build_tables
    tables = [
      {
        name: 'OVERVIEW',
        fields: ['type', 'name', 'walking_time', 'car_time', 'distance'],
        values: []
      },
      {
        name: 'DAY_CARE',
        fields: ['name', 'walking_time', 'car_time', 'rating', 'avg_price'],
        values: []
      },
      {
        name: 'M_SCHOOL',
        fields: ['name', 'walking_time', 'car_time', 'rating', 'avg_price'],
        values: []
      },
      {
        name: 'H_SCHOOL',
        fields: ['name', 'walking_time', 'car_time', 'rating', 'avg_price'],
        values: []
      },
      {
        name: 'COLLEGE',
        fields: ['name', 'walking_time', 'car_time', 'rating', 'avg_price'],
        values: []
      },
      {
        name: 'GYM',
        fields: ['name', 'walking_time', 'car_time', 'rating'],
        values: []
      },
      {
        name: 'MARKET',
        fields: ['name', 'walking_time', 'car_time', 'rating'],
        values: []
      },
      {
        name: 'HOSPITAL',
        fields: ['name', 'walking_time', 'car_time', 'rating', 'access'],
        values: []
      }
    ]
  end

  def build_table_values(table, item_of_this_kind)
    common_fields = ['name', 'walking_time', 'car_time', 'rating']

    table[:values] << {}
    common_fields.each do |field|
      if field.include?('time')
        table[:values].last[field] = item_of_this_kind.json_result_object[field]
      else
        table[:values].last[field] = item_of_this_kind[field.to_sym]
      end
    end

    table = treatment_by_type(table, item_of_this_kind)
  end

  def treatment_by_type(table, item_of_this_kind)
    case table[:name]
    when 'OVERVIEW'
      table[:values].last['type'] = item_of_this_kind['types'].first
      table[:values].last['distance'] = item_of_this_kind['json_result_object']['distance']
    when 'DAY_CARE', 'M_SCHOOL', 'H_SCHOOL', 'COLLEGE'
      table[:values].last['avg_price'] = rand(10.0..100.0).round(2)
    when 'HOSPITAL'
      table[:values].last['access'] = 'Particular'
    end

    return table
  end

  def fill_table_values(tables, items)
    item_of_kind = {
      'OVERVIEW' => items.map { |item| item.second.first },
      'DAY_CARE' => items['school'],
      'M_SCHOOL' => items['school'],
      'H_SCHOOL' => items['school'],
      'COLLEGE' => items['school'],
      'GYM' => items['gym'],
      'MARKET' => items['supermarket'],
      'HOSPITAL' => items['hospital']
    }

    tables.each do |table|
      item_of_kind[table[:name]].each do |spot|
        table = build_table_values(table, spot)
      end
    end
  end
end

# variables = :dt_c,
#             :m1,
#             :m2,
#             :avg_price,
#             :school_num,
#             :hospital_num,
#             :gym_num,
#             :market_num,
#             :gym_top_rating,
#             :gym_top_rating_distance,
#             :gym_top_rating_time_walking,
#             :gym_top_rating_time_car,
#             :market_top_rating,
#             :market_top_rating_distance,
#             :market_top_rating_time_walking,
#             :market_top_rating_time_car,
#             :closest_hospital,
#             :closest_hospital_distance

# 'OVERVIEW_TABLE', 'DAY_CARE_TABLE', 'M_SCHOOL_TABLE', 'H-SCHOOL_TABLE', 'COLLEGE_TABLE','GYM_TABLE', 'MARKET_TABLE', 'HOSPITAL_TABLE'
    
# OVERVIEW_TABLE = ['ov_type', 'ov_name', 'ov_walking_time', 'ov_car_time', 'ov_distance']
# DAY_CARE_TABLE = ['day_care_name', 'day_care_walking_time', 'day_care_car_time', 'day_care_rating', 'day_care_avg_price']
# M_SCHOOL_TABLE = ['m_SCHOOL_name', 'm_SCHOOL_walking_time', 'm_SCHOOL_car_time', 'm_SCHOOL_rating', 'm_SCHOOL_avg_price']
# H_SCHOOL_TABLE = ['h_SCHOOL_name', 'h_SCHOOL_walking_time', 'h_SCHOOL_car_time', 'h_SCHOOL_rating', 'h_SCHOOL_avg_price']
# COLLEGE_TABLE = ['COLLEGE_name', 'COLLEGE_walking_time', 'COLLEGE_car_time', 'COLLEGE_rating', 'COLLEGE_avg_price']
# GYM_TABLE = ['gym_name', 'gym_walking_time', 'gym_car_time', 'gym_rating']
# MARKET_TABLE = ['market_name', 'market_walking_time', 'market_car_time', 'market_rating']
# HOSPITAL_TABLE = ['hospital_name', 'hospital_walking_time', 'hospital_car_time', 'hospital_rating', 'hospital_access']

# r.add_table("GYM_TABLE", items, :header => true) do |t|
#   t.add_column(:name, :name)
#   t.add_column(:distance, :distance)
# end
