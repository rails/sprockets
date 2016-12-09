require 'thread'

module Sprockets
  module Parallel
    class Runner
      @queue   = Queue.new
      @poision = Object.new

      @thread_pool = 5.times.map {
        t = Thread.new do
          loop do
            result = @queue.pop
            break if result == @poision
            result.call
          end
        end
        t.abort_on_exception = true
        t
      }

      def self.queue(job)
        @queue << job
      end

      def initialize(block, &implicit_block)
        @job    = block || implicit_block
        @status = :created
        @result = nil
      end

      def call
        @result = @job.call if @job
        @job    = nil
        @status = :done
        @result
      end

      def done?
        @status == :done
      end

      def wait_until_done!
        until done?
          sleep 0.01
        end
      end

      def exec
        @status = :queued
        self.class.queue(self)
      end

      def finalize(block = nil, &implicit_block)
        block = block || implicit_block
        if block
          @finalize = block
        else
          wait_until_done!
          raise "No finalize block specified" if @finalize.nil?
          @finalize.call(@result)
        end
      end
    end
  end
end
