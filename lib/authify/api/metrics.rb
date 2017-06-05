module Authify
  module API
    # A place to store metrics data
    class Metrics
      include Singleton

      def update(key, value)
        storage[key] = value
      end

      def increment(key, change = 1)
        storage.key?(key) ? storage[key] += change : storage[key] = change
      end

      def decrement(key, change = 1)
        increment(key, -1 * change)
      end

      def [](key)
        storage[key]
      end

      def time(key)
        timer = storage.key?(key) ? storage[key] : Hitimes::TimedMetric.new(key)
        result = timer.measure do
          yield
        end
        update(key, timer)
        result
      end

      def each(&block)
        storage.each(&block)
      end

      private

      def storage
        # While not perfectly thread-safe, this works well enough for Metrics
        @storage ||= Concurrent::Map.new
      end
    end
  end
end
