require 'telegram/bot'
require './telegram_speech'
require './yandex_cloud'

# Настройки для Telegram bot
TELEGRAM_KEY = ENV['TELEGRAM_KEY']

# Настройки для Yandex SpeechCloud API
YANDEX_OAUTH_TOKEN = ENV['YANDEX_OAUTH_TOKEN']
YANDEX_API_SIMPLE_KEY = ENV['YANDEX_API_SIMPLE_KEY']
CATALOG_ID = ENV['YANDEX_CATALOG_ID']

include TelegramSpeech

puts "Starting telegram bot and we will recognize voice messages"
puts "Press Ctrl-C for exit..."

loop do
  begin
    Telegram::Bot::Client.run(TELEGRAM_KEY) do |bot|

      bot.listen do |rqst|

        begin
          if rqst.voice
            voice_message = TelegramVoiceMsg.new(TELEGRAM_KEY, rqst.voice.file_id)
            voice_message.get_voice_from_msg

            yandex_voice_recognize = ( rqst.voice.duration > 30 ) ?
              YandexLongSpeechRecognition.new(voice_message.voice_buffer) :
              YandexShortSpeechRecognition.new(voice_message.voice_buffer)

            voice_speech = yandex_voice_recognize.recognize
            puts "Результат выполнения:\n#{voice_speech}"

            bot.api.send_message(
              chat_id: rqst.chat.id,
              text: voice_speech
            )
            next
          end

          case rqst.text
          when '/start'
            bot.api.send_message(
              chat_id: rqst.chat.id,
              text: "<b>Жду вашего голосового сообщения</b>, #{rqst.from.first_name}!\nНажмите и удерживайте кнопку с изображением микрофона,\nзатем можете произнести ваше сообщение, после чего отпустите кнопку.",
              parse_mode: "HTML"
            )
          when '/stop'
            bot.api.send_message(chat_id: rqst.chat.id, text: "До свидания, #{rqst.from.first_name}")
          else
            bot.api.send_message(chat_id: rqst.chat.id, text: "Я жду ваше <b>голосовое сообщение</b>", parse_mode: "HTML")
          end
        rescue => err
          bot.api.send_message(chat_id: rqst.chat.id, text: "При работе с ботом произошла ошибка")
          puts "Error in telegram bot #{err}"
        end
      end
    end
  rescue => err
    puts "Something went wrong, error: #{err}"
  end
end
