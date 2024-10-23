import fs from '@ohos.file.fs';
import { NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk';
import * as common from '../model/common'

enum NaluType {
  NALU_TYPE_SLICE    = 1,
  NALU_TYPE_DPA      = 2,
  NALU_TYPE_DPB      = 3,
  NALU_TYPE_DPC      = 4,
  NALU_TYPE_IDR      = 5,
  NALU_TYPE_SEI      = 6,
  NALU_TYPE_SPS      = 7,
  NALU_TYPE_PPS      = 8,
  NALU_TYPE_AUD      = 9,
  NALU_TYPE_EOSEQ    = 10,
  NALU_TYPE_EOSTREAM = 11,
  NALU_TYPE_FILL     = 12,
}

enum NaluPriority {
  NALU_PRIORITY_DISPOSABLE = 0,
  NALU_PRIRITY_LOW         = 1,
  NALU_PRIORITY_HIGH       = 2,
  NALU_PRIORITY_HIGHEST    = 3
}

class Nalu {
  start_code_len: number = 0;
  head: number = 0;
  pos_start: number = 0;
  pos_end: number = 0;
  len: number = 0;
}

export default class PushExternalH264Video {

  private TAG: string = "PushExternalH264Video"

  private stopFlag: boolean = false
  private valid: boolean = false
  private width: number = 0
  private height: number = 0
  private fps: number = 15
  private buffer?: Uint8Array
  private size: number = 0
  private curPos: number = 0
  private file?: fs.File
  private randomFile?: fs.RandomAccessFile
  private nalu_vec: Array<Nalu> = new Array<Nalu>()
  private complete: boolean = false
  private index: number = 0
  private lens: number = 0
  private type: NERtcConstants.NERtcVideoStreamType
  private intervalId: number = -1

  constructor(product: common.Product, type: NERtcConstants.NERtcVideoStreamType, path: string, width: number, height: number, fps: number) {
    this.width = width
    this.height = height
    this.fps = fps
    this.type = type
    this.stopFlag = true
    console.info(this.TAG, '==== ExternalH264Source path: ' + path + 'type: ' + this.type + ", width: " + this.width + ", height: " + this.height + ", fps: " + this.fps)

    try {
      console.info(this.TAG, 'product: ' + product)
      let dir: string = getContext().filesDir + "/media"

      console.info(this.TAG, 'RESOUCE_PATH: ' + dir)
      path = dir + "/" + path
      if(!fs.accessSync(path)) {
        console.error(this.TAG, 'ACCESS file faile.')
        return
      }
    } catch (e) {
      console.error(this.TAG, 'ACCESS file error. message: ' + JSON.stringify(e))
      return
    }

    let stats = fs.statSync(path)
    this.size = stats.size
    this.valid = this.readFile(path) == 0
  }

  private readFile(path: string): number {

    this.file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    this.randomFile = fs.createRandomAccessFileSync(this.file)

    let buf = new ArrayBuffer(this.size)
    this.randomFile.setFilePointer(0)

    let len = this.randomFile.readSync(buf)
    if(len != this.size) {
      console.error(this.TAG, 'read file failed.')
      return -1
    }

    this.buffer = new Uint8Array(buf)
    while(!this.complete) {
      let nalu = this.getNalu()
      if(!nalu) return -1
      this.nalu_vec.push(nalu)
    }

    console.info(this.TAG, '=== nalu_vec size: ' + this.nalu_vec.length + " ====")
    return 0
  }

  private getNalu(): Nalu|null {

    if(!this.buffer) {
      console.error(this.TAG, 'getNalu error code: -1')
      return null
    }

    let startCodeFound: boolean = this.isStartCode3B(this.buffer, this.curPos) || this.isStartCode4B(this.buffer, this.curPos)
    if(!startCodeFound) {
      console.error(this.TAG, 'h264 file is invalid.')
      return null
    }

    let startCodeLen = 0
    if(this.isStartCode3B(this.buffer, this.curPos)) {
      startCodeLen = 3
    } else {
      startCodeLen = 4
    }

    // find next start code.
    let tmpPos = this.curPos + startCodeLen
    let hasNextStartCode = false
    let nextStartCodeLen = 0
    while (!hasNextStartCode) {
      if(tmpPos + 3 > this.size) {
        break;
      } else {
        if(this.isStartCode3B(this.buffer, tmpPos)) {
          hasNextStartCode = true
          nextStartCodeLen = 3
          break;
        } else {
          if(tmpPos + 4 > this.size) {
            break;
          } else {
            if(this.isStartCode4B(this.buffer, tmpPos)) {
              hasNextStartCode = true
              nextStartCodeLen = 4
              break;
            }
          }
        }
      }
      tmpPos ++
    }
    let nalu: Nalu = new Nalu
    if(hasNextStartCode) {
      nalu.start_code_len = startCodeLen
      nalu.len = tmpPos - this.curPos // include start code.
      nalu.pos_start = this.curPos + startCodeLen
      nalu.pos_end = tmpPos
      nalu.head = this.buffer[nalu.pos_start]
      this.curPos = tmpPos
    } else {
      nalu.start_code_len = startCodeLen
      nalu.len = this.size - this.curPos
      nalu.pos_start = this.curPos + startCodeLen
      nalu.pos_end = this.size
      nalu.head = this.buffer[nalu.pos_start]
      this.curPos = 0
      this.complete = true
    }
    return nalu
  }

  private isStartCode3B(buf: Uint8Array, offset: number): boolean {
    return (buf[0 + offset] == 0 && buf[1 + offset] == 0 && buf[2 + offset] == 1); //0x000001
  }

  private isStartCode4B(buf: Uint8Array, offset: number): boolean {
    return (buf[0 + offset] == 0 && buf[1 + offset] == 0 && buf[2 + offset] == 0 && buf[3 + offset] == 1); //0x00000001
  }

  start(): boolean {

    if(!this.valid) {
      console.error(this.TAG, 'video file is invalid.')
      return false
    }

    if(this.stopFlag) {
      this.stopFlag = false
    } else {
      console.error(this.TAG, 'push external h264 is started, cannot start repeat' )
      return false
    }

    if(!this.file) {
      console.error(this.TAG, 'file is error.')
      return false
    }

    this.randomFile?.setFilePointer(0)
    let timediff = 1000 / this.fps
    this.intervalId = setInterval(() => {
      this.pushExternalH264VideoImpl()
    }, timediff)
    return true
  }

  stop() : boolean {
    if(this.stopFlag) {
      return false
    }

    clearInterval(this.intervalId)
    this.intervalId = -1

    this.stopFlag = true
    this.nalu_vec = []

    this.complete = false
    this.curPos = 0
    this.index = 0
    this.lens = 0
    this.randomFile?.close()
    fs.close(this.file)
    return true
  }

  private pushExternalH264VideoImpl(): number {

    let frame: NERtcConstants.NERtcVideoEncodedFrame = new NERtcConstants.NERtcVideoEncodedFrame
    let nalLen: Uint32Array = new Uint32Array(40)
    let interIndex = 0
    while(true) {
      let nalu = this.nalu_vec[this.index++]
      nalLen[interIndex++] = nalu.len
      if(interIndex >= 10) {
        console.error(this.TAG, 'nalu num more than 10.')
        return -1
      }

      if((nalu.head & 0x1f) == NaluType.NALU_TYPE_SEI ||
        (nalu.head & 0x1f) == NaluType.NALU_TYPE_SPS ||
        (nalu.head & 0x1f) == NaluType.NALU_TYPE_PPS) {
        continue
      }

      if((nalu.head & 0x1f) == NaluType.NALU_TYPE_IDR) {
        frame.frameType = NERtcConstants.NERtcNalFrameType.NAL_FRAME_TYPE_IDR;
        break;
      } else {
        frame.frameType = NERtcConstants.NERtcNalFrameType.NAL_FRAME_TYPE_P;
        break;
      }
    }

    frame.width = this.width
    frame.height = this.height
    frame.codecType = NERtcConstants.NERtcVideoCodecType.VIDEO_CODEC_TYPE_H264
    frame.timestampUs = Date.now() * 1000

    let lengthArray: number[] = []
    let len = 0
    for(let i = 0; i < interIndex; i++) {
      lengthArray.push(nalLen[i])
      len += nalLen[i]
    }
    this.lens += len

    let arrayBuffer = new ArrayBuffer(len)
    let read = this.randomFile?.readSync(arrayBuffer)
    if(read != len) {
      console.warn(this.TAG, '=== read buf error === len: ' + len + ", read: " + read)
      return -1
    }
    this.randomFile?.setFilePointer(this.lens)

    frame.nalData = new Uint8Array(arrayBuffer)
    frame.nalLengths = new Uint32Array(lengthArray)

    if(this.index >= this.nalu_vec.length) {
      this.index = 0
      this.lens = 0
      this.randomFile?.setFilePointer(0)
      return -1
    }

    let ret = NERtcSDK.getInstance().pushExternalVideoEncodedFrame(this.type, frame)
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      console.error(this.TAG, 'push encoded video frame error: ' + ret)
    }
    return ret
  }


}

