require 'webrick'
require 'fileutils'
require 'json'

class LogWatchServer
  def initialize(queue)
    @server = WEBrick::HTTPServer.new(
      Port: 4567,
      DocumentRoot: File.expand_path('public')
    )
    @queue = queue
  end

  def start
    @server.mount_proc '/log' do |_req, res|
      res.content_type = 'application/json'

      log_lines = []
      log_lines << @queue.pop until @queue.empty?

      parsed_logs = parse_logs(log_lines)
      res.body = JSON.generate(parsed_logs)
    end

    @server.start
  end

  def parse_logs(log_lines)
    parsed_logs = []
    request_lines = []
    start_time = nil
    end_time = nil
    host = nil
    method = nil
    status = nil
    controller = nil
    rendered = []

    log_lines.each do |line|
      if line.include?('Started GET')
        start_time = extract_time(line)
        method = line.split(' ')[1]
        host = line.split(' ')[3]
        request_lines = [line]
        rendered = [] # 新しいリクエストの開始時に初期化
      elsif line.include?('Processing by')
        controller = line.split('Processing by ')[1].split(' as ')[0]
        request_lines << line
      elsif line.include?('Rendered')
        rendered << line.split('Rendered ')[1].split(' (')[0]
        request_lines << line
      elsif line.include?('Completed')
        status = line.split(' ')[1]
        req_time = extract_time_from_completed(line)
        request_lines << line

        parsed_logs << {
          time: start_time,
          req_time: req_time,
          host: host,
          method: method,
          status: status,
          controller: controller,
          rendered: rendered
        }

        rendered = []
      else
        request_lines << line
      end
    end

    # parsed_logsが1つだけの時はそのハッシュを返す
    parsed_logs.length == 1 ? parsed_logs.first : parsed_logs
  end

  def extract_time(line)
    match = line.match(/for [\d.]+ at (.+)/)
    match[1] if match
  end

  def extract_time_from_completed(line)
    match = line.match(/Completed .+ in (\d+)ms/)
    "#{match[1]}ms" if match
  end

  # FIXME:
  # def extract_rendered_templates(line)
  #   # Regex to extract rendered templates
  #   matches = line.scan(/Rendered (.+?)(?: \()/)
  #   matches.flatten
  # end
end
