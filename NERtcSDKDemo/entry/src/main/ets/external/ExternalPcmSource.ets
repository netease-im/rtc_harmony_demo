import { NERtcConstants } from '@nertc/nertc_sdk/Index';
import fs from '@ohos.file.fs';
import prompt from '@ohos.promptAction';
import { NERtcSDK } from '@nertc/nertc_sdk';
import * as common from '../model/common'

const CUSTOM_AUDIO_TIME_DURATION: number = 20
export class ExternalPcmSource {

  private TAG: string = "ExternalPCMAudioSource"
  private type?: NERtcConstants.NERtcAudioStreamType
  private sampleRate: number
  private channels: number
  private file : fs.File|null = null;
  private bufferLength?: number;
  private arrayBuffer?: ArrayBuffer
  private running: boolean = false
  private intervalTaskId: number = -1
  private fileReadOffset: number = 0;

  constructor(product: common.Product, type: NERtcConstants.NERtcAudioStreamType, path: string, sampleRate: number, channels: number) {
    console.info(this.TAG, "path: " + path + ", sampleRate: " + sampleRate + ", channels: " + channels)
    this.type = type
    this.sampleRate = sampleRate
    this.channels = channels

    try {
      console.info(this.TAG, 'product: ' + product)
      let dir: string = getContext().filesDir + "/media"

      console.info(this.TAG, 'RESOUCE_PATH: ' + dir)
      path = dir + "/" + path
      let res = fs.accessSync(path)
      console.info(this.TAG, 'access file ret: ' + res)
      if(!res) return
    } catch (e) {
      console.error(this.TAG, 'asscess file failed. message: ' + JSON.stringify(e))
      return
    }

    this.file = fs.openSync(path, fs.OpenMode.READ_ONLY)
    this.bufferLength = this.sampleRate * this.channels * CUSTOM_AUDIO_TIME_DURATION * 2 /1000
    this.arrayBuffer = new ArrayBuffer(this.bufferLength)
    console.info(this.TAG, 'bufferLength: ' + this.bufferLength)
  }

  start(): boolean {

    if(!this.file) {
      prompt.showToast({ message: '文件读取异常' })
      return false
    }
    console.info(this.TAG, 'file fd: ' + this.file.fd)

    if(this.running) {
      console.info(this.TAG, 'already start.')
      return false
    }
    this.running = true

    this.intervalTaskId = setInterval(() => {

      if(!this.file) {
        console.info(this.TAG, 'file is undefined.')
        return
      }

      if(!this.running) {
        console.info(this.TAG, 'User stop push external audio frame.')
        return
      }

      try {
        let readLen = fs.readSync(this.file.fd, this.arrayBuffer, { offset: this.fileReadOffset })
        if(readLen != this.bufferLength) {
          this.fileReadOffset = 0
          console.warn(this.TAG, 'read file to end, loop again, read length: ' + readLen)
          return
        }

        this.fileReadOffset += readLen
        let data: Uint8Array = new Uint8Array(this.arrayBuffer as ArrayBufferLike)
        let audioFrame: NERtcConstants.NERtcAudioFrame = new NERtcConstants.NERtcAudioFrame();
        audioFrame.data = data;
        audioFrame.format = new NERtcConstants.NERtcAudioFormat();
        audioFrame.format.sampleRate = this.sampleRate;
        audioFrame.format.numberOfChannel = this.channels;
        audioFrame.format.bytesPerSample = 2;
        audioFrame.format.samplesPerChannel = this.sampleRate * CUSTOM_AUDIO_TIME_DURATION / 1000;

        let ret: number = 0
        if(this.type == NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain) {
          ret = NERtcSDK.getInstance().pushExternalAudioFrame(audioFrame)
        } else {
          ret = NERtcSDK.getInstance().pushExternalSubStreamAudioFrame(audioFrame)
        }
        if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
          console.error(this.TAG, 'push external audio frame error. ret: ' + ret)
        }
      } catch (e) {
        console.error(this.TAG, 'push external audio frame error: ' + JSON.stringify(e))
      }
    }, CUSTOM_AUDIO_TIME_DURATION)
    return true
  }

  stop(): boolean {
    console.info(this.TAG, 'User stop push external audio frame.')
    this.running = false
    clearInterval(this.intervalTaskId)
    if (this.file) {
      fs.close(this.file)
    }
    this.file = null
    return true
  }

}