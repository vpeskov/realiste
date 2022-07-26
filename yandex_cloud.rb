require 'httparty'
require 'aws-sdk-s3'

module TelegramSpeech

  AUDIO_ENCODING = "OGG_OPUS"
  VOICE_LANGUAGE = "ru-RU"
  AUDIO_FORMAT = 'oggopus'

  class YandexSpeech
    def initialize(voice_buffer)
      @voice_buffer = voice_buffer
      @iam_token = get_iam_token
    end

    def get_iam_token

      # Пример получения iamToken-а:
      # curl -d "{\"yandexPassportOauthToken\":\"AQAAAAAPYs9mAATuwRHYXm2svkFIpD6jt55CXmU\"}" "https://iam.api.cloud.yandex.net/iam/v1/tokens"

      #   {
      #    "iamToken": "t1.9euelZqSz4-VkJrOypOMzJGOy5CJju3rnpWayszJjZjHm8abxsiZlZLNnJDl8_dDbxBp-e9iJSMg_d3z9wMeDmn572IlIyD9.zfx5do7NHsDTJl9H0WUuoSgss_KwU7CzVTM5Lh5O91tpPTjIn7eYgtyd8ScosTGTOtXFCj9P6zcUocahuCihBA",
      #    "expiresAt": "2022-07-23T22:06:52.737619229Z"
      # }

      options = {
        body: {
          "yandexPassportOauthToken" => YANDEX_OAUTH_TOKEN
        }.to_json
      }
      response = HTTParty.post('https://iam.api.cloud.yandex.net/iam/v1/tokens', options)
      @iamToken = response.to_h['iamToken']
    end

    def recognize
      raise "Method Not Implemented"
    end
  end

  class YandexLongSpeechRecognition < YandexSpeech
    def initialize(voice_buffer)
      super(voice_buffer)
      @bucket_filename = 'audio_long.ogg'
      @bucket_name = ''
      put_file_to_bucket
    end

    def put_file_to_bucket
      Aws.config.update(
        region: 'ru-central1',
        credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
      )

      s3 = Aws::S3::Client.new(endpoint: "https://storage.yandexcloud.net")

      response = s3.list_buckets
      @bucket_name = response.buckets.first.name

      res = s3.put_object({
        bucket: @bucket_name,
        key: @bucket_filename,
        body: @voice_buffer
      })

    end

    def recognize

      options = {
        headers: {"Authorization" => "Api-Key #{YANDEX_API_SIMPLE_KEY}"},
        body: {
          "config" => {
            "specification" => {
              "languageCode" => VOICE_LANGUAGE,
              "rawResults" => true,
            }
          },
          "audio" => {
            "uri" => "https://storage.yandexcloud.net/#{@bucket_name}/#{@bucket_filename}"
          }
        }.to_json
      }

      response = HTTParty.post('https://transcribe.api.cloud.yandex.net/speech/stt/v2/longRunningRecognize', options).to_h
      recognition_operation_id = response['id']

      if recognition_operation_id
        done = false
        until done
          speech_answer = HTTParty.get("https://operation.api.cloud.yandex.net/operations/#{recognition_operation_id}", {headers: {"Authorization" => "Api-Key #{YANDEX_API_SIMPLE_KEY}"}}).to_h
          done = speech_answer['done']
          sleep 3
        end

        speech_chunks = speech_answer['response']['chunks']
        speech_results = []
        speech_chunks.each do |chunk|
          speech_results << chunk['alternatives'].first['text']
        end

        speech_results.join(' ')
      else

        'Ошибка при обращении к Yandex Cloud'
      end
    end
  end

  class YandexShortSpeechRecognition < YandexSpeech

    def initialize(voice_buffer)
      super(voice_buffer)
    end

    def recognize

      # Пример запроса
      # curl -X POST \
      #  -H "Authorization: Bearer ${IAM_TOKEN}" \
      #  --data-binary "@speech.ogg" \
      #  "https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?folderId=b1gdf77k7ur5voiunstu&lang=ru-RU"

      url = "https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?folderId=#{CATALOG_ID}&lang=#{VOICE_LANGUAGE}&format=#{AUDIO_FORMAT}&rawResults=true"
      options = {
        headers: {"Authorization" => "Bearer #{@iam_token}"},
        body: @voice_buffer
      }

      response = HTTParty.post(url, options).to_h
      return response["result"] ? response["result"] : "Ошибка при обращении к Yandex Cloud"

    end

  end
end
