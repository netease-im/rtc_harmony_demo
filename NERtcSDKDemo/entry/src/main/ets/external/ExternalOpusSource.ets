import { NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk/Index';
import fs from '@ohos.file.fs';
import * as common from '../model/common'

export default class ExternalOpusSource {

  private TAG: string = "ExternalOpusSource"
  private type: NERtcConstants.NERtcAudioStreamType
  private sampleRate: number
  private channels: number
  private running: boolean = false
  private intervalTaskId: number = -1
  private file : fs.File|null = null
  private lenBuffer?: ArrayBuffer
  private duration: number = 20
  private offset: number = 0
  private timeStampUs: number = 0
  private totalSampleCount: number = 0

  constructor(product: common.Product, type: NERtcConstants.NERtcAudioStreamType, path: string, sampleRate: number, channels: number)  {
    console.info(this.TAG, 'path: ' + path + ", type: " + type + ", sampleRate: " + sampleRate + ", channels: " + channels)
    this.type = type
    this.sampleRate = sampleRate
    this.channels = channels

    try {
      console.info(this.TAG, 'product: ' + product)
      let dir: string = getContext().filesDir + "/media"

      console.info(this.TAG, 'RESOUCE_PATH: ' + dir)
      path = dir + "/" + path

      if(!fs.accessSync(path)) {
        console.info(this.TAG, 'ACCESS file error.')
        return
      }
    } catch (e) {
      console.error(this.TAG, 'ACCESS file failed. message: ' + JSON.stringify(e))
      return
    }

    this.file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    this.lenBuffer = new ArrayBuffer(4)
  }

  start(): boolean {

    if(!this.file) {
      console.error(this.TAG, 'file read failed.')
      return false
    }
    console.info(this.TAG, 'file fd: ' + this.file.fd)

    if(this.running) {
      console.info(this.TAG, 'opus push already start.')
      return true
    }
    this.running = true

    this.intervalTaskId = setInterval(()=> {

      if(!this.running) {
        console.info(this.TAG, 'user stop push encode audio frame.')
        this.reset()
        return
      }

      let len = fs.readSync(this.file?.fd, this.lenBuffer, { offset: this.offset })
      if(len != 4) {
        this.reset()
        return
      }
      this.offset += len

      let view = new DataView(this.lenBuffer as ArrayBuffer)
      len = view.getInt32(0, false)

      let arrayBuffer = new ArrayBuffer(len)
      let read = fs.readSync(this.file?.fd, arrayBuffer, { offset: this.offset })
      if(read != len) {
        this.reset()
        return
      }
      this.offset += read

      let data: Uint8Array = new Uint8Array(arrayBuffer as ArrayBuffer)
      let samplePerChannel = this.sampleRate * this.duration / 1000
      let encodedFrame: NERtcConstants.NERtcAudioEncodedFrame = new NERtcConstants.NERtcAudioEncodedFrame()
      encodedFrame.data = data
      encodedFrame.timeStampUs = this.timeStampUs * 1000
      encodedFrame.sampleRate = this.sampleRate
      encodedFrame.channels = this.channels
      encodedFrame.samplesPerChannel = samplePerChannel
      encodedFrame.encodedLen = read
      encodedFrame.encodedTimestamp = this.totalSampleCount
      encodedFrame.payloadType = NERtcConstants.NERtcAudioPayLoadType.AUDIO_PAY_LOAD_TYPE_OPUS
      encodedFrame.rmsLevel = 100

      let ret: number = -1
      if(this.type == NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain) {
        ret = NERtcSDK.getInstance().pushExternalAudioEncodedFrame(encodedFrame)
      } else {
        ret = NERtcSDK.getInstance().pushExternalAudioSubStreamEncodedFrame(encodedFrame)
      }

      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        console.error(this.TAG, '==== PUSH AUDIO ENCODED FRAME ERROR ===')
      }

      this.timeStampUs += 20
      this.totalSampleCount += samplePerChannel
    }, this.duration)

    return true
  }

  stop(): boolean {
    console.info(this.TAG, 'USER Stop push external encoded audio frame.')
    this.running = false
    this.reset()
    if (this.file) {
      fs.closeSync(this.file)
    }
    this.file = null
    return true
  }

  private reset() {
    this.totalSampleCount = 0
    this.timeStampUs = 0
    this.offset = 0
    clearInterval(this.intervalTaskId)
    this.intervalTaskId = -1
  }

}