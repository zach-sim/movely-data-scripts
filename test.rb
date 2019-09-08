565300 - homedale
573000 - lambton

require 'csv';

csv = CSV.read('../data/commuting_matrix2013.csv', headers: true); 0
csv.select{|row| row['AU'] == "565300"}.first['573000']

homedale = AreaUnit.select(:id, :name, 'ST_GeneratePoints(shape::geometry, 1) as point').find(565300)
lambton = AreaUnit.select(:id, :name, 'ST_GeneratePoints(shape::geometry, 1) as point').find(573000)

174.8596482727035, -36.93487397548026
174.8596482727035, -36.93487397548026
.point.first.y


-36.940427061410695
irb(main):038:0> homedale.point.first.x
=> 174.85500078351004


main):039:0> lambton.point.first.x
=> 174.85500078351004
irb(main):040:0> lambton.point.first.y
=> -36.940427061410695

174.9589312429465, -41.26869197989043
174.77384986947828, -41.28993165052001

curl -X POST \
'https://api.openrouteservice.org/v2/directions/driving-car/geojson' \
-H 'Content-Type: application/json' \
-H 'Accept: application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8' \
-H 'Authorization: 5b3ce3597851110001cf6248745d18584e3b4c2796180b3ee90ff48b' \
-d '{"coordinates":[[174.9589312429465, -41.26869197989043],[174.77384986947828, -41.28993165052001]]}'



values = {"coordinates":[
  [homedale.point.first.x, homedale.point.first.y],
  [lambton.point.first.x, lambton.point.first.y]
]}.to_json

headers = {
  accept: 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
  Authorization: '5b3ce3597851110001cf6248745d18584e3b4c2796180b3ee90ff48b',
  content_type: 'application/json',
}

types = {
  'driving-car': :car,
  'cycling-road': :cycle,
  'foot-walking': :walk,
}

response = RestClient.post 'https://api.openrouteservice.org/v2/directions/driving-car/geojson', values, headers
response = RestClient.post 'https://api.openrouteservice.org/v2/directions/cycling-road/geojson', values, headers

https://api.openrouteservice.org/v2/directions/foot-walking/geojson

res = JSON.parse(response.body);

duration = res['features'].first['properties']['summary']['duration']
coords = res['features'].first['geometry']['coordinates']

step = duration/coords.length

outputRow = {
  path: coords,
  timestamps: (step..duration).step(step).to_a,
}



class CommuteBreakdown < ActiveRecord::Base
  self.table_name = 'ur_to_wp_by_mode_of_travel_all_au_v3'

  establish_connection(
    adapter: "sqlite3",
    database: "db/statsNz.sqlite"
  )
end

types = {
  'cycling-road': :bicycle,
  'foot-walking': :walk,
  'driving-car': :car,
}
fromAUs = [
  573000,
  573101,
  573300,
  575701,
  575300,
  573200,
  576500,
  573400,
  572900,
]

aus = AreaUnit.select(:id, :name, 'ST_GeneratePoints(shape::geometry, 1) as point')
headers = {
  accept: 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
  Authorization: '5b3ce3597851110001cf6248745d18584e3b4c2796180b3ee90ff48b',
  content_type: 'application/json',
}

test = []




# ratiod import of bike, walking, cycle in inner city.
CommuteBreakdown.where(AU2013_V1_00_UR: fromAUs).select(:AU2013_V1_00_UR, :AU2013_V1_00_WP, :total, :merged_car, :bicycle, :walked_or_jogged).each do |row|
  from_au = aus.where(id: row.AU2013_V1_00_UR).first
  to_au = aus.where(id: row.AU2013_V1_00_WP).first

  counts = row.slice(:Bicycle, :Walked_or_Jogged, :merged_car)
  min = counts.values.reject(&:zero?).min

  next if [min, from_au, to_au].any?(&:nil?)

  counts.values.each_with_index do |val, idx|
    type = types.values[idx]
    api_type = types.keys[idx]

    done = Direction.where(from_au_id: from_au.id, to_au_id: to_au.id, type: type).count
    expected = val/min
    todo = expected - done
    test << todo
    todo.times do
      loop do
        from_au = aus.where(id: row.AU2013_V1_00_UR).first
        to_au = aus.where(id: row.AU2013_V1_00_WP).first
        break unless from_au.point.first.equals?(to_au.point.first)
      end


      req_data = {"coordinates":[[from_au.point.first.x, from_au.point.first.y],[to_au.point.first.x, to_au.point.first.y]]}.to_json
      response = RestClient.post "https://api.openrouteservice.org/v2/directions/#{api_type}/geojson", req_data, headers

      res = JSON.parse(response.body);
      shape = RGeo::GeoJSON.decode(res['features'].first['geometry'])
      data = res['features'].first['properties']

      Direction.create!(from_au_id: from_au.id, to_au_id: to_au.id, path: shape, data: data, type: type)
    end
  end

  # counts.values.map do |v|
  #   test << (v/min)
  # end
end


# Single car trip from each outher area unit to inner city
api_type = 'driving-car'
type = :car
test = 0
CommuteBreakdown.where.not(AU2013_V1_00_UR: fromAUs).where(AU2013_V1_00_WP: fromAUs).where('merged_car > 0').each do |row|
  from_au = aus.where(id: row.AU2013_V1_00_UR).first
  to_au = aus.where(id: row.AU2013_V1_00_WP).first
  next if [from_au, to_au].any?(&:nil?)

  done = Direction.where(from_au_id: from_au.id, to_au_id: to_au.id, type: type).count
  next if done > 0

  loop do
    from_au = aus.where(id: row.AU2013_V1_00_UR).first
    to_au = aus.where(id: row.AU2013_V1_00_WP).first
    break unless from_au.point.first.equals?(to_au.point.first)
  end

  req_data = {"coordinates":[[from_au.point.first.x, from_au.point.first.y],[to_au.point.first.x, to_au.point.first.y]]}.to_json
  response = RestClient.post "https://api.openrouteservice.org/v2/directions/#{api_type}/geojson", req_data, headers

  res = JSON.parse(response.body);
  shape = RGeo::GeoJSON.decode(res['features'].first['geometry'])
  data = res['features'].first['properties']

  Direction.create!(from_au_id: from_au.id, to_au_id: to_au.id, path: shape, data: data, type: type)
