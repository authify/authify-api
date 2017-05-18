module Authify
  module API
    # A place to store metrics data
    class Metrics
      include Singleton

      def update(key, value)
        write_lock do
          storage[key] = value
        end
      end

      def increment(key, change = 1)
        write_lock do
          storage.key?(key) ? storage[key] += change : storage[key] = change
        end
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

      private

      def write_lock
        @wlock ||= Mutex.new
        @wlock.synchronize do
          yield
        end
      end

      def storage
        # While not perfectly thread-safe, this works well enough for Metrics
        @storage ||= Concurrent::Map.new
      end
    end
  end
end
