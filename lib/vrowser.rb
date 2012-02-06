# encoding: utf-8
require 'ruby-qstat'
require 'sequel'
require 'logger'
require 'retry-handler'
require 'active_support/core_ext'
require 'yaml'
require 'json'

module VrowserModel
  def self.connect(options={})
    Sequel::Model.plugin(:schema)
    Sequel.connect(options)
    self.define_models
    Servers.plugin :timestamps, :create=>:created_at, :update=>:updated_at
  end

  def self.define_models
    module_eval %{
      class Servers < Sequel::Model
        unless table_exists?
          set_schema do
            primary_key :id
            string :name
            string :host, :unique => true
            string :status
            integer :ping
            string :num_players
            string :type
            string :map
            string :players
            timestamp :created_at
            timestamp :updated_at
          end
          create_table
        end
      end
    }
  end
end

class Vrowser
  include VrowserModel

  @@logger = Logger.new(STDOUT)
  def self.logger=(logger)
    @@logger = logger
  end

  def self.qstat_path=(path)
    QStat.qstat_path = path
  end

  def self.update_serverlist(host, gametype, gamename, maxping)
    inserted = updated = 0

    servers = self.fetch_serverlist(host, gametype, gamename, maxping)
    servers.each{ |sv|
      if sv.rules.empty?
        game_type = "unknown"
      else
        game_type = sv.rules.first.game_tags.first
      end
      @@logger.info "game_type is #{game_type}"

      @@logger.info "finding hostname: #{sv.addr}"
      record = Servers.find(:host => sv.addr)
      @@logger.info "record result: #{record.inspect}"

      if record.nil?
        @@logger.info "new record for #{sv.addr}"
        Servers.insert(:name => sv.server_name, :host => sv.addr,
                       :status => sv.status, :ping => sv.ping, :num_players => sv.number_of_players,
                       :type => game_type, :map => sv.map, :players => sv.players.map(&:name).join(',')
                      )
                      inserted += 1
      else
        @@logger.info "already exist hostname, record update: #{sv.addr}"
        record.update(
          :name => sv.server_name, :status => sv.status, 
          :ping => sv.ping,
          #:num_players => sv.number_of_players,
          #:type => game_type,
          #:map => sv.map,
          #:players => sv.players.map(&:name).join(',')
        )
        updated += 1
      end
    }
    @@logger.info "updated exit: inserted:#{inserted}, updated:#{updated}"
    servers
  end

  def self.update_registered_all(protocol)
    updated = 0
    begin
      Servers.all.each{ |server|
        @@logger.info "trying to update: #{server.host}, #{server.name}"
        self.update(server.host, protocol)
        updated += 1
      }
    rescue
      @@logger.error $!
    ensure
      @@logger.info "updated #{updated} servers"
    end
  end

  def self.update_info_registered_all(protocol)
    updated = 0
    begin
      Servers.all.each{ |server|
        @@logger.info "trying to update_info: #{server.host}, #{server.name}"
        self.update_info(server.host, protocol)
        updated += 1
      }
    rescue
      @@logger.error $!
    ensure
      @@logger.info "updated #{updated} servers"
    end
  end

  def self.update(host, protocol)
    new_info = QStat.query(host, protocol)
    if new_info.nil? or new_info.no_response? or new_info.down?
      @@logger.info "server is downing"
      Servers.find(:host => host).update(:status => 'DOWN')
      return
    end

    new_info = self.before_update(new_info)
    @@logger.info "game_type is #{new_info.game_type}"

    record = Servers.find(:host => host)
    if record
      record.update(:name => new_info.server_name,
                    :status => 'UP', :ping => new_info.ping,
                    :num_players => new_info.number_of_players,
                    :type => new_info.game_type,
                    :map => new_info.map,
                    :players => new_info.players.map(&:name).join(','))
      @@logger.info "updated: #{new_info.addr}, #{new_info.server_name}"
    else
      @@logger.info "not found record: #{record.inspect.players}"
      @@logger.info "#{new_info.server_name}"
      Servers.insert(:host => new_info.addr, :name => new_info.server_name,
                     :status => 'UP', :ping => new_info.ping, :num_players => new_info.number_of_players,
                     :type => new_info.game_type, :map => new_info.map,
                     :players => new_info.players.map(&:name).join(','))
                     @@logger.info "inserted: #{new_info.addr}, #{new_info.server_name}"
    end
  end

  def self.before_update(server_info)
    server_info
  end

  def self.update_info(host, protocol)
    new_info = QStat.query_serverinfo(host, protocol)
    if new_info.nil? or new_info.no_response? or new_info.down?
      @@logger.info "server is downing"
      Servers.find(:host => host).update(:status => 'DOWN')
      return
    end

    new_info = self.before_update(new_info)
    @@logger.info "game_type is #{new_info.game_type}"

    record = Servers.find(:host => host)
    if record
      record.update(:name => new_info.server_name,
                    :status => 'UP', :ping => new_info.ping,
                    :type => new_info.game_type,
                    :map => new_info.map)
      @@logger.info "updated: #{new_info.addr}, #{new_info.server_name}"
    else
      @@logger.info "not found record: #{record.inspect.players}"
      @@logger.info "#{new_info.server_name}"
      Servers.insert(:host => new_info.addr, :name => new_info.server_name,
                     :status => 'UP', :ping => new_info.ping, 
                     :type => new_info.game_type, :map => new_info.map)
                     @@logger.info "inserted: #{new_info.addr}, #{new_info.server_name}"
    end
  end

  def self.servers
    Servers.all
  end

  def self.active_servers
    Servers.filter(:status => 'UP')
  end

  def self.remove_all
    o = Servers.delete
    @@logger.info "remove all records: #{o}"
  end

  def self.remove_debris
    records = Servers.filter(:status => 'DOWN')
    @@logger.info "remove debris: count #{records.count}"
    records.delete
    @@logger.info "removed"
  end

  def self.fetch_serverlist(host, gametype, gamename, maxping)
    proc{
      @@logger.info "try to fetch server list"
      return QStat.query_serverlist(host, gametype, gamename, maxping)
    }.retry(:accept_exception => StandardError, :logger => @@logger)
  rescue => ex
    @@logger.error "error: #{ex}"
    return []
  end

  def self.read_serverlist_from_xml(path)
    QStat.read_from_xml(path)
  end

  def self.debug_list
    Servers.all.each{ |server|
      puts "#{server.name}, #{server.host}"
    }
  end

  def self.update_server_types
    active_servers.each{ |sv|
      update(sv.host)
    }
  end

  def self.plugin_dir
    File.expand_path(File.join(File.dirname(__FILE__), "./plugins"))
  end

  def self.plugin_path(plugin_name)
    File.expand_path(File.join(self.plugin_dir, plugin_name + ".rb"))
  end

  def self.load_all_plugins
    self.load_plugins(self.plugin_dir)
  end

  def self.load_plugins(dir)
    Dir.entries(dir).each{ |entry|
      next if entry == "." or entry == ".."
      load File.join(dir, entry)
    }
  end

  def self.load_plugin(plugin_name)
    load self.plugin_path(plugin_name.to_s)
  end

  def self.load_config(config)
    raise ArgumentError.new("config['plugins']") unless config["plugins"]
    raise ArgumentError.new("config['qstat']") unless config["qstat"]
    raise ArgumentError.new("config['database']") unless config["database"]

    VrowserModel.connect(config["database"])

    config['plugins'].each{ |plugin_symbol|
      Vrowser.load_plugin plugin_symbol
    }

    Vrowser.new(config['qstat'].symbolize_keys)
  end

  def self.load_file(path)
    instance = self.load_config YAML.load_file(path)
    yield(instance) if block_given?
    instance
  end

  #### ==== instance methods
  def initialize(options={})
    @master_server = options[:master_server] or raise ArgumentError("master_server")
    @gametype = options[:gametype] or raise ArgumentError("gametype")
    @gamename = options[:gamename] or raise ArgumentError("gamename")
    @protocol = options[:protocol] or raise ArgumentError("protocol")
    @maxping  = options[:maxping] ||= 130
    yield(self) if block_given?
  end

  def fetch
    self.class.update_serverlist(@master_server, @gametype, @gamename, @maxping)
  end

  def update
    self.class.update_registered_all(@protocol)
  end

  def update_only_info
    self.class.update_info_registered_all(@protocol)
  end

  def clear
    self.class.remove_debris
  end

  def servers
    self.class.servers
  end

  def active_servers
    self.class.active_servers
  end
end
