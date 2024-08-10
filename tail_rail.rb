require_relative 'log_tail'
require_relative 'log_watch_server'

LOG_FILE_PATH = 'log/development.log'.freeze

file = File.open(LOG_FILE_PATH)
queue = Queue.new

log_tail = LogTail.new(file, queue)
server = LogWatchServer.new(queue)

threads = []
threads << Thread.new { log_tail.tail }
threads << Thread.new { server.start }

trap('INT') do
  puts 'Shutting down...'
  server.instance_variable_get(:@server).shutdown if server.instance_variable_defined?(:@server)
  file.close
  threads.each(&:kill)
  threads.each(&:join)
  exit
end

threads.each(&:join)
