import http from '@ohos.net.http';
import { WeatherData, WeatherApiResponse } from '../models/WeatherModel';

/**
 * Open-Meteo 天气服务。
 */
export class WeatherService {

  async getWeather(
    latitude: number,
    longitude: number
  ): Promise<WeatherData> {
    const url =
      'https://api.open-meteo.com/v1/forecast' +
      `?latitude=${latitude}` +
      `&longitude=${longitude}` +
      '&current=temperature_2m,' +
      'relative_humidity_2m,' +
      'weather_code,' +
      'wind_speed_10m' +
      '&wind_speed_unit=ms' +
      '&temperature_unit=celsius' +
      '&timezone=auto';

    const httpRequest = http.createHttp();

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000
      };

      const response =
        await httpRequest.request(
          url,
          options
        );

      console.info(
        `天气接口响应码：${response.responseCode}`
      );

      if (
        response.responseCode < 200 ||
        response.responseCode >= 300
      ) {
        throw new Error(
          `天气API返回错误：${response.responseCode}`
        );
      }

      const data =
        JSON.parse(
          response.result as string
        ) as WeatherApiResponse;

      if (!data.current) {
        throw new Error(
          '天气API没有返回current数据'
        );
      }

      return {
        temperature: data.current.temperature_2m,
        weather: this.weatherCodeToText(
          data.current.weather_code
        ),
        humidity: data.current.relative_humidity_2m,
        windSpeed: data.current.wind_speed_10m
      };
    } finally {
      httpRequest.destroy();
    }
  }

  weatherCodeToText(code: number): string {
    if (code === 0) return '晴';
    if (code === 1 || code === 2) return '少云/多云';
    if (code === 3) return '阴';
    if (code === 45 || code === 48) return '雾';
    if (code === 51 || code === 53 || code === 55) return '毛毛雨';
    if (code === 56 || code === 57) return '冻毛毛雨';
    if (code === 61 || code === 63 || code === 65) return '雨';
    if (code === 66 || code === 67) return '冻雨';
    if (code === 71 || code === 73 || code === 75 || code === 77) return '下雪';
    if (code === 80 || code === 81 || code === 82) return '阵雨';
    if (code === 85 || code === 86) return '阵雪';
    if (code === 95) return '雷雨';
    if (code === 96 || code === 99) return '雷雨伴冰雹';
    return '未知天气';
  }
}
