import fs from '@ohos.file.fs';
import { NERtcSDK, NERtcConstants} from '@nertc/nertc_sdk'
import * as common from '../model/common'

enum FrameType{
  frameTypeSps = 0,
  frameTypepps = 1,
  frameTypeKeyFrame = 2,
  frameTypeNonKeyFrame = 3,
  frameTypeSei = 4
}

class videoFrame{
  data: ArrayBuffer;
  bufferView: Uint8Array;
  size: number
  frameType: number;

  constructor() {
    this.data = new ArrayBuffer(1024 * 1024 * 10);
    this.bufferView = new Uint8Array(this.data);
    this.size = 0;
    this.frameType = -1;
  }
}

class spsFrame{
  data: Uint8Array;
  size: number

  constructor() {
    this.data = new Uint8Array(1024 * 5)
    this.size = 0;
  }
}

class ppsFrame{
  data: Uint8Array;
  size: number

  constructor() {
    this.data = new Uint8Array(1024 * 5)
    this.size = 0;
  }
}

export default class ExternalH264Source {

  private TAG: string = "ExternalH264Source"

  private destBuffer: Uint8Array = new Uint8Array(1024 * 1024 * 10 + 1024 * 10)
  private nextSendTime: number = 0
  private gOffset: number = 0
  private delayTime: number = 0

  private videoFrame = new videoFrame()
  private spsFrame = new spsFrame()
  private ppsFrame = new ppsFrame()

  private width: number = 640
  private height: number = 480

  private file?: fs.File
  private type: NERtcConstants.NERtcVideoStreamType
  // private timeoutId: number = -1
  private running: boolean = false
  private fps: number = 15
  private intervalTaskId: number = -1

  constructor(product: common.Product, type: NERtcConstants.NERtcVideoStreamType, path: string, width: number, height: number, fps: number) {
    this.width = width
    this.height = height
    this.type = type
    this.fps = fps
    console.info(this.TAG, '=== ExternalH264Source path: ' + path + ", type: " + this.type + ", width: " + this.width + ", height: " + this.height + ", fps: " + this.fps)

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
    this.file = fs.openSync(path, fs.OpenMode.READ_ONLY)
  }

  start(): boolean {
    if(this.running) {
      console.info(this.TAG, 'You have push encoded video frame aready.')
      return true
    }

    if(!this.file) {
      console.warn(this.TAG, 'file is error.')
      return false
    }
    this.running = true
    this.gOffset = 0
    // this.nextSendTime = Date.now() + 1000 / this.fps
    // this.timeoutId = setTimeout(this.parse264, 0)

    let duration: number = 1000 / this.fps;
    console.info(this.TAG, 'Interval duration: ' + duration)
    this.intervalTaskId = setInterval(() => {

      if(!this.running)
      {
        this.reset()
        console.info(this.TAG, 'user stop push encode video frame.')
        return
      }

      let ret = this.readOneFrame(this.videoFrame, this.gOffset)
      if(ret < 0){
        this.reset()
        return
      }
      this.gOffset += ret
      this.sendH264Frame(this.videoFrame, this.spsFrame, this.ppsFrame)

    }, duration)
    return true
  }

  private reset() {
    this.running = false
    this.gOffset = 0;
    clearInterval(this.intervalTaskId)
    this.intervalTaskId = -1
  }

  stop(): boolean {
    if(!this.running) {
      console.info(this.TAG, 'You have stop push encoded video frame.')
      return true
    }

    this.reset()
    return true
  }

  // parse264 = () => {
  //   let ret = this.readOneFrame(this.videoFrame, this.gOffset)
  //   if(ret < 0){
  //     fs.closeSync(this.file)
  //     return
  //   }
  //   this.gOffset += ret
  //   this.sendH264Frame(this.videoFrame, this.spsFrame, this.ppsFrame)
  //   this.delayTime = this.nextSendTime - Date.now()
  //   if(this.delayTime < 0){
  //     this.delayTime = 0
  //   }
  //   this.nextSendTime = Date.now() + 1000 / this.fps
  //   if(this.running) {
  //     this.timeoutId = setTimeout(this.parse264, 33)
  //   }
  // }


