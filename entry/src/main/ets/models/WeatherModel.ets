// 天气相关数据模型

export interface WeatherData {
  temperature: number;
  weather: string;
  humidity: number;
  windSpeed: number;
}

export interface WeatherCurrentData {
  temperature_2m: number;
  relative_humidity_2m: number;
  weather_code: number;
  wind_speed_10m: number;
}

export interface WeatherApiResponse {
  current: WeatherCurrentData;
}
