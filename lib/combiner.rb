# input:
# - two enumerators returning elements sorted by their key
# - block calculating the key for each element
# - block combining two elements having the same key or a single element, if there is no partner
# output:
# - enumerator for the combined elements
class Combiner

	def initialize(&key_extractor)
		@key_extractor = key_extractor
	end

	def key(value)
		@key_extractor.call(value) if value
	end

	def set_empty_values(values=nil, enumerators=nil)
		values.each_with_index do |value, index|
			if enumerators[index] && !value
				begin
					values[index] = enumerators[index].next
				rescue StopIteration
					enumerators[index] = nil
				end
			end
		end
	end

	def get_min_key(keys)
		keys.min do |left, right|
			case
			when !left && !right then 0
			when !left then 1
			when !right then -1
			else left <=> right
			end
		end
	end

	def finished?(enumerators)
		enumerators.compact.empty?
	end

	def set_values_from_last(min_key, values, last_values)
		last_values.each_with_index do |value, index|
			if key(value) == min_key
				values[index] = value
				last_values[index] = nil
			end
		end
	end

	def combine(*enumerators)
		Enumerator.new do |yielder|
			last_values = Array.new(enumerators.size)
			done = finished?(enumerators)

			while not done
				set_empty_values(last_values, enumerators)
				done = finished?(enumerators + last_values)
				values = Array.new(last_values.size)

				unless done
					keys = last_values.map { |value| key(value) }
					min_key = get_min_key(keys)
					set_values_from_last(min_key, values, last_values)

					yielder.yield(values)
				end
			end
		end
	end
end
