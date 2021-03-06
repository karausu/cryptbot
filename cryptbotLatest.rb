# coding: utf-8
require 'slack-ruby-bot'

#webに接続するためのライブラリ
require "open-uri"
#クレイピングに使用するライブラリ
require "nokogiri"

class Crypt
  attr_accessor :name
  attr_accessor :symbol
  attr_accessor :hp


  def initialize(name:, symbol:, hp:)
    self.name = name
    self.symbol = symbol
    self.hp = hp
  end


  def price
  url = self.hp
  #取得するhtml用charset
  charset = nil

  html = open(url) do |page|
    #charsetを自動で読み込み、取得
    charset = page.charset
    #中身を読む
    page.read
  end
    # Nokogiri で切り分け
    doc = Nokogiri::HTML(open(url))
    # Xpathを指定し、１ETHの値段を抽出
    price = doc.xpath( '//*[@id="quote_price"]/span[1]').text

end

  def marketcap
    url = self.hp
      charset = nil

      html = open(url) do |page|
        charset = page.charset
        page.read
      end
        # Nokogiri で切り分け
        doc = Nokogiri::HTML(open(url))
        marketCap = doc.xpath('/html/body/div[6]/div/div[1]/div[5]/div[1]/div[1]/div[2]/span[1]/span[1]').text

  end

  def volume
    url = self.hp
      charset = nil

      html = open(url) do |page|
        charset = page.charset
        page.read
      end
        # Nokogiri で切り分け
        doc = Nokogiri::HTML(open(url))
        volume = doc.xpath('/html/body/div[6]/div/div[1]/div[5]/div[1]/div[2]/div[2]/span[1]/span[1]').text
  end

  def usd_jpy
    #ドル円レートを取得
    #yahooドル円レートのURL
    url= "https://stocks.finance.yahoo.co.jp/stocks/detail/?code=USDJPY=X"

    charset = nil
    html = open(url) do |page|
      charset = page.charset
      page.read
    end
    #nokogiriで切り分け
    doc = Nokogiri::HTML(open(url))
    usd = doc.xpath('//*[@id="main"]/div[3]/div/div[2]/table').text
    #数値と小数点のみ残し、不要な情報を削除
    usdjpy = usd.delete("^0-9,.")
  end

  def jpy
    crypt_jpy = self.price.to_f*self.usd_jpy.to_i
  end

  def jpy_cap
    cap_num = self.marketcap.delete("^0-9")
    crypt_jpy_cap = cap_num.to_i*self.usd_jpy.to_i

    #桁数に応じてまとめる
    if crypt_jpy_cap > 1000000000000 then
      crypt_jpy_cap /= 1000000000000
      msg = "#{self.name}の市場規模は約#{crypt_jpy_cap.round}兆円です"
    elsif crypt_jpy_cap > 100000000
      crypt_jpy_cap /= 100000000
      msg =  "#{self.name}の市場規模は約#{crypt_jpy_cap.round}億円です"
    else crypt_jpy_cap > 10000
      crypt_jpy_cap /= 10000
      msg =  "#{self.name}の市場規模は約#{crypt_jpy_cap.round}万円です"
    end

  end

  def jpy_vol
    vol_num = self.volume.delete("^0-9")
    crypt_jpy_vol = vol_num.to_i*self.usd_jpy.to_i

    #桁数に応じてまとめる
    if  crypt_jpy_vol > 1000000000000 then
      crypt_jpy_vol /= 1000000000000
      msg =  "#{self.name}の24時間取引量は約#{ crypt_jpy_vol.round}兆円です"
    elsif  crypt_jpy_vol > 100000000
      crypt_jpy_vol /= 100000000
      msg =  "#{self.name}の24時間取引量は約#{ crypt_jpy_vol.round}億円です"
    else  crypt_jpy_vol > 10000
      crypt_jpy_vol /= 10000
      msg  = "#{self.name}の24時間取引量は約#{ crypt_jpy_vol.round}万円です"
    end
  end
end



SlackRubyBot::Client.logger.level = Logger::WARN

class Bot
  def call(client, data)

#投稿された通貨の名前に応じてcrypt1を代入
    case data.text
    when /BTC|btc|B(it ?coin|IT ?COIN)|bit ?coin|ビットコイン/ then
      crypt1 = Crypt.new(name: "Bitcoin", symbol: "BTC",
                                     hp: "https://coinmarketcap.com/currencies/bitcoin/")
    when /ETH|eth|E(thereum|THEREUM)|ethereum|イーサ|イーサリ(アム|ウム)/ then
        crypt1 = Crypt.new(name: "Ethereum", symbol: "ETH",
                                     hp: "https://coinmarketcap.com/currencies/ethereum/")
    when  /XRP|xrp|R(ipple|IPPLE)|ripple|リップル/ then
        crypt1 = Crypt.new(name: "Ripple", symbol: "XRP",
                                     hp: "https://coinmarketcap.com/currencies/ripple/")
    when  /BCH|bch|B(itcoin ?cash|ITCOIN ?CASH)|bitcoin ?cash|Bitcoin ?Cash|ビットコイン　?キャッシュ/ then
            crypt1 = Crypt.new(name: "Bitcoin Cash", symbol: "BCH",
                                         hp: "https://coinmarketcap.com/currencies/bitcoin-cash/")
    else
      #処理を飛ばす用
      flag = 0
    end

    if flag != 0
      #所持枚数JPY,1枚JPY、時価総額、取引量
      case data.text
      when  /[0-9]/ then
        #data.textを数値と小数点のみに加工
        possession = data.text.delete("^0-9,.")
        possession_jpy = possession.to_f * crypt1.jpy
        client.say(text: "#{possession}#{crypt1.symbol}は#{possession_jpy}円です", channel: data.channel)
      when  /いくら|幾ら|値段|価格|(P|p)rice/ then
        client.say(text: "1#{crypt1.symbol}は#{crypt1.jpy}円です", channel: data.channel)
      when   /時価総額|市場価(値|格)|(M|m)arket ?(C|c)ap|CAP|(C|c)ap/ then
        client.say(text: crypt1.jpy_cap, channel: data.channel)
      when  /取引量|(V|v)olume|vol|VOL/ then
        client.say(text: crypt1.jpy_vol, channel: data.channel)
      else
        client.say(text: '聞きたい内容を入力してください。例：値段/時価総額/取引量', channel: data.channel)
      end
    end

  end
end

server = SlackRubyBot::Server.new(
  token: 'your token',
  hook_handlers: {
    message: Bot.new
  }
)
server.run