import { fileIo, fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

/**
 * 图片服务：统一处理 rawfile、拍照文件和本地 URI。
 */
export class ImageService {

  static readonly TEST_IMAGE_NAME: string = 'test_clothes.jpg';
  static readonly TEST_IMAGE_TAG: string = 'test_clothes.jpg';

  async loadTestImage(
    context: common.UIAbilityContext
  ): Promise<string> {
    const imageBytes: Uint8Array =
      await context.resourceManager.getRawFileContent(
        ImageService.TEST_IMAGE_NAME
      );

    const filePath: string =
      context.filesDir + '/' + ImageService.TEST_IMAGE_NAME;

    try {
      fileIo.unlinkSync(filePath);
    } catch (error) {
      console.info('旧测试图片不存在，无需删除');
    }

    const file = fileIo.openSync(
      filePath,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE
    );

    try {
      fileIo.writeSync(file.fd, imageBytes.buffer);
    } finally {
      fileIo.closeSync(file);
    }

    return fileUri.getUriFromPath(filePath);
  }

  async readImage(
    context: common.UIAbilityContext,
    imageUri: string
  ): Promise<Uint8Array> {
    if (imageUri.includes(ImageService.TEST_IMAGE_TAG)) {
      return await context.resourceManager.getRawFileContent(
        ImageService.TEST_IMAGE_NAME
      );
    }

    const file = fileIo.openSync(
      imageUri,
      fileIo.OpenMode.READ_ONLY
    );

    try {
      const stat = fileIo.statSync(file.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      return new Uint8Array(buffer);
    } finally {
      fileIo.closeSync(file);
    }
  }

  getImageContentType(uri: string): string {
    const lower: string = uri.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  getFileName(contentType: string): string {
    if (contentType === 'image/png') {
      return 'clothes.png';
    }

    if (contentType === 'image/webp') {
      return 'clothes.webp';
    }

    return 'clothes.jpg';
  }
}
