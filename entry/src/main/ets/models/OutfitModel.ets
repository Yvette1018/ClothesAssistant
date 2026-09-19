// 穿搭推荐相关数据模型

import { AIResultData } from './ClothingModel';
import { WeatherData } from './WeatherModel';

export interface OutfitRecommendRequest {
  clothing: AIResultData;
  weather: WeatherData;
  scene: string;
}

export interface OutfitResultData {
  recommendation: string;
  match: string;
  reason: string;
  suggestion: string;
  voiceText: string;
}

export interface OutfitResponse {
  success: boolean;
  message: string;
  data: string | OutfitResultData;
}
