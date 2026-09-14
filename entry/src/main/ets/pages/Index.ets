import { camera, cameraPicker as picker } from '@kit.CameraKit';
import { fileIo } from '@kit.CoreFileKit';
import { textToSpeech } from '@kit.CoreSpeechKit';
import { common } from '@kit.AbilityKit';
import http from '@ohos.net.http';
import util from '@ohos.util';
import { BusinessError } from '@ohos.base';

interface AIResultData {
  category: string;
  type: string;
  color: string;
  material: string;
  style: string;
  pattern: string;
  confidence: number;
}

interface AIResponse {
  success: boolean;
  message: string;
  data: AIResultData;
}

@Entry
@Component
struct Index {

  // =========================================================
  // 图片状态
  // =========================================================

  @State imageUri: string = '';
  @State hasImage: boolean = false;

  // =========================================================
  // AI识别状态
  // =========================================================

  @State isAnalyzing: boolean = false;

  @State statusText: string =
    '拍照或选择测试图片开始识别';

  @State resultData: AIResultData | null = null;

  // =========================================================
  // TTS
  // =========================================================

  private ttsEngine:
  textToSpeech.TextToSpeechEngine | null = null;

  @State isSpeaking: boolean = false;

  // =========================================================
  // Spring Boot服务器
  // =========================================================

  private serverUrl: string =
    'http://172.26.72.160:8080/ai/analyze';


  // =========================================================
  // 页面出现
  // =========================================================

  aboutToAppear(): void {

    console.info('Index页面出现');

    this.initTTS();
  }


  // =========================================================
  // 初始化TTS
  // =========================================================

  private initTTS(): void {

    if (this.ttsEngine !== null) {
      return;
    }

    const extraParams: Record<string, Object> = {

      'style':
      'interaction-broadcast',

      'locate':
      'CN',

      'name':
      'ClothingAI'
    };

    const initParams:
      textToSpeech.CreateEngineParams = {

      language:
      'zh-CN',

      person:
      0,

      online:
      1,

      extraParams:
      extraParams
    };

    try {

      textToSpeech.createEngine(
        initParams,

        (
          err: BusinessError,
          engine: textToSpeech.TextToSpeechEngine
        ) => {

          if (!err) {

            console.info(
              'TTS引擎创建成功'
            );

            this.ttsEngine =
              engine;

            this.ttsEngine.setListener({

              onStart: (
                requestId: string,
                response:
                  textToSpeech.StartResponse
              ) => {

                console.info(
                  `TTS开始播报，requestId=${requestId}`
                );

                this.isSpeaking =
                  true;
              },


              onComplete: (
                requestId: string,
                response:
                  textToSpeech.CompleteResponse
              ) => {

                console.info(
                  `TTS播报完成，requestId=${requestId}`
                );

                if (response.type === 1) {

                  this.isSpeaking =
                    false;
                }
              },


              onStop: (
                requestId: string,
                response:
                  textToSpeech.StopResponse
              ) => {

                console.info(
                  `TTS停止播报，requestId=${requestId}`
                );

                this.isSpeaking =
                  false;
              },


              onData: (
                requestId: string,
                audio: ArrayBuffer,
                response:
                  textToSpeech.SynthesisResponse
              ) => {

                console.info(
                  `TTS音频数据返回，requestId=${requestId}`
                );
              },


              onError: (
                requestId: string,
                errorCode: number,
                errorMessage: string
              ) => {

                console.error(
                  `TTS错误，requestId=${requestId}, ` +
                    `errorCode=${errorCode}, ` +
                    `errorMessage=${errorMessage}`
                );

                this.isSpeaking =
                  false;
              }
            });

          } else {

            console.error(
              `TTS引擎创建失败，` +
                `错误码：${err.code}，` +
                `错误信息：${err.message}`
            );
          }
        }
      );

    } catch (error) {

      const err =
        error as BusinessError;

      console.error(
        `TTS初始化异常，` +
          `错误码：${err.code}，` +
          `错误信息：${err.message}`
      );
    }
  }


