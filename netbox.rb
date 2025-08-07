require 'oxidized'

# --- CORREÇÃO AQUI ---
# Usamos o nome completo da classe: Oxidized::Source
class NetBox < Oxidized::Source
  def initialize
    super
    @cfg = @cfg.model_map["netbox"]
    @out = []
  end
  def setup
    return unless @cfg.has_key? "url"
    require "json"
    require "net/http"
    require "uri"
    require "openssl"
  end
  def load(node_want)
    get_devices
    @out
  end
  private
  def get_devices
    url = @cfg["url"]
    token = @cfg["token"]
    query = @cfg.has_key?("device_query") ? @cfg["device_query"] : {}
    map = @cfg["map"] || {}
    vars_map = @cfg["vars_map"] || {}
    url = url.chomp("/")
    query_str = query.map { |k, v| "#{k}=#{v}" }.join("&")
    uri = URI.parse("#{url}/api/dcim/devices/?#{query_str}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "httpss"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @cfg["insecure"]
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Token #{token}"
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    response = http.request(request)
    data = JSON.parse(response.body)
    data["results"].each do |device|
      next unless device.dig("status", "value") == "active"
      next unless device.has_key?("primary_ip") && device["primary_ip"]
      node = {}
      node[:name] = device[map["name"]] || device["name"]
      node[:ip] = device["primary_ip"]["address"].split("/").first
      if map.has_key?("model") && device.has_key?("platform") && device["platform"]
        node[:model] = device["platform"][map["model"]] || device["platform"]["slug"]
      end
      if map.has_key?("group") && device.has_key?("custom_fields") && device["custom_fields"].has_key?(map["group"].sub("cf_", ""))
        node[:group] = device["custom_fields"][map["group"].sub("cf_", "")]
      end
      node[:vars] = {}
      vars_map.each do |key, value|
        if value.is_a?(String) && value.start_with?("cf_")
          cf_key = value.sub("cf_", "")
          node[:vars][key.to_sym] = device["custom_fields"][cf_key] if device["custom_fields"]&.has_key?(cf_key)
        else
          node[:vars][key.to_sym] = value
        end
      end
      @out << node
    end
  end
end
