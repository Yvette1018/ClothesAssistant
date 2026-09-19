import { common } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { AIResultData } from '../models/ClothingModel';
import { WeatherData } from '../models/WeatherModel';
import { OutfitResultData } from '../models/OutfitModel';
import { ClothingViewModel } from '../viewmodels/ClothingViewModel';

@Entry
@Component
struct Index {

  // =========================================================
  // API地址：只在这里集中维护
  // =========================================================
  private analyzeUrl: string =
    'http://172.26.182.40:8080/ai/analyze';

  private recommendUrl: string =
    'http://172.26.182.40:8080/ai/recommend';

  // =========================================================
  // ViewModel
  // =========================================================
  private viewModel: ClothingViewModel =
    new ClothingViewModel(
      this.analyzeUrl,
      this.recommendUrl
    );

  // =========================================================
  // 定位状态
  // =========================================================
  @State locationText: string =
    '正在获取当前位置...';

  @State isLocationLoading: boolean = false;

  @State hasLocation: boolean = false;

  @State locationLatitude: number = 0;

  @State locationLongitude: number = 0;

  // =========================================================
  // 页面状态
  // =========================================================
  @State message: string =
    '请选择一张衣物图片';

  @State photoUri: string = '';

  @State showImage: boolean = false;

  @State isUploading: boolean = false;

  @State uploadResult: string = '';

  @State aiResult: string = '';

  @State resultData: AIResultData | null = null;

  // =========================================================
  // 天气状态
  // =========================================================
  @State weatherData: WeatherData = {
    temperature: 0,
    weather: '天气获取中',
    humidity: 0,
    windSpeed: 0
  };

  @State isWeatherLoading: boolean = false;

  @State weatherText: string =
    '正在获取天气...';

  // =========================================================
  // 穿搭推荐状态
  // =========================================================
  @State isRecommending: boolean = false;

  @State outfitResult: OutfitResultData | null = null;

  @State outfitText: string = '';

  @State scene: string =
    '日常出行';

  // =========================================================
  // TTS状态
  // =========================================================
  @State isSpeaking: boolean = false;

  // =========================================================
  // 生命周期
  // =========================================================
  aboutToAppear(): void {
    console.info(
      'AI衣物识别页面初始化'
    );

    this.viewModel.initTTS(
      (speaking: boolean) => {
        this.isSpeaking = speaking;
      }
    );

    this.getCurrentLocation();
  }

  // =========================================================
  // Context
  // =========================================================
  private getContext(): common.UIAbilityContext {
    return this.getUIContext()
      .getHostContext() as common.UIAbilityContext;
  }

  // =========================================================
  // TTS
  // =========================================================
  private speakText(text: string): void {
    this.viewModel.speak(text);
  }

  private stopSpeaking(): void {
    this.viewModel.stopSpeaking();
    this.isSpeaking = false;
  }

  // =========================================================
  // 获取当前位置
  // =========================================================
  private async getCurrentLocation(): Promise<void> {
    if (this.isLocationLoading) {
      return;
    }

    this.isLocationLoading = true;
    this.locationText =
      '正在获取当前位置...';

    try {
      const location =
        await this.viewModel.getCurrentLocation(
          this.getContext()
        );

      this.locationLatitude =
        location.latitude;

      this.locationLongitude =
        location.longitude;

      this.hasLocation = true;

      this.locationText =
        '定位成功';

      console.info(
        '当前纬度：' + location.latitude
      );

      console.info(
        '当前经度：' + location.longitude
      );

      await this.getWeather();
    } catch (error) {
      const err = error as BusinessError;

      console.error(
        '定位失败：' +
        JSON.stringify(error)
      );

      this.locationText =
        '定位失败：' +
        (err.message || '请检查定位权限和设备设置');

      this.hasLocation = false;
    } finally {
      this.isLocationLoading = false;
    }
  }

