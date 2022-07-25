require 'openssl'
require 'net-http2'
require 'json'

ALPN_PROTOCOL = 'h2'

module TelegramSpeech
  module Request

    def ctx
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

      ctx.alpn_protocols = [ALPN_PROTOCOL]
      ctx.alpn_select_cb = lambda do |protocols|
        puts "ALPN protocols supported by server: #{protocols}"
        ALPN_PROTOCOL if protocols.include? ALPN_PROTOCOL
      end
      ctx
    end

    def post(url: '', path: '/', body: nil, params: nil, headers: nil)
      return if url.empty?

      client = NetHttp2::Client.new(url, ssl_context: ctx)
      response = client.call(:post, path, body: body, params: params, headers: headers)

      if response.status == '200'
        result = JSON.parse(response.body)
      else
        result = nil
      end
    end

  end
end
