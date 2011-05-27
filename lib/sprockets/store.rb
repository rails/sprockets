require 'multi_json'

module Sprockets
  class Store
    def initialize(store)
      @store = store
    end

    def [](key)
      value = if @store.respond_to?(:get)
        @store.get(key)
      elsif @store.respond_to?(:[])
        @store[key]
      elsif @store.respond_to?(:read)
        @store.read(key)
      else
        nil
      end

      if value.is_a?(String)
        MultiJson.decode(value)
      end
    end

    def []=(key, value)
      if @store.respond_to?(:set)
        @store.set(key, value.to_json)
      elsif @store.respond_to?(:[]=)
        @store[key] = value.to_json
      elsif @store.respond_to?(:write)
        @store.write(key, value.to_json)
      else
        nil
      end

      value
    end
  end
end