end













8am +- 2.hours.random

output = []
Direction.car.find_each do |row|
  coords = row.path.coordinates
  duration = row.data['summary']['duration']
  steps = row.data['segments'].first['steps']
  timestamps = []

  finish_time = rand(9000..16050)
  start_time = finish_time - duration

  timestamps << start_time
  steps.flat_map do |a|
    parts = (a['way_points'][1] - a['way_points'][0])
    dur = a['duration'] / parts
    parts.times.map{ dur }
  end.each do |time|
    start_time += time
    timestamps << start_time
  end

  output << {
    path: coords,
    timestamps: timestamps
  }
end
File.open("public/cars.json","w") do |f|
  f.write(output.to_json)
end





output = []
Direction.car.find_each do |row|
  coords = row.path.coordinates
  duration = row.data['summary']['duration']
  steps = row.data['segments'].first['steps']
  timestamps = []

  finish_time = rand(9000..16050)
  start_time = finish_time - duration

  timestamps << start_time
  steps.flat_map do |a|
    parts = (a['way_points'][1] - a['way_points'][0])
    dur = a['duration'] / parts
    parts.times.map{ dur }
  end.each do |time|
    start_time += time
    timestamps << start_time
  end

  output << {
    path: coords,
    timestamps: timestamps
  }
end
File.open("public/cars.json","w") do |f|
  f.write(output.to_json)
end


output = []
Direction.bicycle.find_each do |row|
  coords = row.path.coordinates
  duration = row.data['summary']['duration']
  steps = row.data['segments'].first['steps']
  timestamps = []

  finish_time = rand(9000..16050)
  start_time = finish_time - duration

  timestamps << start_time
  steps.flat_map do |a|
    parts = (a['way_points'][1] - a['way_points'][0])
    dur = a['duration'] / parts
    parts.times.map{ dur }
  end.each do |time|
    start_time += time
    timestamps << start_time
  end

  output << {
    path: coords,
    timestamps: timestamps
  }
end
File.open("public/bicycle.json","w") do |f|
  f.write(output.to_json)
end

output = []
Direction.walk.find_each do |row|
  coords = row.path.coordinates
  duration = row.data['summary']['duration']
  steps = row.data['segments'].first['steps']
  timestamps = []

  finish_time = rand(9000..16050)
  start_time = finish_time - duration

  timestamps << start_time
  steps.flat_map do |a|
    parts = (a['way_points'][1] - a['way_points'][0])
    dur = a['duration'] / parts
    parts.times.map{ dur }
  end.each do |time|
    start_time += time
    timestamps << start_time
  end

  output << {
    path: coords,
    timestamps: timestamps
  }
end
File.open("public/walk.json","w") do |f|
  f.write(output.to_json)
end



mult = {}
output = {}

fromAUs = [
  573000,
  573101,
  573300,
  575701,
  575300,
  573200,
  576500,
  573400,
  572900,
]
aus = AreaUnit.select(:id, :name, 'ST_GeneratePoints(shape::geometry, 1) as point')
mult = {};
CommuteBreakdown.where(AU2013_V1_00_UR: fromAUs).select(:AU2013_V1_00_UR, :AU2013_V1_00_WP, :total, :merged_car, :bicycle, :walked_or_jogged).each do |row|
  from_au = aus.where(id: row.AU2013_V1_00_UR).first
  to_au = aus.where(id: row.AU2013_V1_00_WP).first

  counts = row.slice(:Bicycle, :Walked_or_Jogged, :merged_car)
  min = counts.values.reject(&:zero?).min

  next if [min, from_au, to_au].any?(&:nil?)
  mult[from_au.id] = {} unless mult[from_au.id]
  mult[from_au.id][to_au.id] = min
end
CommuteBreakdown.where.not(AU2013_V1_00_UR: fromAUs).where(AU2013_V1_00_WP: fromAUs).where('merged_car > 0').each do |row|
  from_au = aus.where(id: row.AU2013_V1_00_UR).first
  to_au = aus.where(id: row.AU2013_V1_00_WP).first
  next if [from_au, to_au].any?(&:nil?)

  done = Direction.where(from_au_id: from_au.id, to_au_id: to_au.id, type: :car).count
  next if done.zero?

  mult[from_au.id] = {} unless mult[from_au.id]
  mult[from_au.id][to_au.id] = row.merged_car
end
Direction.find_each do |d|
  coords = d.path.coordinates
  duration = d.data['summary']['duration'] # in seconds
  steps = d.data['segments'].first['steps']
  timestamps = [0]
  start_time = 0
  steps.flat_map do |a|
    parts = (a['way_points'][1] - a['way_points'][0])
    dur = a['duration'] / parts
    parts.times.map{ dur }
  end.each do |time|
    start_time += time
    timestamps << start_time
  end

  output[d.type] = [] unless output[d.type]
  output[d.type] << {
    path: coords,
    timestamps: timestamps,
    multiply: mult[d.from_au_id][d.to_au_id]
  }
end

File.open("public/2013.json","w") do |f|
  f.write(output.to_json)
end
