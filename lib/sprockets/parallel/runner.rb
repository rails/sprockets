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
            begin
              result.call
            rescue Exception => e
              result.exception = e
            end
          end
        end
        t.abort_on_exception = true
        t
      }

      def self.queue(job)
        @queue << job
      end

      def initialize(block = nil, &implicit_block)
        @job    = block || implicit_block
        @status = :created
        @result = nil
        @mutex  = Mutex.new
        @exception = nil
      end

      def exception=(e)
        @exception = e
      end

      def call
        @mutex.synchronize do
          run unless done?
        end
        @result
      end

      def done?
        @status == :done
      end

      def exec
        @status = :queued
        self.class.queue(self)
      end

      def finalize=(block)
        @finalize = block
      end

      def finalize
        raise "No finalize block specified" if @finalize.nil?
        if @exception
          first_line = @exception.backtrace.first
          @exception.set_backtrace([first_line] + caller)
        end
        @mutex.synchronize do
          run unless done?
        end
        @finalize.call(@result)
      end

      private def run
        @result = @job.call if @job
        @backtrace = nil
        @job    = nil
        @status = :done
      end
    end
  end
end
