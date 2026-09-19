import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError } from '@ohos.base';

/**
 * TTS服务：统一负责初始化、播放、停止和状态回调。
 */
export class TtsService {

  private engine:
    textToSpeech.TextToSpeechEngine | null = null;

  private speakingListener:
    ((speaking: boolean) => void) | null = null;

  setSpeakingListener(
    listener: (speaking: boolean) => void
  ): void {
    this.speakingListener = listener;
  }

  init(): void {
    if (this.engine !== null) {
      return;
    }

    const extraParams: Record<string, Object> = {
      'style': 'interaction-broadcast',
      'locate': 'CN',
      'name': 'ClothingAI'
    };

    const initParams:
      textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: extraParams
    };

    try {
      textToSpeech.createEngine(
        initParams,
        (
          err: BusinessError,
          engine: textToSpeech.TextToSpeechEngine
        ) => {
          if (err) {
            console.error(
              `TTS引擎创建失败：${err.code} ${err.message}`
            );
            return;
          }

          console.info('TTS引擎创建成功');

          this.engine = engine;

          this.engine.setListener({
            onStart: (
              requestId: string,
              response: textToSpeech.StartResponse
            ) => {
              console.info(
                `TTS开始播报，requestId=${requestId}`
              );
              this.notifySpeaking(true);
            },

            onComplete: (
              requestId: string,
              response: textToSpeech.CompleteResponse
            ) => {
              console.info(
                `TTS播报完成，requestId=${requestId}`
              );
              if (response.type === 1) {
                this.notifySpeaking(false);
              }
            },

            onStop: (
              requestId: string,
              response: textToSpeech.StopResponse
            ) => {
              console.info(
                `TTS停止播报，requestId=${requestId}`
              );
              this.notifySpeaking(false);
            },

            onData: (
              requestId: string,
              audio: ArrayBuffer,
              response: textToSpeech.SynthesisResponse
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
                `TTS错误：${requestId} ${errorCode} ${errorMessage}`
              );
              this.notifySpeaking(false);
            }
          });
        }
      );
    } catch (error) {
      const err = error as BusinessError;
      console.error(
        `TTS初始化异常：${err.code} ${err.message}`
      );
    }
  }

  speak(text: string): void {
    if (!text || text.trim() === '') {
      return;
    }

    if (this.engine === null) {
      console.error('TTS引擎还没有初始化');
      this.init();
      return;
    }

    const extraParams: Record<string, Object> = {
      'queueMode': 1,
      'speed': 1,
      'volume': 2,
      'pitch': 1,
      'languageContext': 'zh-CN',
      'audioType': 'pcm',
      'soundChannel': 3,
      'playType': 1
    };

    const speakParams:
      textToSpeech.SpeakParams = {
      requestId: 'clothing-ai-' + Date.now(),
      extraParams: extraParams
    };

    try {
      this.notifySpeaking(true);
      this.engine.speak(
        text,
        speakParams
      );
    } catch (error) {
      const err = error as BusinessError;
      console.error(
        `TTS播报异常：${err.code} ${err.message}`
      );
      this.notifySpeaking(false);
    }
  }

  stop(): void {
    if (this.engine === null) {
      return;
    }

    try {
      this.engine.stop();
      this.notifySpeaking(false);
    } catch (error) {
      const err = error as BusinessError;
      console.error(
        `停止TTS失败：${err.code} ${err.message}`
      );
      this.notifySpeaking(false);
    }
  }

  private notifySpeaking(
    speaking: boolean
  ): void {
    if (this.speakingListener !== null) {
      this.speakingListener(speaking);
    }
  }
}
