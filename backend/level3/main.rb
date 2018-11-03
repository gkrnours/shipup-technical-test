require 'date'
require 'json'


# A specific carrier, taking care of returning correct delivery time
class Carrier
	def initialize carrier, country_distance
		@carrier = carrier
		@country_distance = country_distance
	end

	# take a package, return a delivery date and an oversea delay
	def ship package
		oversea_delay = get_oversea_delay package
		lead = @carrier["delivery_promise"] + oversea_delay
		date = Date.parse(package["shipping_date"])
		date = advance_date date

		# Decrease lead time while increasing delivery date
		while 0 < lead
			date = advance_date date
			lead -= 1
		end
		return date, oversea_delay
	end

	def get_oversea_delay package
		from, to = package["origin_country"], package["destination_country"]
		distance = @country_distance[from][to]
		oversea_delay = distance / @carrier["oversea_delay_threshold"]
		return oversea_delay
	end

	# If date is not delivered by carrier, push it to a shipping day
	def advance_date date
		date += 1
		date += 1 if date.saturday? and not @carrier["saturday_deliveries"]
		date += 1 if date.sunday?
		date
	end
end


# Take a package, find the related carrier, ship it
class Shipper
	def initialize carriers
		@carriers = carriers
	end

	def ship package
		carrier = @carriers[package["carrier"]]
		carrier.ship package
	end
end


# read and parse input data
def read_data
	json = nil
	File.open("data/input.json", "r") do |f|
		json = JSON.parse(f.read)
	end
	carriers = {}
	json["carriers"].each do |c|
		carriers[c["code"]] = Carrier.new(c, json["country_distance"])
	end
	return Shipper.new(carriers), json["packages"]
end


# Compute one entry of the deliveries list
def compute_output package, shipper
	date, oversea = shipper.ship package
	{
		"package_id" => package["id"],
		"expected_delivery" => date,
		"oversea_delay" => oversea
	}
end


if __FILE__ == $0
	shipper, packages = read_data
	# Compute all deliveries
	deliveries = packages.map{|p| compute_output p, shipper }
	output = { "deliveries" => deliveries }
	# write to file
	File.open("data/output.json", "w") do |f|
		f.write(JSON.pretty_generate(output))
	end
end
