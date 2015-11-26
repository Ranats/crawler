# coding: utf-8

require 'mechanize'
require 'nokogiri'
require 'csv'
require 'openssl'
require 'dotenv'
Dotenv.load('./nnid.env')

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG=true

$agent = Mechanize.new

$agent.request_headers = {
    'accept-language' => 'ja,ja-JP'
}


def auth
  $agent.get('https://splatoon.nintendo.net/users/auth/nintendo') do |page|
    login_result = page.form_with(action: 'https://id.nintendo.net/oauth/authorize') do |login|
      login['username'] = ENV['ID']
      login['password'] = ENV['PASS']
    end.submit
  end
end

auth

$agent.get('https://splatoon.nintendo.net/schedule') do |page|
#  page.force_encoding 'ASCII-8BIT' if page.respond_to? :force_encoding
#  puts page.encoding = 'UTF-8'

  html = Nokogiri::HTML(page.body)
  p html.title.encoding
  html.search('span[@class="map-name"]').each do |node|
    puts node.text
#    p node.xpath('span[@class="map-name"]').text
  end
end