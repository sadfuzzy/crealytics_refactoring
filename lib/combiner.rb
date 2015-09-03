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

	def combine(*enumerators)
		Enumerator.new do |yielder|
			last_values = Array.new(enumerators.size)
			done = enumerators.compact.empty?

			while not done
				set_empty_values(last_values, enumerators)

				done = (enumerators + last_values).compact.empty?
				unless done
					keys = last_values.map { |value| key(value) }
					min_key = keys.min do |left, right|
						if !left && !right
							0
						elsif !left
							1
						elsif !right
							-1
						else
							left <=> right
						end
					end

					values = Array.new(last_values.size)

					last_values.each_with_index do |value, index|
						if key(value) == min_key
							values[index] = value
							last_values[index] = nil
						end
					end

					yielder.yield(values)
				end
			end
		end
	end
end