  // =========================================================
  // TTS播报
  // =========================================================

  private speakText(
    text: string
  ): void {

    if (this.ttsEngine === null) {

      console.error(
        'TTS引擎还没有初始化'
      );

      this.initTTS();

      return;
    }

    if (
      !text ||
        text.trim() === ''
    ) {

      console.error(
        'TTS播报内容为空'
      );

      return;
    }

    const extraParams:
      Record<string, Object> = {

      'queueMode':
      1,

      'speed':
      1,

      'volume':
      2,

      'pitch':
      1,

      'languageContext':
      'zh-CN',

      'audioType':
      'pcm',

      'soundChannel':
      3,

      'playType':
      1
    };

    const speakParams:
      textToSpeech.SpeakParams = {

      requestId:
      'clothing-ai-' +
      Date.now(),

      extraParams:
      extraParams
    };

    try {

      console.info(
        '开始TTS播报：' +
          text
      );

      this.isSpeaking =
        true;

      this.ttsEngine.speak(
        text,
        speakParams
      );

    } catch (error) {

      const err =
        error as BusinessError;

      console.error(
        `TTS播报异常，` +
          `错误码：${err.code}，` +
          `错误信息：${err.message}`
      );

      this.isSpeaking =
        false;
    }
  }


  // =========================================================
  // 停止TTS
  // =========================================================

  private stopSpeaking(): void {

    if (this.ttsEngine === null) {

      console.info(
        'TTS引擎不存在'
      );

      return;
    }

    try {

      console.info(
        '停止TTS播报'
      );

      this.ttsEngine.stop();

      this.isSpeaking =
        false;

    } catch (error) {

      const err =
        error as BusinessError;

      console.error(
        `停止TTS失败，` +
          `错误码：${err.code}，` +
          `错误信息：${err.message}`
      );

      this.isSpeaking =
        false;
    }
  }


  // =========================================================
  // 生成AI语音播报内容
  // =========================================================

