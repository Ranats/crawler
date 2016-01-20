# coding: utf-8

# `require': cannot load such file -- nokogiri/nokogiri (LoadError)
# → ruby 2.1.x
# Settings - Languages & Frameworks > Ruby SDK and Gems
# or http://www.kaoriya.net/blog/2015/11/17/

require 'mechanize'
require 'nokogiri'
require 'csv'
require 'openssl'
require 'dotenv'
require 'dropbox_sdk'

Dotenv.load('./nnid.env')

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG=true

$drop_client = DropboxClient.new(ENV['TOKEN'])
$drop_file_path = '/Test/'
$stage_file_name = 'stage.csv'

$agent = Mechanize.new
$agent.request_headers = {
    'accept-language' => 'ja,ja-JP'
}

module Crawler

  def self.auth
    $agent.get('https://splatoon.nintendo.net/users/auth/nintendo') do |page|
      # フォーム入力。
      # formタグのinput要素、name属性で指定する。
      # ログイン後のページ情報が返る。
      logged_page = page.form_with(action: 'https://id.nintendo.net/oauth/authorize') do |field|
        field['username'] = ENV['ID']
        field['password'] = ENV['PASS']
      end.submit

      if logged_page.body =~ /logout/
        puts 'login success'
      else
        puts 'login failed'
        exit 1
      end
    end
  end

  def stage_update(table)
    auth
    $agent.get('https://splatoon.nintendo.net/schedule') do |page|
      html = Nokogiri::HTML(page.body)
      html.search('span[@class="stage-schedule"]').each_with_index do |node,index|
        table[index][:date] = node.text
      end
      html.search('span[@class="rule-description"]').each_with_index do |node,index|
        table[index][:gachi_rule] = node.text
      end
      html.search('span[@class="map-name"]').each_slice(2).with_index do |node_arr,num|
        node_arr.each_with_index do |node,index|
          if num.even?
            table[num/2][:"regular#{index}"] = node.text
          else
            table[num/2][:"gachi#{index}"] = node.text
          end
        end
      end
      html.search("//span[@class='map-image retina-support' and @style]").each_with_index do |node,index|
        table[index/4][:"image#{index%4}"] = 'https://splatoon.nintendo.net/' + node.values.find {|val| val =~ /'\/assets.+png/}[/assets.+png/]
      end
    end

    response = $drop_client.put_file($drop_file_path + $stage_file_name,table.to_csv,true)
    puts "uploaded:", response.inspect
    table
  end

  def self.load_stage
    stage_file = nil
    # フォルダ上のファイル情報を取得 json 配列
    # 各ファイルの情報はHashで返ってくるので、stage.csvを含むか否かで分岐
    if $drop_client.metadata($drop_file_path)['contents'].map {|h| h.has_value?($drop_file_path + $stage_file_name)}.include?(true)
      # ファイルが存在する場合、読み込む。
      stage_file = $drop_client.get_file($drop_file_path + $stage_file_name)
    else
      # ファイルが存在しない場合、ローカルのファイルをアップロード。
      stage_file = open($stage_file_name)
      response = $drop_client.put_file($drop_file_path + $stage_file_name,stage_file)
      puts "uploaded:", response.inspect
      stage_file = $drop_client.get_file($drop_file_path + $stage_file_name)
    end

    stage_file.force_encoding('UTF-8')
    table = CSV.new(stage_file, row_sep: :auto, headers: true, converters: :numeric, header_converters: :symbol).read

    if table[0][:date][-5,2].to_i < Time.now.hour
      stage_update(table)
    end
  end

end

if $0 == __FILE__
  Crawler.load_stage
end