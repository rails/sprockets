$:.unshift "/Volumes/GitHub/sprockets/lib"
$:.unshift "/Users/josh/.rip/sprockets/lib"

require 'sprockets'
require 'sprockets/errors'

env = Sprockets::Environment.new(".")
env.paths << File.expand_path("../test/fixtures/default", __FILE__)
env.static_root = File.expand_path("../test/fixtures/public", __FILE__)

def dtruss(&block)
  pid = fork do
    sleep 3
    block.call
  end

  fork do
    exec "dtruss", "-p", pid.to_s
  end

  Process.wait pid
  system "killall", "dtrace"
end

env["application.js"]

dtruss do
  env.path("application.js")
end
