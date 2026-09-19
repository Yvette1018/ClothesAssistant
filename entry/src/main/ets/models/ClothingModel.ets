// 衣物识别相关数据模型

export interface AIResultData {
  category: string;
  type: string;
  color: string;
  material: string;
  style: string;
  pattern: string;
  confidence: number;
}

export interface AIResponse {
  success: boolean;
  message: string;
  data: AIResultData;
}
