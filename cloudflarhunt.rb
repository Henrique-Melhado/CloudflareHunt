#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'
require 'optparse'
require 'set'

# A class to encapsulate the logic for fetching DNS history from SecurityTrails.
class SecurityTrailsClient
  API_URL = 'https://api.securitytrails.com/v1'.freeze

  def initialize(api_key)
    @api_key = api_key
    raise ArgumentError, 'SecurityTrails API key is required.' if @api_key.nil? || @api_key.empty?
  end

  # Fetches the DNS A record history for a given domain.
  def fetch_history(domain)
    uri = URI.parse("#{API_URL}/history/#{domain}/dns/a")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['APIKEY'] = @api_key
    request['Accept'] = 'application/json'

    response = http.request(request)
    handle_response(response)
  rescue StandardError => e
    warn "An unexpected network error occurred: #{e.message}"
    nil
  end

  private

  # Handles the HTTP response from the API.
  def handle_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    when Net::HTTPUnauthorized
      warn "Error: Authentication failed. Please check your API key."
      nil
    when Net::HTTPNotFound
      warn "Error: Domain not found or no history available for it."
      nil
    else
      warn "Error fetching data: #{response.code} #{response.message}"
      warn "Response body: #{response.body}"
      nil
    end
  rescue JSON::ParserError
    warn "Error: Failed to parse JSON response from the API."
    nil
  end
end

# A class to format and display the DNS history.
class HistoryPresenter
  def initialize(data, domain)
    @data = data
    @domain = domain
  end

  def print
    if @data.nil? || @data['records'].nil? || @data['records'].empty?
      puts "No history found for #{@domain}"
      return
    end

    puts "DNS A Record History for #{@domain}:"
    puts "-----------------------------------"

    ip_addresses = Set.new

    @data['records'].each do |record|
      record['values'].each do |value|
        ip = value['ip']
        ip_addresses.add(ip)
        first_seen = record['first_seen']
        last_seen = record['last_seen']
        puts "IP: #{ip.ljust(15)} | First Seen: #{first_seen} | Last Seen: #{last_seen}"
      end
    end

    return if ip_addresses.empty?

    puts "\nSummary of unique IP addresses:"
    ip_addresses.each do |ip|
      puts "- #{ip}"
    end
  end
end

# Main application logic that parses arguments and coordinates the objects.
class CloudflareHuntApp
  BANNER = <<~'BANNER'
    ______ _                 ______ _     _   _            _
   / _____) |               / _____) |   | | | |          | |
  / /     | | ___  _   _  _ | /     | |___| |_| | ___    _ | |
 | |     | |/ _ \| | | |/ || |     |  ___)  _  |/ _ \  / || |
 | \_____| | |_| | |_| ( (_| \_____| |   | | | | |_| |( (_| |
  \______)_|\___/ \____|\_)\______)|_|   |_| |_|\___/  \____|

               CLOUDFLARE DNS History and IP Address Analyzer
                   Author: Henrique-Me

                             |
                          *******
                           *****
                            ***
                             *
BANNER

  def self.print_banner
    puts BANNER
  end

  def self.run
    print_banner
    options = { api_key: ENV['SECURITYTRAILS_API_KEY'] }

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] <domain>"
      opts.on("-k", "--api-key KEY", "SecurityTrails API Key (overrides SECURITYTRAILS_API_KEY env var)") do |key|
        options[:api_key] = key
      end
      opts.on("-h", "--help", "Prints this help") do
        puts opts
        exit
      end
    end

    parser.parse!

    domain = ARGV[0]

    if domain.nil? || domain.empty?
      warn "Error: Domain is a required argument."
      warn parser
      exit 1
    end

    unless options[:api_key]
      warn "Error: SECURITYTRAILS_API_KEY not set."
      warn "Set it as an environment variable or use the -k/--api-key flag."
      warn "Get a free API key from https://securitytrails.com/corp/api"
      exit 1
    end

    puts "Fetching history for #{domain}..."
    client = SecurityTrailsClient.new(options[:api_key])
    history_data = client.fetch_history(domain)

    return unless history_data

    presenter = HistoryPresenter.new(history_data, domain)
    presenter.print
  end
end

if __FILE__ == $PROGRAM_NAME
  CloudflareHuntApp.run
end
else
  module CloudflareHuntApp
end