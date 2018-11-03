require 'date'
require 'json'

class Shipper
	def initialize carrier_list
		@carriers = {}
		carrier_list.each { |c| @carriers[c['code']] = c }
	end

	# take a package, return a delivery date
	def ship package
		date = Date.parse(package["shipping_date"])
		carrier = @carriers[package["carrier"]]
		lead = carrier["delivery_promise"]
		date = advance_date date, carrier

		# Decrease lead time while increasing delivery date
		while 0 < lead
			date = advance_date date, carrier
			lead -= 1
		end
		date
	end

	# If date is not delivered by carrier, push it to a shipping day
	def advance_date date, carrier
		date += 1
		date += 1 if date.saturday? and not carrier["saturday_deliveries"]
		date += 1 if date.sunday?
		date
	end
end


def read_data
	json = nil
	File.open("data/input.json", "r") do |f|
		json = JSON.parse(f.read)
	end
	return json["carriers"], json["packages"]
end

def compute_output package, shipper
	{
		"package_id" => package["id"],
		"expected_delivery" => shipper.ship(package),
	}
end

if __FILE__ == $0
	carriers, packages = read_data
	shipper = Shipper.new(carriers)
	deliveries = packages.map{|p| compute_output p, shipper }
	output = { "deliveries" => deliveries }
	File.open("data/output.json", "w") do |f|
		f.write(JSON.pretty_generate(output))
	end
end
