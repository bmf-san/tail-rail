class LogTail
  def initialize(file, queue)
    @file = file
    @log_queue = queue
    @buffer = ''
  end

  def tail
    @file.seek(0, IO::SEEK_END)
    loop do
      readable, = IO.select([@file])
      next unless readable

      lines = @file.readlines
      lines.each do |line|
        line.include?('Completed')
        @log_queue.push(line)
        @buffer = ''
      end
    end
  end
end
