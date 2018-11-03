require 'date'
require 'json'

def read_data
	File.open("data/input.json", "r") do |f|
		return JSON.parse(f.read)
	end
end

def get_delivery_lead data, carrier
	data["carriers"].find{ |c| c['code'] == carrier }["delivery_promise"]
end

def compute_output data, package
	lead = get_delivery_lead data, package["carrier"]
	{
		"package_id" => package["id"],
		"expected_delivery" => compute_delivery(package["shipping_date"], lead)
	}
end

def compute_delivery expedition_date, lead_time
	date = Date.parse(expedition_date)
	date += 1 + lead_time
end


if __FILE__ == $0
	data = read_data
	deliveries = data["packages"].map{|p| compute_output data, p }
	output = { "deliveries" => deliveries }
	File.open("data/output.json", "w") do |f|
		f.write(JSON.pretty_generate(output))
	end
end
