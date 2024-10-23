import { NERtcConstants, NERtcPreDecodeObserver } from '@nertc/nertc_sdk'
import { collections } from '@kit.ArkTS'
import fs from '@ohos.file.fs'

@Sendable
export class DemoNERtcPreDecodeObserver implements NERtcPreDecodeObserver {

  private TAG: string = "MyPreDecodeObserver"
  private dir?: string
  private collections: collections.Map<string, number> = new collections.Map
  private offsets: collections.Map<number, number> = new collections.Map

  constructor(path: string) {
    this.dir = path
    try {
      if(!fs.accessSync(path)) {
        fs.mkdirSync(path)
        console.info(this.TAG, `dir not found, create path: ${this.dir}`)
      }
    } catch (e) {
      console.error(this.TAG, 'mkdir dir failed.')
    }
  }

  onFrame(preDecodeFrame: NERtcConstants.NERtcPreDecodeFrameInfo): void {

    try {
      let uid: bigint = preDecodeFrame.uid
      let mediaType: number = preDecodeFrame.mediaType
      let stuff: string = preDecodeFrame.codec
      let isMain: string = preDecodeFrame.isMainStream ? 'main':'sub'

      let key = String(uid) + '_' + String(mediaType.valueOf()) + "_" + stuff + "_" + isMain
      let fd = this.collections.get(key)
      if(!fd) {
        let file = fs.openSync(this.dir + '/' + key, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE)
        if(file) {
          this.collections.set(key, file.fd)
          this.offsets.set(file.fd, 0)
          fd = file.fd
        } else {
          throw Error(`create file on dir ${this.dir} error.`)
        }
      }

      if(preDecodeFrame.data && fd) {
        let offset = this.offsets.get(fd)
        if(offset == undefined) offset = 0

        let byteLength: number = preDecodeFrame.data.byteLength
        let frameLen: number = preDecodeFrame.length
        console.info(this.TAG, `byteLength: ${byteLength}, frameLen: ${frameLen}`)

        let len = fs.writeSync(fd, preDecodeFrame.data.buffer, { offset: offset, length: preDecodeFrame.length })
        if(len != preDecodeFrame.length) {
          console.error(this.TAG, 'write into file, len not match.')
        }
        console.info(this.TAG, `write fd: ${fd} offset: ${offset} len: ${len}` )
        offset += len
        this.offsets.set(fd, offset)
      } else {
        console.info(this.TAG, `== preDecodeFrame data:${preDecodeFrame}, fd:${fd}`)
      }
    } catch (e) {
      console.error(this.TAG, 'onFrame execute error: ' + JSON.stringify(e))
    }
  }

  clear() {
    for(let fd of this.collections.values()) {
      fs.close(fd)
    }
    this.offsets.clear()
    this.collections.clear()
  }
}