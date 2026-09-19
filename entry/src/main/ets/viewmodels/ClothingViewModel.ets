import { common } from '@kit.AbilityKit';
import { camera, cameraPicker as picker } from '@kit.CameraKit';
import { AIResponse, AIResultData } from '../models/ClothingModel';
import { WeatherData } from '../models/WeatherModel';
import {
  OutfitRecommendRequest,
  OutfitResultData
} from '../models/OutfitModel';
import { ImageService } from '../services/ImageService';
import { ClothingApiService } from '../services/ClothingApiService';
import { WeatherService } from '../services/WeatherService';
import { LocationData, LocationService } from '../services/LocationService';
import { OutfitApiService } from '../services/OutfitApiService';
import { TtsService } from '../services/TtsService';

/**
 * 页面业务编排层（轻量 ViewModel）。
 * Index 只负责界面状态与交互，具体业务交给这里。
 */
export class ClothingViewModel {

  private imageService: ImageService;
  private clothingApi: ClothingApiService;
  private weatherService: WeatherService;
  private locationService: LocationService;
  private outfitApi: OutfitApiService;
  private ttsService: TtsService;

  constructor(
    analyzeUrl: string,
    recommendUrl: string
  ) {
    this.imageService = new ImageService();
    this.clothingApi = new ClothingApiService(
      analyzeUrl,
      this.imageService
    );
    this.weatherService = new WeatherService();
    this.locationService = new LocationService();
    this.outfitApi = new OutfitApiService(
      recommendUrl
    );
    this.ttsService = new TtsService();
  }

  initTTS(
    onSpeakingChanged: (speaking: boolean) => void
  ): void {
    this.ttsService.setSpeakingListener(
      onSpeakingChanged
    );
    this.ttsService.init();
  }

  speak(text: string): void {
    this.ttsService.speak(text);
  }

  stopSpeaking(): void {
    this.ttsService.stop();
  }

  async takePhoto(
    context: common.UIAbilityContext
  ): Promise<string> {
    const pickerProfile: picker.PickerProfile = {
      cameraPosition:
        camera.CameraPosition.CAMERA_POSITION_BACK
    };

    const result: picker.PickerResult =
      await picker.pick(
        context,
        [picker.PickerMediaType.PHOTO],
        pickerProfile
      );

    if (
      result.resultCode !== 0 ||
      !result.resultUri
    ) {
      throw new Error(
        '没有获取到拍照结果'
      );
    }

    return result.resultUri;
  }

  async loadTestImage(
    context: common.UIAbilityContext
  ): Promise<string> {
    return await this.imageService.loadTestImage(
      context
    );
  }

  async analyzeImage(
    context: common.UIAbilityContext,
    imageUri: string
  ): Promise<AIResponse> {
    return await this.clothingApi.analyze(
      context,
      imageUri
    );
  }

  async getCurrentLocation(
    context: common.UIAbilityContext
  ): Promise<LocationData> {
    return await this.locationService.getCurrentLocation(
      context
    );
  }

  async getWeather(
    latitude: number,
    longitude: number
  ): Promise<WeatherData> {
    return await this.weatherService.getWeather(
      latitude,
      longitude
    );
  }

  async recommendOutfit(
    clothing: AIResultData,
    weather: WeatherData,
    scene: string
  ): Promise<OutfitResultData> {
    const request: OutfitRecommendRequest = {
      clothing: clothing,
      weather: weather,
      scene: scene
    };

    return await this.outfitApi.recommend(
      request
    );
  }

  buildClothingSpeechText(
    data: AIResultData
  ): string {
    let text: string = '识别完成。';

    if (
      data.color &&
      data.material &&
      data.type
    ) {
      text +=
        `这是一件${data.color}` +
        `${data.material}` +
        `${data.type}。`;
    } else if (
      data.color &&
      data.type
    ) {
      text +=
        `这是一件${data.color}` +
        `${data.type}。`;
    } else if (data.type) {
      text +=
        `这是一件${data.type}。`;
    }

    if (
      data.category &&
      data.category !== '无法判断'
    ) {
      text +=
        `属于${data.category}。`;
    }

    if (
      data.style &&
      data.style !== '无法判断'
    ) {
      text +=
        `整体风格偏${data.style}。`;
    }

    if (
      data.pattern &&
      data.pattern !== '无法判断'
    ) {
      text +=
        `图案为${data.pattern}。`;
    }

    return text;
  }
}
