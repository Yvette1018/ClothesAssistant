import { common } from '@kit.AbilityKit';
import http from '@ohos.net.http';
import { AIResponse } from '../models/ClothingModel';
import { ImageService } from './ImageService';
import { MultipartUtil } from '../utils/MultipartUtil';

/**
 * 衣物识别 API 服务。
 * 负责把图片上传到 Spring Boot /ai/analyze 并解析结果。
 */
export class ClothingApiService {

  private serverUrl: string;
  private imageService: ImageService;

  constructor(serverUrl: string, imageService: ImageService) {
    this.serverUrl = serverUrl;
    this.imageService = imageService;
  }

  async analyze(
    context: common.UIAbilityContext,
    imageUri: string
  ): Promise<AIResponse> {
    const imageBytes =
      await this.imageService.readImage(
        context,
        imageUri
      );

    const contentType =
      this.imageService.getImageContentType(imageUri);

    const fileName =
      this.imageService.getFileName(contentType);

    const boundary =
      '----HarmonyOSClothingAI' + Date.now().toString();

    const multipartBody =
      MultipartUtil.buildImageBody(
        imageBytes,
        fileName,
        contentType,
        boundary
      );

    const httpRequest = http.createHttp();

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type':
            `multipart/form-data; boundary=${boundary}`
        },
        extraData: multipartBody,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 60000
      };

      const response =
        await httpRequest.request(
          this.serverUrl,
          options
        );

      console.info(
        `衣物识别接口响应码：${response.responseCode}`
      );

      console.info(
        `衣物识别接口响应：${response.result}`
      );

      if (
        response.responseCode < 200 ||
        response.responseCode >= 300
      ) {
        throw new Error(
          `服务器返回错误：${response.responseCode}`
        );
      }

      const data =
        JSON.parse(response.result as string) as AIResponse;

      if (!data.success) {
        throw new Error(
          data.message || 'AI识别失败'
        );
      }

      return data;
    } finally {
      httpRequest.destroy();
    }
  }
}
