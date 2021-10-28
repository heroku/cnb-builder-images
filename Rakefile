require "pathname"
require "toml-rb"
require 'json'
require 'excon'

def root_dir
  Pathname(__dir__)
end

class RegistryEntry
  attr_reader :ns, :name, :version, :yanked, :addr

  def initialize(ns: , name: , version: , yanked: , addr:)
    @ns = ns
    @name = name
    @version = version
    @yanked = yanked
    @addr = addr
  end

  def uri
    "docker://#{addr}"
  end

  def not_yanked?
    !yanked
  end
end

class RegistryFetcher
  def initialize(id)
    @namespace, @name = id.split("/")
    @response = nil
    @entries = []
    @thread = nil
  end

  def response
    @response ||= Excon.get(raw_url)
  end

  def success?
    response.status.to_s.start_with?("2")
  end

  def parse_line(line)
    JSON.parse(line, symbolize_names: true)
  rescue => e
    warn "Could not parse line #{line.inspect}, #{e.message}"
    # Ignore error and keep going
  end

  def last_entry(allow_yanked: false)
    entries.reverse.detect do |entry|
      next true if allow_yanked

      entry.not_yanked?
    end
  end

  def entries
    raise "Failed response Status: '#{response.status}' Body: '#{response.body}' url: '#{raw_url}'" unless success?
    return @entries if !@entries.empty?

    response.body.each_line do |line|
      hash = parse_line(line)
      next if hash.nil?
      @entries << RegistryEntry.new(**hash)
    end
    @entries
  end

  # Example:
  #
  #  RegistryFetcher.new("java").raw_url
  #  # => "https://raw.githubusercontent.com/buildpacks/registry-index/main/ja/va/heroku_java"
  def raw_url
    "https://raw.githubusercontent.com/buildpacks/registry-index/main/#{registry_path}"
  end

  # Example:
  #
  #  RegistryFetcher.new("java").registry_path
  #  # => "ja/va/heroku_java"
  def registry_path
    File.join(dir, "#{@namespace}_#{@name}")
  end

  def dir
    File.join(@name[0..1], @name[2..3])
  end
end

task "fetch:latest" do
  skip_array = ["heroku/go", "heroku/php", "heroku/python"]

  builder_files = ["builder-18.toml", "builder-20.toml"].map do |p|
    root_dir.join(p).expand_path
  end

  # De-dup ids, create fetcher objects
  fetcher_for_id = {}
  builder_files.flat_map do |path|
    TomlRB.load_file(path).fetch("buildpacks").each do |hash|
      id = hash["id"]
      fetcher_for_id[id] = RegistryFetcher.new(id)
    end
  end

  builder_files.each do |path|
    toml_hash = TomlRB.load_file(path)

    toml_hash["buildpacks"].map! do |hash|
      id = hash["id"]
      next hash if skip_array.include?(id)
      hash["uri"] = fetcher_for_id[id].last_entry.uri
      hash
    end

    toml_hash["order"].map! do |order_hash|
      order_hash["group"].map! do |hash|
        id = hash["id"]
        next hash if skip_array.include?(id)
        hash["version"] = fetcher_for_id[id].last_entry.version
        hash
      end
      order_hash
    end

    puts toml_hash
    path.write(TomlRB.dump(toml_hash))
  end
end
