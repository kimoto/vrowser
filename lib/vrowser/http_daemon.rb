# encoding: utf-8
# Author: kimoto
require 'vrowser'
require 'webrick'

class Vrowser::HTTPDaemon
  def self.start(options={})
    self.new(options) do |instance|
      instance.start
    end
  end

  public
  def initialize(options={})
    @config_path = options[:config_path] or raise ArgumentError("config_path")

    @server = WEBrick::HTTPServer.new(options)
    @server.mount_proc("/api/updated/json"){ |req, res|
      res.header["Content-Type"] = "application/json"
      res.body = get_active_servers_nary.to_json
    }
    @server.mount_proc("/api/connected/json"){ |req, res|
      res.header["Content-Type"] = "application/json"
      res.body = get_active_servers.to_json
    }

    yield(self) if block_given?
    self
  end

  def start
    @th = Thread.start do
      fetch_and_update @config_path
    end
    regist_stop
    @server.start
  end

  def daemonize!
    Process.daemon
  end

  def stop
    @server.shutdown if @server
    Thread.kill(@th) if @th
  end

  private
  def regist_stop
    trap("INT") do
      stop
    end
  end

  def fetch_and_update(config_path)
    Vrowser.load_file(config_path) do |vrowser|
      while true
        puts "update server list"
        vrowser.fetch

        (60 / 5).times do
          puts "try update"
          vrowser.update
          sleep (60 * 5)
        end
      end
    end
  end

  def get_active_servers
    Vrowser.load_file(@config_path){ |v|
      query = v.active_servers.select(:name, :host, :ping, :num_players, :type, :map, :players)
      return query.order(:host).map(&:values)
    }
    nil
  end

  def get_active_servers_nary
    get_active_servers.map(&:values)
  end
end

