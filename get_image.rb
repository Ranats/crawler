ENV['INLINEDIR'] = File.dirname(File.expand_path(__FILE__))

require "rubygems"

require 'openssl'
require 'open-uri'
require 'nokogiri'

def save_file(url)
  filename = File.basename(url)
  open("img/" + filename, 'wb') do |file|
    open(url) do |data|
      p file.write(data.read)
    end
  end
end

url = 'https://stat.ink/users'
#url = 'https://splatoon.nintendo.net/schedule'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

charset = nil
html = open(url) do |f|
  charset = f.charset # �������ʂ��擾
  f.read # html��ǂݍ���ŕϐ�html�ɕԂ�
end

# html���p�[�X
doc = Nokogiri::HTML.parse(html, nil, charset)


doc.xpath('//a[@class="auto-tooltip"]').each do |node|
  url = node.attribute('href').value
  html = open(url) do |f|
    charset = f.charset # �������ʂ��擾
    f.read # html��ǂݍ���ŕϐ�html�ɕԂ�
  end

  doc = Nokogiri::HTML.parse(html, nil, charset)
#  p doc
  doc.xpath('//div[@class="col-xs-12 col-sm-12 col-md-6 col-lg-6 image-container"]').each do |node|
#    p node
    p node.child.attribute('src').value
    save_file(node.child.attribute('src').value)
    break
  end

end