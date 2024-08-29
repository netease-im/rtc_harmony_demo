import fs from '@ohos.file.fs';
import { collections } from '@kit.ArkTS'

"use shared"

@Sendable
export class RtcDemoFileInfo {
  fd: number = 0;
  offset: number = 0;
  path: string = "";
}

@Sendable
export default class RtcDemoFileManager {
  private static instance: RtcDemoFileManager = new RtcDemoFileManager();
  private tag: string = "RtcDemoFileManager";
  private fileInfoMap: collections.Map<number, RtcDemoFileInfo> = new collections.Map<number, RtcDemoFileInfo>();

  public static sharedInstance(): RtcDemoFileManager {
    return RtcDemoFileManager.instance;
  }

  public createFile(folderPath: string, fileName: string): RtcDemoFileInfo|null {
    let fileInfo: RtcDemoFileInfo|null = null;
    let filePath = folderPath + "/" + fileName;
    try {
      if (!fs.accessSync(folderPath)) {
        fs.mkdirSync(folderPath);
        console.info(this.tag, `folder not found, will create path:${folderPath}`);
      }
      let file = fs.openSync(filePath, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE);
      if (file) {
        console.info(this.tag, `create file succeed, filePath:${filePath}, fd:${file.fd}`);
        fileInfo = new RtcDemoFileInfo();
        fileInfo.fd = file.fd;
        fileInfo.path = filePath;
        this.fileInfoMap.set(file.fd, fileInfo);
      } else {
        console.error(this.tag, `create file failed, filePath:${filePath}`);
      }
      return fileInfo;
    } catch (e) {
      console.error(this.tag, `create file failed, filePath:${filePath}, error:${JSON.stringify(e)}`);
      return fileInfo;
    }
  }

  public closeFile(fd: number): void {
    let fileInfo = this.fileInfoMap.get(fd);
    if (fileInfo == undefined) {
      console.warn(this.tag, `close file failed, file for fd:${fd} not found`);
      return;
    }

    try {
      fs.closeSync(fd);
      this.fileInfoMap.delete(fd);
      console.info(this.tag, `close file succeed, fd:${fd}, filePath:${fileInfo.path}`);
    } catch (e) {
      console.error(this.tag, `close file failed, fd:${fd}, filePath:${fileInfo.path}, error:${JSON.stringify(e)}`);
    }
  }

  public deleteFile(fd: number): void {
    let fileInfo = this.fileInfoMap.get(fd);
    if (fileInfo == undefined) {
      console.warn(this.tag, `delete file failed, file for fd:${fd} not found`);
      return;
    }

    try {
      fs.unlinkSync(fileInfo.path);
      console.info(this.tag, `delete file succeed, fd:${fd}, filePath:${fileInfo.path}`);
    } catch (e) {
      console.error(this.tag, `delete file failed, fd:${fd}, filePath:${fileInfo.path}`)
    }
  }

  public writeDataToFile(fd: number, data?: Uint8Array|null): boolean {
    if (data == null || data == undefined) {
      console.warn(this.tag, `write data to file failed, data is invalid`);
      return false;
    }

    let fileInfo = this.fileInfoMap.get(fd);
    if (fileInfo == undefined) {
      console.warn(this.tag, `write data to file failed, file for fd:${fd} not found, must create file first`);
      return false;
    }

    try {
      let length = fs.writeSync(fd, data.buffer as ArrayBuffer, { offset: fileInfo.offset, length: data.byteLength });
      if (length != data.byteLength) {
        console.error(this.tag, `write data to file failed, fd:${fd}, length:${length} does not match data.byteLength:${data.byteLength}`);
        return false;
      }
      fileInfo.offset += length;
      // console.info(this.tag, `write, fd:${fileInfo.fd}, offset:${fileInfo.offset}, dataLength:${data.byteLength}`);
      return true;
    } catch (e) {
      console.error(this.tag, `write data to file failed, fd:${fd}, error:${JSON.stringify(e)}`);
      return false;
    }
  }
}