  private buildSpeechText(
    data: AIResultData
  ): string {

    let text =
      '识别完成。';

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

    } else if (
    data.type
    ) {

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


  // =========================================================
  // 拍照
  // =========================================================

  private async takePhoto(): Promise<void> {

    try {

      console.info(
        '开始调用相机'
      );

      const context = getContext(this) as common.UIAbilityContext;

      const pickerProfile:
        picker.PickerProfile = {

        cameraPosition:
        camera.CameraPosition
          .CAMERA_POSITION_BACK
      };

      const result:
        picker.PickerResult =
        await picker.pick(
          context,

          [
            picker.PickerMediaType.PHOTO
          ],

          pickerProfile
        );

      console.info(
        '相机返回结果：' +
        JSON.stringify(result)
      );

      if (
        result.resultCode === 0 &&
        result.resultUri
      ) {

        this.imageUri =
          result.resultUri;

        this.hasImage =
          true;

        this.resultData =
          null;

        this.statusText =
          '照片已选择，可以开始AI识别';

        console.info(
          '获取照片成功：' +
          this.imageUri
        );

      } else {

        console.error(
          '没有获取到拍照结果'
        );

        this.statusText =
          '没有获取到拍照结果';

        this.speakText(
          '没有获取到拍照结果，请重新拍摄。'
        );
      }

    } catch (error) {

      const err =
        error as BusinessError;

      console.error(
        `调用相机失败：` +
          `code=${err.code}, ` +
          `message=${err.message}`
      );

      this.statusText =
        '调用相机失败';

      this.speakText(
        '调用相机失败，请重新尝试。'
      );
    }
  }


  // =========================================================
  // 加载测试图片
  // =========================================================

  private loadTestImage(): void {

    this.imageUri =
      'resource://RAWFILE/test_clothes.jpg';

    this.hasImage =
      true;

    this.resultData =
      null;

    this.statusText =
      '测试图片已加载，可以开始AI识别';

    console.info(
      '测试图片加载成功'
    );
  }


  // =========================================================
  // 拼接Uint8Array
  // =========================================================

  private concatUint8Arrays(
    parts: Uint8Array[]
  ): Uint8Array {

    let totalLength =
      0;

    for (
      let i = 0;
      i < parts.length;
      i++
    ) {

      totalLength +=
      parts[i].length;
    }

    const result =
      new Uint8Array(
        totalLength
      );

    let offset =
      0;

    for (
      let i = 0;
      i < parts.length;
      i++
    ) {

      result.set(
        parts[i],
        offset
      );

      offset +=
      parts[i].length;
    }

    return result;
  }


  // =========================================================
  // 构造真正的multipart/form-data请求
  // =========================================================

  private buildMultipartBody(
    imageBytes: Uint8Array,
    fileName: string,
    contentType: string,
    boundary: string
  ): ArrayBuffer {

    const encoder =
      new util.TextEncoder();

    const headerText =
      `--${boundary}\r\n` +
        `Content-Disposition: form-data; ` +
        `name="file"; ` +
        `filename="${fileName}"\r\n` +
        `Content-Type: ${contentType}\r\n` +
        `\r\n`;

    const footerText =
      `\r\n` +
        `--${boundary}--\r\n`;

    const headerBytes =
      encoder.encodeInto(
        headerText
      );

    const footerBytes =
      encoder.encodeInto(
        footerText
      );

    const body =
      this.concatUint8Arrays([
        headerBytes,
        imageBytes,
        footerBytes
      ]);

    console.info(
      `multipart body构造完成，` +
        `boundary=${boundary}, ` +
        `bodySize=${body.length}`
    );

    return body.buffer;
  }


  // =========================================================
  // 判断图片类型
  // =========================================================

  private getImageContentType(
    uri: string
  ): string {

    const lower =
      uri.toLowerCase();

    if (
    lower.endsWith('.png')
    ) {

      return 'image/png';
    }

    if (
    lower.endsWith('.webp')
    ) {

      return 'image/webp';
    }

    return 'image/jpeg';
  }


  // =========================================================
  // AI识别
  // =========================================================

  private async analyzeImage(): Promise<void> {

    // =======================================================
    // 检查图片
    // =======================================================

    if (
      !this.hasImage ||
        !this.imageUri
    ) {

      this.statusText =
        '请先选择一张衣物图片';

      this.speakText(
        '请先选择一张衣物图片。'
      );

      return;
    }


    // =======================================================
    // 防止重复点击
    // =======================================================

    if (
    this.isAnalyzing
    ) {

      return;
    }


    // =======================================================
    // 开始AI识别
    // =======================================================

    this.isAnalyzing =
      true;

    this.resultData =
      null;

    this.statusText =
      '正在识别衣物，请稍候...';

    this.speakText(
      '正在识别衣物，请稍候。'
    );


    // =======================================================
    // 创建HTTP请求
    // =======================================================

    const httpRequest =
      http.createHttp();


    try {

      // =====================================================
      // 读取图片
      // =====================================================

      let imageBytes:
        Uint8Array;


      // =====================================================
      // 测试图片
      // =====================================================

      if (
        this.imageUri ===
          'resource://RAWFILE/test_clothes.jpg'
      ) {

        console.info(
          '正在从rawfile读取测试图片'
        );

        const context = getContext(this) as common.UIAbilityContext;

        imageBytes =
          await context.resourceManager
            .getRawFileContent(
              'test_clothes.jpg'
            );

        console.info(
          `测试图片读取成功，` +
            `大小=${imageBytes.length} bytes`
        );

      } else {

        // ===================================================
        // 拍摄图片
        // ===================================================

        console.info(
          '正在从文件路径读取拍摄图片'
        );

        const file =
          await fileIo.open(
            this.imageUri,
            fileIo.OpenMode.READ_ONLY
          );

        try {

          const stat =
            await fileIo.stat(
              file.fd
            );

          const fileSize =
            stat.size;

          const buffer =
            new ArrayBuffer(
              fileSize
            );

          await fileIo.read(
            file.fd,
            buffer
          );

          imageBytes =
            new Uint8Array(
              buffer
            );

          console.info(
            `拍摄图片读取成功，` +
              `大小=${imageBytes.length} bytes`
          );

        } finally {

          await fileIo.close(
            file.fd
          );
        }
      }


      // =====================================================
      // 图片类型
      // =====================================================

      const contentType =
        this.getImageContentType(
          this.imageUri
        );

      let fileName =
        'clothes.jpg';

      if (
        contentType ===
          'image/png'
      ) {

        fileName =
          'clothes.png';

      } else if (
        contentType ===
          'image/webp'
      ) {

        fileName =
          'clothes.webp';
      }


      // =====================================================
      // 创建boundary
      // =====================================================

      const boundary =
        '----HarmonyOSClothingAI' +
        Date.now().toString();


      // =====================================================
      // 构造multipart body
      // =====================================================

      const multipartBody =
        this.buildMultipartBody(
          imageBytes,
          fileName,
          contentType,
          boundary
        );


      console.info(
        `multipart请求构造完成，` +
          `body大小=${multipartBody.byteLength}`
      );


      // =====================================================
      // HTTP请求配置
      // =====================================================

      const requestOptions:
        http.HttpRequestOptions = {

        method:
        http.RequestMethod.POST,

        header: {

          'Content-Type':
          `multipart/form-data; boundary=${boundary}`
        },

        extraData:
        multipartBody,

        expectDataType:
        http.HttpDataType.STRING,

        connectTimeout:
        10000,

        readTimeout:
        60000
      };


      // =====================================================
      // 输出请求日志
      // =====================================================

      console.info(
        '===================================='
      );

      console.info(
        '开始上传图片到Spring Boot'
      );

      console.info(
        '服务器地址：' +
        this.serverUrl
      );

      console.info(
        'Content-Type：' +
          requestOptions.header?.[
          'Content-Type'
          ]
      );

      console.info(
        '图片大小：' +
        imageBytes.length +
          ' bytes'
      );

      console.info(
        '===================================='
      );


      // =====================================================
      // 发送请求
      // =====================================================

      const response =
        await httpRequest.request(
          this.serverUrl,
          requestOptions
        );


      // =====================================================
      // 打印响应
      // =====================================================

      console.info(
        `服务器响应状态码：` +
        response.responseCode
      );

      console.info(
        '服务器返回：' +
        response.result
      );


      // =====================================================
      // HTTP状态检查
      // =====================================================

      if (
        response.responseCode < 200 ||
          response.responseCode >= 300
      ) {

        throw new Error(
          `服务器返回错误状态码：` +
          response.responseCode +
            `，内容：` +
          response.result
        );
      }


      // =====================================================
      // 解析JSON
      // =====================================================

      const responseText =
        response.result as string;

      const responseData =
        JSON.parse(
          responseText
        ) as AIResponse;


      // =====================================================
      // 判断AI识别结果
      // =====================================================

      if (
        responseData.success &&
        responseData.data
      ) {

        const result =
          responseData.data;


        // ===================================================
        // 保存AI结果
        // ===================================================

        this.resultData =
          result;

        this.statusText =
          'AI识别完成';


        // ===================================================
        // 输出结果
        // ===================================================

        console.info(
          'AI识别结果：' +
          JSON.stringify(result)
        );


        // ===================================================
        // 构造播报文本
        // ===================================================

        const speechText =
          this.buildSpeechText(
            result
          );

        console.info(
          '播报内容：' +
            speechText
        );


        // ===================================================
        // 自动播报
        // ===================================================

        this.speakText(
          speechText
        );

      } else {

        throw new Error(
          responseData.message ||
            'AI识别失败'
        );
      }

    } catch (error) {

      const err =
        error as BusinessError;

      console.error(
        '===================================='
      );

      console.error(
        'AI识别异常'
      );

      console.error(
        `错误码：${err.code}`
      );

      console.error(
        `错误信息：${err.message}`
      );

      console.error(
        '===================================='
      );


      this.statusText =
        'AI识别失败，请稍后重试';

      this.resultData =
        null;


      // =====================================================
      // 失败语音
      // =====================================================

      this.speakText(
        '衣物识别失败，请稍后重试。'
      );

    } finally {

      this.isAnalyzing =
        false;


      // =====================================================
      // 销毁HTTP请求
      // =====================================================

      try {

        httpRequest.destroy();

      } catch (error) {

        console.error(
          'HTTP请求销毁失败：' +
          JSON.stringify(error)
        );
      }
    }
  }


  // =========================================================
  // 页面UI
  // =========================================================

  build() {

    Scroll() {

      Column() {

        // ===================================================
        // 顶部区域
        // ===================================================

        Row() {

          Column() {

            Text('AI衣物识别')
              .fontSize(28)
              .fontWeight(
                FontWeight.Bold
              )
              .fontColor(
                '#1A1A1A'
              );

            Text(
              '智能识别衣物属性'
            )
              .fontSize(15)
              .fontColor(
                '#777777'
              )
              .margin({
                top: 6
              });

          }
          .alignItems(
            HorizontalAlign.Start
          )
          .layoutWeight(1);


          Column() {

            Text('AI')
              .fontSize(15)
              .fontWeight(
                FontWeight.Bold
              )
              .fontColor(
                '#1677FF'
              );

          }
          .width(48)
          .height(48)
          .justifyContent(
            FlexAlign.Center
          )
          .alignItems(
            HorizontalAlign.Center
          )
          .backgroundColor(
            '#EAF3FF'
          )
          .borderRadius(24);

        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 24,
          bottom: 16
        });


        // ===================================================
        // 图片展示卡片
        // ===================================================

        Column() {

          if (this.hasImage) {

            Image(this.imageUri)
              .width('100%')
              .height(270)
              .objectFit(
                ImageFit.Contain
              )
              .borderRadius(16);

          } else {

            Column() {

              Text('👕')
                .fontSize(64);

              Text(
                '还没有选择衣物图片'
              )
                .fontSize(18)
                .fontWeight(
                  FontWeight.Medium
                )
                .fontColor(
                  '#555555'
                )
                .margin({
                  top: 12
                });

              Text(
                '拍照或选择测试图片'
              )
                .fontSize(14)
                .fontColor(
                  '#999999'
                )
                .margin({
                  top: 7
                });

            }
            .width('100%')
            .height(270)
            .justifyContent(
              FlexAlign.Center
            )
            .alignItems(
              HorizontalAlign.Center
            );
          }

        }
        .width('90%')
        .padding(12)
        .backgroundColor(
          '#FFFFFF'
        )
        .borderRadius(20)
        .shadow({
          radius: 14,
          color: '#22000000',
          offsetX: 0,
          offsetY: 4
        });


        // ===================================================
        // 图片操作按钮
        // ===================================================

        Row() {

          // =================================================
          // 拍照
          // =================================================

          Button() {

            Row() {

              Text('📷')
                .fontSize(20)
                .margin({
                  right: 7
                });

              Text('拍照')
                .fontSize(16)
                .fontWeight(
                  FontWeight.Medium
                );

            }
            .justifyContent(
              FlexAlign.Center
            );

          }
          .width('47%')
          .height(50)
          .backgroundColor(
            '#FFFFFF'
          )
          .fontColor(
            '#222222'
          )
          .borderRadius(14)
          .onClick(() => {

            this.takePhoto();

          });


          // =================================================
          // 测试图片
          // =================================================

          Button() {

            Row() {

              Text('🖼️')
                .fontSize(20)
                .margin({
                  right: 7
                });

              Text('测试图片')
                .fontSize(16)
                .fontWeight(
                  FontWeight.Medium
                );

            }
            .justifyContent(
              FlexAlign.Center
            );

          }
          .width('47%')
          .height(50)
          .backgroundColor(
            '#FFFFFF'
          )
          .fontColor(
            '#222222'
          )
          .borderRadius(14)
          .onClick(() => {

            this.loadTestImage();

          });

        }
        .width('90%')
        .justifyContent(
          FlexAlign.SpaceBetween
        )
        .margin({
          top: 15
        });


        // ===================================================
        // AI识别按钮
        // ===================================================

        Button() {

          Row() {

            if (
            this.isAnalyzing
            ) {

              LoadingProgress()
                .width(22)
                .height(22)
                .margin({
                  right: 10
                });

            } else {

              Text('✨')
                .fontSize(21)
                .margin({
                  right: 8
                });
            }


            Text(
              this.isAnalyzing
                ? '正在分析衣物...'
                : '开始 AI 识别'
            )
              .fontSize(17)
              .fontWeight(
                FontWeight.Medium
              );

          }
          .justifyContent(
            FlexAlign.Center
          );

        }
        .width('90%')
        .height(56)
        .margin({
          top: 15
        })
        .backgroundColor(
          this.isAnalyzing
            ? '#8CB8FF'
            : '#1677FF'
        )
        .fontColor(
          '#FFFFFF'
        )
        .borderRadius(16)
        .enabled(
          !this.isAnalyzing
        )
        .onClick(() => {

          this.analyzeImage();

        });


        // ===================================================
        // 当前状态
        // ===================================================

        Row() {

          Text('●')
            .fontSize(10)
            .fontColor(
              this.isAnalyzing
                ? '#1677FF'
                : '#52C41A'
            )
            .margin({
              right: 8
            });

          Text(
            this.statusText
          )
            .fontSize(14)
            .fontColor(
              '#666666'
            )
            .layoutWeight(1)
            .textAlign(
              TextAlign.Center
            );

        }
        .width('90%')
        .padding({
          top: 13,
          bottom: 5
        })
        .justifyContent(
          FlexAlign.Center
        );


        // ===================================================
        // AI识别结果
        // ===================================================

        if (
          this.resultData !== null
        ) {

          Column() {

            // ===============================================
            // 结果标题
            // ===============================================

            Row() {

              Column() {

                Text(
                  '识别结果'
                )
                  .fontSize(20)
                  .fontWeight(
                    FontWeight.Bold
                  )
                  .fontColor(
                    '#222222'
                  );

                Text(
                  'AI 已完成衣物分析'
                )
                  .fontSize(13)
                  .fontColor(
                    '#999999'
                  )
                  .margin({
                    top: 4
                  });

              }
              .alignItems(
                HorizontalAlign.Start
              )
              .layoutWeight(1);


              Text('✓')
                .fontSize(18)
                .fontWeight(
                  FontWeight.Bold
                )
                .fontColor(
                  '#FFFFFF'
                )
                .width(34)
                .height(34)
                .textAlign(
                  TextAlign.Center
                )
                .backgroundColor(
                  '#52C41A'
                )
                .borderRadius(17);

            }
            .width('100%')
            .margin({
              bottom: 18
            });


            // ===============================================
            // 核心识别结果
            // ===============================================

            Column() {

              Text(
                this.resultData.color +
                this.resultData.type
              )
                .fontSize(24)
                .fontWeight(
                  FontWeight.Bold
                )
                .fontColor(
                  '#1677FF'
                )
                .margin({
                  bottom: 6
                });

              Text(
                this.resultData.category
              )
                .fontSize(14)
                .fontColor(
                  '#777777'
                );

            }
            .width('100%')
            .padding({
              top: 16,
              bottom: 16
            })
            .backgroundColor(
              '#F4F8FF'
            )
            .borderRadius(14)
            .justifyContent(
              FlexAlign.Center
            )
            .alignItems(
              HorizontalAlign.Center
            );


            // ===============================================
            // 详细属性
            // ===============================================

            Column() {

              this.ResultRow(
                '衣物类别',
                this.resultData.category
              );

              this.ResultRow(
                '具体类型',
                this.resultData.type
              );

              this.ResultRow(
                '主要颜色',
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
                '识别置信度',
                `${Math.round(
                  this.resultData.confidence *
                    100
                )}%`
              );

            }
            .width('100%')
            .margin({
              top: 10
            });


            // ===============================================
            // 语音播报按钮
            // ===============================================

            if (
            this.isSpeaking
            ) {

              Button() {

                Row() {

                  Text('🛑')
                    .fontSize(20)
                    .margin({
                      right: 8
                    });

                  Text(
                    '停止播报'
                  )
                    .fontSize(16)
                    .fontWeight(
                      FontWeight.Medium
                    );

                }
                .justifyContent(
                  FlexAlign.Center
                );

              }
              .width('100%')
              .height(52)
              .margin({
                top: 18
              })
              .backgroundColor(
                '#FF4D4F'
              )
              .fontColor(
                '#FFFFFF'
              )
              .borderRadius(14)
              .onClick(() => {

                this.stopSpeaking();

              });

            } else {

              Button() {

                Row() {

                  Text('🔊')
                    .fontSize(20)
                    .margin({
                      right: 8
                    });

                  Text(
                    '再次播报识别结果'
                  )
                    .fontSize(16)
                    .fontWeight(
                      FontWeight.Medium
                    );

                }
                .justifyContent(
                  FlexAlign.Center
                );

              }
              .width('100%')
              .height(52)
              .margin({
                top: 18
              })
              .backgroundColor(
                '#1677FF'
              )
              .fontColor(
                '#FFFFFF'
              )
              .borderRadius(14)
              .onClick(() => {

                if (
                  this.resultData !== null
                ) {

                  const speechText =
                    this.buildSpeechText(
                      this.resultData
                    );

                  this.speakText(
                    speechText
                  );
                }

              });
            }


            // ===============================================
            // 下一阶段功能入口
            // ===============================================

            Row() {

              Text('👗')
                .fontSize(18)
                .margin({
                  right: 8
                });

              Column() {

                Text(
                  '智能穿搭推荐'
                )
                  .fontSize(15)
                  .fontWeight(
                    FontWeight.Medium
                  )
                  .fontColor(
                    '#333333'
                  );

                Text(
                  '下一步将根据天气和场景推荐搭配'
                )
                  .fontSize(12)
                  .fontColor(
                    '#999999'
                  )
                  .margin({
                    top: 3
                  });

              }
              .alignItems(
                HorizontalAlign.Start
              )
              .layoutWeight(1);

              Text('›')
                .fontSize(26)
                .fontColor(
                  '#AAAAAA'
                );

            }
            .width('100%')
            .padding({
              left: 14,
              right: 14,
              top: 13,
              bottom: 13
            })
            .margin({
              top: 15
            })
            .backgroundColor(
              '#F8F9FB'
            )
            .borderRadius(14);

          }
          .width('90%')
          .padding(20)
          .margin({
            top: 18,
            bottom: 30
          })
          .backgroundColor(
            '#FFFFFF'
          )
          .borderRadius(20)
          .shadow({
            radius: 12,
            color: '#22000000',
            offsetX: 0,
            offsetY: 3
          });
        }

      }
      .width('100%')
      .backgroundColor(
        '#F6F8FB'
      );

    }
    .width('100%')
    .height('100%')
    .backgroundColor(
      '#F6F8FB'
    );
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
        .fontColor(
          '#777777'
        )
        .width('30%');

      Text(value)
        .fontSize(16)
        .fontColor(
          '#222222'
        )
        .fontWeight(
          FontWeight.Medium
        )
        .layoutWeight(1)
        .textAlign(
          TextAlign.End
        );

    }
    .width('100%')
    .padding({
      top: 10,
      bottom: 10
    });
  }
}