  private sendH264Frame(videoframe: videoFrame, spsframe: spsFrame, ppsframe: ppsFrame){
    let encodedFrame: NERtcConstants.NERtcVideoEncodedFrame = new NERtcConstants.NERtcVideoEncodedFrame;
    encodedFrame.codecType = NERtcConstants.NERtcVideoCodecType.VIDEO_CODEC_TYPE_H264
    encodedFrame.width = this.width
    encodedFrame.height= this.height
    encodedFrame.timestampUs =  Date.now() * 1000;
    if(videoframe.frameType == FrameType.frameTypeKeyFrame){
      encodedFrame.frameType = NERtcConstants.NERtcNalFrameType.NAL_FRAME_TYPE_IDR
      encodedFrame.nalLengths = new Uint32Array([spsframe.size, ppsframe.size, videoframe.size])
      this.destBuffer.set(spsframe.data)
      this.destBuffer.set(ppsframe.data, spsframe.size)
      this.destBuffer.set(videoframe.bufferView, spsframe.size + ppsframe.size)
      encodedFrame.nalData = this.destBuffer
      let ret:number = NERtcSDK.getInstance().pushExternalVideoEncodedFrame(this.type, encodedFrame);
      console.info(this.TAG, 'PUSH I FRAME ret: ' + ret)
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        console.error(this.TAG, '=== push external encoded video frame error ====')
      }
    }else if(videoframe.frameType == FrameType.frameTypeNonKeyFrame){
      encodedFrame.frameType = NERtcConstants.NERtcNalFrameType.NAL_FRAME_TYPE_P
      encodedFrame.nalLengths = new Uint32Array([videoframe.size])
      encodedFrame.nalData = videoframe.bufferView
      let ret: number = NERtcSDK.getInstance().pushExternalVideoEncodedFrame(this.type, encodedFrame)
      console.info(this.TAG, 'PUSH P FRAME ret: ' + ret)
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        console.error(this.TAG, '=== push external encoded video frame error ===')
      }
    }else if(videoframe.frameType == FrameType.frameTypeSps){
      let partToCopy = videoframe.bufferView.subarray(0, videoframe.size);
      spsframe.data.set(partToCopy)
      spsframe.size = videoframe.size
    }else if(videoframe.frameType == FrameType.frameTypepps){
      let partToCopy = videoframe.bufferView.subarray(0, videoframe.size);
      ppsframe.data.set(partToCopy)
      ppsframe.size = videoframe.size
    }
  }

  private uint8ArrayToHexString(uint8Array: Uint8Array): string {
    return Array.from(uint8Array, (byte) => ('0' + byte.toString(16).toUpperCase()).slice(-2)).join(' ');
  }

  private readOneFrame(videoframe: videoFrame, offset_pre: number): number {
    let size = 0
    let offset = offset_pre
    if(fs.readSync(this.file?.fd, videoframe.data, { offset: offset, length: 5 }) < 5){
      console.log(this.TAG, "read start code error")
      return -1;
    }

    if((videoframe.bufferView[0] == 0x00 && videoframe.bufferView[1] == 0x00 && videoframe.bufferView[2] == 0x00 && videoframe.bufferView[3] == 0x01) ||
      (videoframe.bufferView[0] == 0x00 && videoframe.bufferView[1] == 0x00 && videoframe.bufferView[2] == 0x01)){
      let frameFlag = 0
      if(videoframe.bufferView[0] == 0x00 && videoframe.bufferView[1] == 0x00 && videoframe.bufferView[2] == 0x01){
        frameFlag = videoframe.bufferView[3] & 0x1F
      }else{
        frameFlag = videoframe.bufferView[4] & 0x1F
      }
      switch(frameFlag){
        case 5:
          videoframe.frameType = FrameType.frameTypeKeyFrame
          break
        case 7:
          videoframe.frameType = FrameType.frameTypeSps
          break
        case 8:
          videoframe.frameType = FrameType.frameTypepps
          break
        case 1:
          videoframe.frameType = FrameType.frameTypeNonKeyFrame
          break
        case 6:
          videoframe.frameType = FrameType.frameTypeSei
          break
      }
      size = 5 + size;
      offset = 5 + offset
      let buf = new ArrayBuffer(1);
      const array = new Uint8Array(4).fill(255);
      while(1){
        if(fs.readSync(this.file?.fd, buf, { offset: offset, length: 1 })){
          const dataView = new Uint8Array(buf);
          array[0] = array[1]
          array[1] = array[2]
          array[2] = array[3]
          array[3] = dataView[0]
          videoframe.bufferView[size] = dataView[0]
          size++;
          offset++;
          if((array[0] == 0x00 && array[1] == 0x00 && array[2] == 0x00 && array[3] == 0x01) ||
            (array[0] == 0x00 && array[1] == 0x00 && array[2] == 0x01)){
            size -= 4
            videoframe.size = size
            break;
          }
        }else{
          return -1;
        }
      }
    }
    return size
  }



}