  // =========================================================
  // 获取天气
  // =========================================================
  private async getWeather(): Promise<void> {
    if (!this.hasLocation) {
      this.weatherText =
        '请先获取当前位置';
      return;
    }

    if (this.isWeatherLoading) {
      return;
    }

    this.isWeatherLoading = true;
    this.weatherText =
      '正在获取真实天气...';

    try {
      const weather =
        await this.viewModel.getWeather(
          this.locationLatitude,
          this.locationLongitude
        );

      this.weatherData = weather;
      this.weatherText =
        '天气获取成功';

      console.info(
        '当前天气：' +
        JSON.stringify(weather)
      );
    } catch (error) {
      console.error(
        '获取天气失败：' +
        JSON.stringify(error)
      );

      this.weatherText =
        '天气获取失败，暂时使用默认天气';

      // 天气服务失败时保留默认值，
      // 保证穿搭推荐仍然可以测试。
      this.weatherData = {
        temperature: 28,
        weather: '晴',
        humidity: 60,
        windSpeed: 2
      };
    } finally {
      this.isWeatherLoading = false;
    }
  }

  // =========================================================
  // 拍照
  // =========================================================
  private async takePhoto(): Promise<void> {
    try {
      const imageUri =
        await this.viewModel.takePhoto(
          this.getContext()
        );

      this.photoUri = imageUri;
      this.showImage = true;
      this.message =
        '拍照成功，可以进行AI识别';
      this.uploadResult = '';
      this.aiResult = '';
      this.resultData = null;
      this.outfitResult = null;
      this.outfitText = '';

      console.info(
        '拍照成功：' + imageUri
      );
    } catch (error) {
      const err = error as BusinessError;

      console.error(
        `拍照失败，错误码：${err.code}，错误信息：${err.message}`
      );

      this.message =
        '拍照失败：' + err.message;
    }
  }

  // =========================================================
  // 测试图片
  // =========================================================
  private async useTestImage(): Promise<void> {
    try {
      const imageUri =
        await this.viewModel.loadTestImage(
          this.getContext()
        );

      this.photoUri = imageUri;
      this.showImage = true;
      this.message =
        '测试图片加载成功';
      this.uploadResult = '';
      this.aiResult = '';
      this.resultData = null;
      this.outfitResult = null;
      this.outfitText = '';

      console.info(
        '测试图片URI：' + imageUri
      );
    } catch (error) {
      const err = error as BusinessError;

      console.error(
        '读取测试图片失败：' +
        err.message
      );

      this.message =
        '读取测试图片失败：' +
        err.message;
    }
  }

  // =========================================================
  // AI衣物识别
  // =========================================================
  private async analyzeImage(): Promise<void> {
    if (!this.photoUri) {
      this.message =
        '请先拍照或选择测试图片';

      this.speakText(
        '请先选择一张衣物图片'
      );
      return;
    }

    if (this.isUploading) {
      return;
    }

    this.isUploading = true;
    this.message =
      '正在进行AI衣物识别...';
    this.uploadResult = '';
    this.aiResult = '';
    this.resultData = null;
    this.outfitResult = null;
    this.outfitText = '';

    try {
      const response =
        await this.viewModel.analyzeImage(
          this.getContext(),
          this.photoUri
        );

      this.resultData =
        response.data;

      this.aiResult =
        JSON.stringify(
          response.data,
          null,
          2
        );

      this.uploadResult =
        '衣物识别成功';

      this.message =
        'AI衣物识别完成';

      this.speakText(
        this.viewModel.buildClothingSpeechText(
          response.data
        )
      );

      // 重新刷新天气，防止页面停留过久。
      await this.getWeather();
    } catch (error) {
      const err = error as BusinessError;

      console.error(
        `AI识别失败：${err.code} ${err.message}`
      );

      this.message =
        'AI识别失败：' + err.message;

      this.uploadResult =
        'AI识别失败';
    } finally {
      this.isUploading = false;
    }
  }

