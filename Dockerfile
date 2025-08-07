# Dockerfile Definitivo - Método de Criação Direta do Plugin NetBox

# 1. Inicia com a imagem oficial e estável.
FROM oxidized/oxidized:latest

# 2. Cria o diretório exato onde o Oxidized procura por plugins de fonte de dados.
RUN mkdir -p /home/oxidized/.config/oxidized/source/

# 3. Cria o arquivo netbox.rb com o conteúdo completo do plugin.
# Este comando 'echo' escreve o código Ruby diretamente no arquivo.
# Este método é garantido e não depende de downloads.
RUN echo '#
# Author: Josh M.
# Email: josh@joshm.us
#
# This is a NetBox source for Oxidized
#
# HOW TO USE:
# 1. Create a custom field for devices in NetBox with the name ''oxidized_group''
#    and a type of "Selection". Add your Oxidized groups to the selection.
#    This will give you a dropdown menu on your devices to select a group.
#
# 2. If you have devices with different login credentials or other variations,
#    create groups in your Oxidized config that match the values from the
#    dropdown menu you created in NetBox.
#
# 3. Add the following to your Oxidized config, along with any other config options:
#
# source:
#   default: netbox
#   netbox:
#     url: https://your_netbox_url
#     token: your_netbox_token
#     device_query:
#       # This is a query that will be passed to pynetbox.
#       # You can use any filter that pynetbox supports.
#       # For example, to get all devices with the status "active":
#       status: "active"
#     map:
#       # These are the default mappings.
#       # You can override them here.
#       name: name
#       ip: primary_ip4.address
#       model: platform.slug
#       group: cf_oxidized_group
#
class NetBox < Source
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

    # Check if the URL has a trailing slash and remove it
    url = url.chomp("/")

    # Check for custom fields in the map
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
      next unless device["status"]["value"] == "active"

      # Map device attributes to Oxidized node attributes
      # The order of precedence is:
      # 1. map
      # 2. default
      node = {}
      # map name
      node[:name] = device[map["name"]] || device["name"]
      # map ip
      node[:ip] = map_ip(device)
      # map model
      node[:model] = device["platform"] ? (device["platform"][map["model"]] || device["platform"]["slug"]) : nil if map.has_key?("model")
      # map group
      node[:group] = device["custom_fields"][map["group"].sub("cf_", "")] if map.has_key?("group") && device.has_key?("custom_fields") && device["custom_fields"].has_key?(map["group"].sub("cf_", ""))

      # map vars
      node[:vars] = {}
      if @cfg.has_key?("vars_map")
        @cfg["vars_map"].each do |key, value|
          if value.is_a?(String) && value.start_with?("cf_")
            node[:vars][key.to_sym] = device["custom_fields"][value.sub("cf_", "")] if device["custom_fields"].has_key?(value.sub("cf_", ""))
          else
            node[:vars][key.to_sym] = value
          end
        end
      end

      @out << node
    end
  end

  def map_ip(device)
    # Check for primary_ip first
    if device.has_key? "primary_ip" and not device["primary_ip"].nil?
      return device["primary_ip"]["address"].split("/").first
    # Fallback to name if we dont have a primary_ip
    elsif device.has_key? "name" and not device["name"].nil?
      return device["name"]
    end
  end
end
' > /home/oxidized/.config/oxidized/source/netbox.rb
