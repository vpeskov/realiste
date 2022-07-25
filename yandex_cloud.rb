require './request'

module TelegramSpeech
  include Request

  class YandexSpeechRecognition
    # Настройки для Yandex SpeechCloud API
    YANDEX_OAUTH_TOKEN = 'AQAAAAAPYs9mAATuwRHYXm2svkFIpD6jt55CXmU'
    CATALOG_ID = "b1gdf77k7ur5voiunstu"
    VOICE_LANGUAGE = "ru-RU"
    AUDIO_FORMAT = 'oggopus'

    def initialize(voice_buffer)
      @iam_token = get_iam_token
      @voice_buffer = voice_buffer
    end

    def recognize

      # Пример запроса
      # curl -X POST \
      #  -H "Authorization: Bearer ${IAM_TOKEN}" \
      #  --data-binary "@speech.ogg" \
      #  "https://stt.api.cloud.yandex.net/speech/v1/stt:recognize?folderId=b1gdf77k7ur5voiunstu&lang=ru-RU"

      params = {
        folderId: CATALOG_ID,
        lang: VOICE_LANGUAGE,
        rawResults: true,
        format: AUDIO_FORMAT
      }

      result = Request::post(
        url: 'https://stt.api.cloud.yandex.net',
        path: '/speech/v1/stt:recognize',
        body: @voice_buffer,
        params: params,
        headers: {'Authorization' => "Bearer #{@iam_token}"}
      )

      return result.nil? ? "Ошибка при обращении к Yandex Cloud" : result['result']

    end

    private

    def get_iam_token

      # Пример получения iamToken-а:
      # curl -d "{\"yandexPassportOauthToken\":\"AQAAAAAPYs9mAATuwRHYXm2svkFIpD6jt55CXmU\"}" "https://iam.api.cloud.yandex.net"

      #   {
      #    "iamToken": "t1.9euelZqSz4-VkJrOypOMzJGOy5CJju3rnpWayszJjZjHm8abxsiZlZLNnJDl8_dDbxBp-e9iJSMg_d3z9wMeDmn572IlIyD9.zfx5do7NHsDTJl9H0WUuoSgss_KwU7CzVTM5Lh5O91tpPTjIn7eYgtyd8ScosTGTOtXFCj9P6zcUocahuCihBA",
      #    "expiresAt": "2022-07-23T22:06:52.737619229Z"
      # }

      result = Request::post(
        url: 'https://iam.api.cloud.yandex.net',
        path: '/iam/v1/tokens',
        params: {'yandexPassportOauthToken' => YANDEX_OAUTH_TOKEN},
        headers: {'accept' => '*/*'}
      )

      @iamToken = result['iamToken']
    end

  end
end
