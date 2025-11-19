#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'uri'

# # Description: Fetches DNS and IP history for a domain using the SecurityTrails API.
# Usage: ruby cloudflare_history.rb <domain>
#
# To use this script, you need a Security Trails API key.
# 1. Go to https://securitytrails.com/corp/api and sign up for a free account.
# 2. Get your API key from your account dashboard.
# 3. Set the API key as an environment variable:
#    export SECURITYTRAILS_API_KEY='your_api_key'
# echo "export SECURITYTRAILS_API_KEY='your_api_key'" >> ~/.zshrc

API_KEY = ENV['SECURITYTRAILS_API_KEY']
API_URL = 'https://api.securitytrails.com/v1'

def fetch_history(domain)
  unless API_KEY
    puts "Error: SECURITYTRAILS_API_KEY environment variable not set."
    puts "Please get a free API key from https://securitytrails.com/corp/api"
    exit 1
  end

  uri = URI.parse("#{API_URL}/history/#{domain}/dns/a")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri.request_uri)
  request['APIKEY'] = API_KEY
  request['Accept'] = 'application/json'

  response = http.request(request)

  if response.code == '200'
    JSON.parse(response.body)
  else
    puts "Error fetching data from Security Trails: #{response.code} #{response.message}"
    puts "Response body: #{response.body}"
    nil
  end
end

def print_history(data, domain)
  if data.nil? || data['records'].nil? || data['records'].empty?
    puts "No history found for #{domain}"
    return
  end

  puts "DNS A Record History for #{domain}:"
  puts "-----------------------------------"

  ip_addresses = []

  data['records'].each do |record|
    record['values'].each do |value|
      ip = value['ip']
      ip_addresses << ip unless ip_addresses.include?(ip)
      first_seen = record['first_seen']
      last_seen = record['last_seen']
      puts "IP: #{ip.ljust(15)} | First Seen: #{first_seen} | Last Seen: #{last_seen}"
    end
  end

  puts "\nSummary of unique IP addresses:"
  ip_addresses.each do |ip|
    puts "- #{ip}"
  end
end

def main
  domain = ARGV[0]
  if domain.nil? || domain.empty?
    puts "Usage: #{$PROGRAM_NAME} <domain>"
    exit 1
  end

  puts "Fetching history for #{domain}..."
  history_data = fetch_history(domain)

  if history_data
    print_history(history_data, domain)
  end
end

if __FILE__ == $PROGRAM_NAME
  main
end