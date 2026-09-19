import http from '@ohos.net.http';
import {
  OutfitRecommendRequest,
  OutfitResponse,
  OutfitResultData
} from '../models/OutfitModel';

/**
 * AI智能穿搭推荐 API 服务。
 */
export class OutfitApiService {

  private recommendUrl: string;

  constructor(recommendUrl: string) {
    this.recommendUrl = recommendUrl;
  }

  async recommend(
    requestData: OutfitRecommendRequest
  ): Promise<OutfitResultData> {
    const httpRequest = http.createHttp();

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(requestData),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 60000
      };

      const response =
        await httpRequest.request(
          this.recommendUrl,
          options
        );

      console.info(
        `穿搭接口响应码：${response.responseCode}`
      );

      console.info(
        `穿搭接口响应：${response.result}`
      );

      if (
        response.responseCode < 200 ||
        response.responseCode >= 300
      ) {
        throw new Error(
          `穿搭服务器返回错误：${response.responseCode}`
        );
      }

      const data =
        JSON.parse(
          response.result as string
        ) as OutfitResponse;

      if (!data.success) {
        throw new Error(
          data.message ||
          'AI穿搭推荐失败'
        );
      }

      if (typeof data.data === 'string') {
        return JSON.parse(
          data.data
        ) as OutfitResultData;
      }

      return data.data;
    } finally {
      httpRequest.destroy();
    }
  }
}
