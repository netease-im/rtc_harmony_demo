import fs from '@ohos.file.fs';

import { NERtcConstants } from '@nertc/nertc_sdk';
import prompt from '@ohos.promptAction';
import { NERtcSDK } from '@nertc/nertc_sdk';
import * as common from '../model/common'

export class ExternalYuvVideoSource {

  private TAG: string = "ExternalYuvVideoSource"
  private type: NERtcConstants.NERtcVideoStreamType
  private fps: number
  private rotation: NERtcConstants.NERtcVideoFrameRotation
  private width: number
  private height: number
  private file?: fs.File;
  private bufferLength?: number;
  private arrayBuffer?: ArrayBuffer
  private running: boolean = false
  private intervalTaskId: number = -1
  private fileReadOffset: number = 0;

  constructor(product: common.Product, type: NERtcConstants.NERtcVideoStreamType, path: string, width: number, height: number, fps: number, rotation: NERtcConstants.NERtcVideoFrameRotation) {
    this.type = type
    this.fps = fps
    this.rotation = rotation
    this.width = width
    this.height = height
    console.info(this.TAG, 'type: ' + type + ", path: " + path + ", width: " + width + ", height: " + height + ", fps: " + fps + ", rotation: " + rotation)

    try {
      let dir: string = getContext().filesDir + "/media"

      console.info(this.TAG, 'RESOURCE_PATH: ' + dir)
      path = dir + "/" + path
      let res = fs.accessSync(path)
      console.info(this.TAG, 'asscess file ret: ' + res)
      if(!res) return
    } catch (err) {
      console.error(this.TAG, 'access file failed, message: ' + err.message + ", code: " + err.code)
      return
    }

    this.file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    this.bufferLength = width * height * 3 / 2
    this.arrayBuffer = new ArrayBuffer(this.bufferLength)
  }

  start(): boolean {

    if(!this.file) {
      prompt.showToast({ message: "文件读取异常" })
      return false
    }
    console.info(this.TAG, 'file fd: ' + this.file.fd)

    if(this.running) {
      console.info(this.TAG, 'already start.')
      return true
    }
    this.running = true

    let pushIntervalMs = 1000 / this.fps
    let transformMatrixArray: Float32Array = new Float32Array([0])
    this.intervalTaskId = setInterval(() => {

      if(!this.file) {
        console.info(this.TAG, 'file is undefined.')
        return
      }

      if(!this.running) {
        console.info(this.TAG, 'User stop push external video frame.')
        return
      }

      try {
          let readLen = fs.readSync(this.file.fd, this.arrayBuffer, { offset: this.fileReadOffset })
          if(readLen != this.bufferLength) {
            this.fileReadOffset = 0
            console.warn(this.TAG, 'read file to end, loop again. read length: ' + readLen)
            return
          }

          this.fileReadOffset += readLen
          let data: Uint8Array = new Uint8Array(this.arrayBuffer as ArrayBufferLike)
          let rotation: number = this.rotation ? this.rotation : NERtcConstants.NERtcVideoFrameRotation.kLiteSDKVideoFrameRotationType0
          let videoFrame: NERtcConstants.NERtcVideoFrame = {
            width: this.width,
            height: this.height,
            rotation: rotation,
            format: NERtcConstants.NERtcVideoFormat.I420,
            timeStamp: BigInt(0),
            data: data,
            strideY: 0,
            strideU: 0,
            strideV: 0,
            textureId: 0,
            transformMatrix: transformMatrixArray
          }

          if(NERtcSDK.getInstance().pushExternalVideoFrame(videoFrame, this.type) != NERtcConstants.ErrorCode.NO_ERROR){
            console.error(this.TAG, 'push external video frame error.')
          }
      } catch (e) {
        console.error(this.TAG, 'push external video frame error: ' + JSON.stringify(e))
      }
    }, pushIntervalMs)
    return true
  }

  stop(): boolean {
    console.info(this.TAG, 'User stop push external video frame.')
    this.running = false
    clearInterval(this.intervalTaskId)
    return true
  }

}