  // =========================================================
  // AI智能穿搭推荐
  // =========================================================
  private async recommendOutfit(): Promise<void> {
    if (this.resultData === null) {
      this.message =
        '请先完成AI衣物识别';

      this.speakText(
        '请先完成衣物识别，再进行穿搭推荐'
      );
      return;
    }

    if (this.isRecommending) {
      return;
    }

    if (this.weatherText !== '天气获取成功') {
      await this.getWeather();
    }

    this.isRecommending = true;
    this.message =
      '正在结合天气和场景生成穿搭建议...';
    this.outfitResult = null;
    this.outfitText = '';

    try {
      const outfitData =
        await this.viewModel.recommendOutfit(
          this.resultData,
          this.weatherData,
          this.scene
        );

      this.outfitResult =
        outfitData;

      this.outfitText =
        outfitData.recommendation;

      this.message =
        'AI智能穿搭推荐完成';

      if (
        outfitData.voiceText &&
        outfitData.voiceText.trim() !== ''
      ) {
        this.speakText(
          outfitData.voiceText
        );
      } else {
        this.speakText(
          outfitData.recommendation
        );
      }
    } catch (error) {
      const err = error as BusinessError;

      console.error(
        `AI穿搭推荐失败：${err.code} ${err.message}`
      );

      this.message =
        'AI穿搭推荐失败：' +
        err.message;

      this.outfitText =
        '暂时无法生成穿搭建议';
    } finally {
      this.isRecommending = false;
    }
  }

