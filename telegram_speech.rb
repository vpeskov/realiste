require 'uri'
require 'net/http'
require 'json'
require './error'

module TelegramSpeech

  class TelegramMsg
    def initialize(token)
      @bot_token = token
    end

    def get_voice_from_msg
      raise "Method Not Implemented"
    end
  end

  class TelegramVoiceMsg < TelegramMsg
    attr_reader :voice_buffer

    def initialize(token, file_id)
      super(token)

      uri = URI("https://api.telegram.org/bot#{@bot_token}/getFile")
      params = {file_id: file_id }
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        result = JSON.parse(response.body)
        if result["ok"]
          @file_path = result["result"]["file_path"]
        else
          raise(TelegramSpeech::TelegramError)
        end
      else
        raise(TelegramSpeech::TelegramError)
      end

    end

    def get_voice_from_msg
      uri = URI("https://api.telegram.org/file/bot#{@bot_token}/#{@file_path}")
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        @voice_buffer = response.body

        # Для тестирования сохраняем файл
        # File.open("test_audio_file.ogg","wb") {|f| f.write(@voice_buffer) }

      else
        raise(TelegramSpeech::TelegramError)
      end
    end

  end

end
