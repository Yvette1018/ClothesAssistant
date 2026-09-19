import util from '@ohos.util';

/**
 * Multipart/form-data 请求工具。
 * 负责把图片二进制和表单头尾拼接成完整请求体。
 */
export class MultipartUtil {

  static concatUint8Arrays(parts: Uint8Array[]): Uint8Array {
    let totalLength: number = 0;

    for (let i = 0; i < parts.length; i++) {
      totalLength += parts[i].length;
    }

    const result = new Uint8Array(totalLength);
    let offset: number = 0;

    for (let i = 0; i < parts.length; i++) {
      result.set(parts[i], offset);
      offset += parts[i].length;
    }

    return result;
  }

  static buildImageBody(
    imageBytes: Uint8Array,
    fileName: string,
    contentType: string,
    boundary: string
  ): ArrayBuffer {
    const encoder = new util.TextEncoder();

    const headerText =
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
      `Content-Type: ${contentType}\r\n` +
      `\r\n`;

    const footerText =
      `\r\n--${boundary}--\r\n`;

    const headerBytes = encoder.encodeInto(headerText);
    const footerBytes = encoder.encodeInto(footerText);

    const body = MultipartUtil.concatUint8Arrays([
      headerBytes,
      imageBytes,
      footerBytes
    ]);

    return body.buffer;
  }
}