  // =========================================================
  // 页面UI
  // 保留原有功能入口；本次主要拆分业务逻辑，不重做UI。
  // =========================================================
  build() {
    Scroll() {
      Column({
        space: 15
      }) {

        Text('AI衣物识别')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({
            top: 20,
            bottom: 10
          });

        Text(this.message)
          .fontSize(18)
          .width('90%')
          .textAlign(TextAlign.Center);

        if (
          this.showImage &&
          this.photoUri !== ''
        ) {
          Column() {
            Text('已选择的衣物图片')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({
                bottom: 10
              });

            Image(this.photoUri)
              .width('100%')
              .height(280)
              .objectFit(ImageFit.Contain)
              .borderRadius(12);
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#F5F5F5')
          .borderRadius(16);
        }

        Button('拍照')
          .width('80%')
          .height(50)
          .onClick(() => {
            this.takePhoto();
          });

        Button('使用测试图片')
          .width('80%')
          .height(50)
          .onClick(() => {
            this.useTestImage();
          });

        Button(
          this.isUploading
            ? '正在识别...'
            : '开始AI衣物识别'
        )
          .width('80%')
          .height(55)
          .enabled(!this.isUploading)
          .onClick(() => {
            this.analyzeImage();
          });

        if (
          this.resultData !== null
        ) {
          Column({
            space: 8
          }) {
            Text('👚 衣物识别结果')
              .fontSize(24)
              .fontWeight(FontWeight.Bold);

            this.ResultRow(
              '类别',
              this.resultData.category
            );

            this.ResultRow(
              '类型',
              this.resultData.type
            );

            this.ResultRow(
              '颜色',
              this.resultData.color
            );

            this.ResultRow(
              '材质',
              this.resultData.material
            );

            this.ResultRow(
              '风格',
              this.resultData.style
            );

            this.ResultRow(
              '图案',
              this.resultData.pattern
            );

            this.ResultRow(
              '置信度',
              this.resultData.confidence.toString()
            );
          }
          .width('90%')
          .padding(15)
          .borderRadius(18)
          .backgroundColor('#F8F9FC');
        }

        // ===================================================
        // 定位与天气
        // ===================================================
        Column({
          space: 12
        }) {

          Column({
            space: 8
          }) {
            Text('📍 当前位置')
              .fontSize(22)
              .fontWeight(FontWeight.Bold);

            Text(this.locationText)
              .fontSize(17)
              .fontColor('#555555');

            if (this.hasLocation) {
              Text(
                `纬度：${this.locationLatitude.toFixed(4)}`
              )
                .fontSize(14)
                .fontColor('#888888');

              Text(
                `经度：${this.locationLongitude.toFixed(4)}`
              )
                .fontSize(14)
                .fontColor('#888888');
            }

            Button(
              this.isLocationLoading
                ? '正在定位...'
                : '刷新当前位置'
            )
              .width('90%')
              .height(42)
              .enabled(!this.isLocationLoading)
              .onClick(() => {
                this.getCurrentLocation();
              });
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#F5F5F5');

          Column({
            space: 10
          }) {
            Text('🌤 当前天气')
              .fontSize(22)
              .fontWeight(FontWeight.Bold);

            Text(
              `${this.weatherData.temperature}℃`
            )
              .fontSize(38)
              .fontWeight(FontWeight.Bold);

            Text(
              this.weatherData.weather
            )
              .fontSize(22);

            Text(
              `湿度：${this.weatherData.humidity}%`
            )
              .fontSize(17);

            Text(
              `风速：${this.weatherData.windSpeed}m/s`
            )
              .fontSize(17);

            Text(this.weatherText)
              .fontSize(14)
              .fontColor('#888888');
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#F5F5F5');
        }
        .width('90%');

        // ===================================================
        // 使用场景 + 智能穿搭
        // ===================================================
        if (
          this.resultData !== null
        ) {
          Column({
            space: 12
          }) {
            Text('👕 使用场景')
              .fontSize(22)
              .fontWeight(FontWeight.Bold);

            Text(
              `当前场景：${this.scene}`
            )
              .fontSize(17)
              .fontColor('#555555');

            Row({
              space: 10
            }) {
              Button('日常出行')
                .fontSize(14)
                .layoutWeight(1)
                .onClick(() => {
                  this.scene = '日常出行';
                });

              Button('上班通勤')
                .fontSize(14)
                .layoutWeight(1)
                .onClick(() => {
                  this.scene = '上班通勤';
                });
            }
            .width('100%');

            Row({
              space: 10
            }) {
              Button('运动健身')
                .fontSize(14)
                .layoutWeight(1)
                .onClick(() => {
                  this.scene = '运动健身';
                });

              Button('约会聚餐')
                .fontSize(14)
                .layoutWeight(1)
                .onClick(() => {
                  this.scene = '约会聚餐';
                });
            }
            .width('100%');
          }
          .width('90%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor('#F5F5F5');

          Button(
            this.isRecommending
              ? 'AI正在生成穿搭建议...'
              : 'AI智能穿搭推荐'
          )
            .width('80%')
            .height(55)
            .enabled(!this.isRecommending)
            .onClick(() => {
              this.recommendOutfit();
            });
        }

        // ===================================================
        // 穿搭结果
        // ===================================================
        if (
          this.outfitResult !== null
        ) {
          Column({
            space: 12
          }) {
            Text('✨ AI 智能穿搭建议')
              .fontSize(24)
              .fontWeight(FontWeight.Bold);

            Text(
              `匹配程度：${this.outfitResult.match}`
            )
              .fontSize(18)
              .fontWeight(FontWeight.Bold);

            Divider();

            Text('穿搭推荐')
              .fontSize(19)
              .fontWeight(FontWeight.Bold);

            Text(
              this.outfitResult.recommendation
            )
              .fontSize(17);

            Text('推荐原因')
              .fontSize(19)
              .fontWeight(FontWeight.Bold);

            Text(
              this.outfitResult.reason
            )
              .fontSize(17);

            Text('搭配建议')
              .fontSize(19)
              .fontWeight(FontWeight.Bold);

            Text(
              this.outfitResult.suggestion
            )
              .fontSize(17);
          }
          .width('90%')
          .padding(18)
          .borderRadius(18)
          .backgroundColor('#F8F9FC');
        }

        if (this.isSpeaking) {
          Button('停止语音播报')
            .width('70%')
            .height(50)
            .onClick(() => {
              this.stopSpeaking();
            });
        }

        Blank()
          .height(30);

      }
      .width('100%')
      .padding({
        left: 20,
        right: 20
      });
    }
    .width('100%')
    .height('100%');
  }

  // =========================================================
  // 识别结果行
  // =========================================================
  @Builder
  ResultRow(
    label: string,
    value: string
  ) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#777777')
        .width('30%');

      Text(value)
        .fontSize(16)
        .fontColor('#222222')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.End);
    }
    .width('100%')
    .padding({
      top: 10,
      bottom: 10
    });
  }
}
