import fs from '@ohos.file.fs'


export class AudioModel {

  //通用
  audioProfile: number = 0
  audioScenario: number = 0
  recordVolume: number = 100
  playoutVolume: number = 100
  autoOpenAudio: boolean = true
  autoSubAudio: boolean = true
  audioDumpType: number = 2
  enableFrameObserver: boolean = false;

  //伴音
  audioMixUrl: string = 'https://music.163.com/song/media/outer/url?id=65919.mp3' //URL
  audioMixPath: string = '' //本地文件路径
  audioMixIsSend: boolean = true //伴音本地是否发送
  audioMixIsPlay: boolean = true //伴音本地是否播放
  audioMixLoopNum: number = 1 //伴音循环次数
  audioMixMainSend: boolean = true //伴音是否跟随主流发送
  audioMixPitch: number = 0 //音调默认值为0, 取值范围[-12,12]

  //音效1
  audioEffect1Url: string = ''  //音效文件路径
  audioEffect1IsSend: boolean = true  //是否发送
  audioEffect1IsPlay: boolean = true  //是否播放
  audioEffect1LoopNum: number = 1     //循环次数
  audioEffect1Pitch: number = 0 //音调默认值为0, 取值范围[-12,12]

  //外部音频输入
  externalAudioInputUrl: string = '' //外部音频输入路径
  externalAudioInputSampleRate: number = 0 //外部音频输入采样率
  externalAudioInputChannelNum: number = 0 //外部音频输入声道数

  //外部辅流音频输入
  externalSubAudioInputUrl: string = '' //外部音频辅流音频路径
  externalSubAudioInputSampleRate: number = 0 //外部辅流音频输入采样率
  externalSubAudioInputChannelNum: number = 0 //外部辅流音频输入通道数

  //采集音量回调
  captureVolumeEnable: boolean = false
  captureVolumeIndicationDuration: number = 200 //采集音量回调间隔
  captureVolumeVAD: boolean = false //检测人声

  //音频回调参数设置
  audioCallbackChannel: number = 1
  audioCallbackSampleRate: number = 16000
  audioCallbackReadOnly: boolean = false
}

export class VideoModel {

  //通用
  fontCamera: boolean = true;
  encodeMode: number = 0
  decodeMode: number = 0
  scaleMode: number = 0  //fit
  publishStreamType: number = 1 //发布流类型 default: High
  enableFrameObserver: boolean = false;
  autoEnableVideo: boolean = true //自动开启视频
  autoSubVideo: boolean = true //自定订阅视频

  //主流
  mainCaptureWidth: number = 0
  mainCaptureHeight: number = 0
  mainSendResolution: number = 3  //720p
  mainEncodeFrameMode: number = 0
  mainEncodeFrameRate: number = 4 //30fps
  mainEnableDualStream: boolean = true
  mainCropMode: number = 0
  mainMirrorMode: number = 0

  //辅流
  subCaptureWidth: number = 0
  subCaptureHeight: number = 0
  subSendResolution: number = 3  //720p
  subEncodeFrameMode: number = 0
  subEncodeFrameRate: number = 4 //30fps
  subEnableDualStream: boolean = true
  subCropMode: number = 0
  subMirrorMode: number = 0

  //屏幕共享
  screenSendResolution: number = 2  //1080P
  screenMode: number = 0  //MOTION
  screenFrameRate: number = 3
  screenMinFrameRate: number = 0 //最小帧率
  screenBitRate = 0
  screenMinBitRate = 0

  //外部视频数据
  externalVideoType: number = 0
  externalVideoPath: string = ''
  externalVideoWidth: number = 0
  externalVideoHeight: number = 0
  externalVideoFrameRate: number = 0
  externalVideoRotation: number = 0

  //外部辅流视频数据
  externalSubVideoType: number = 0
  externalSubVideoPath: string = ''
  externalSubVideoWidth: number = 0
  externalSubVideoHeight: number = 0
  externalSubVideoFrameRate: number = 0
  externalSubVideoRotation: number = 0
}

export class OtherModel {

  //通用
  chatDetail: boolean = true
  upFallbackOption: number = 0
  downFallbackOption: number = 0
  channelProfile: number = 0

  //网络测速
  upLinkBitRate: number = 5000000 //本端期望的最高发送码率
  downLinkBitRate: number = 200000 //本端期望的最高接收码率
  upLinkProbe: boolean = false //是否探测上行网络
  downLinkProbe: boolean = false //是否探测下行网络

  //服务器录制
  recordSpeaker: boolean = true
  audioRecord: boolean = true
  videoRecord: boolean = true
  recordMode: number = 0
}

export class DumpModel {
  //视频 dump
  enableVideoDump: boolean = false //视频dump总开关
  enableDumpCapturedYUV: number = 0;
  maxSpaceForDumpCapturedYUVMB: number = 3;// 2GB
  dumpCapturedYUVInterval: number=  0; // ms
  enableDumpEncodeYUV: number = 0;
  maxSpaceForDumpEncodeYUVMB: number = 3;// 2GB
  dumpEncodeYUVInterval: number = 0; // ms
  enableDumpEncodedVideo: number = 0;
  maxSpaceForDumpEncodedVideoMB: number = 2; // 1GB
  enableDumpDecodeVideo: number = 0;
  maxSpaceForDumpDecodeVideoMB: number = 2; // 1GB
  enableDumpDecodedYUV: number = 0;
  maxSpaceForDumpDecodedYUVMB: number = 3; // 2GB
  dumpDecodedYUVInterval: number = 0; // ms
  enableDumpPostProcessedYUV: number = 0;
  maxSpaceForDumpPostProcessedYUVMB: number = 3; // 2GB
  dumpPostProcessedYUVInterval: number = 0; // ms
}

export class AudioEffectModel {

  //变声预设值
  voiceChangerEffectsEnable: boolean = false
  voiceChangerEffectsType: number = 0

  //预设的美声效果
  voiceBeautifierEffectsEnable: boolean = false
  voiceBeautifierEffectsType: number = 0

  //音调
  voicePitchEnable: boolean = false
  voicePitch: number = 1.0

  //设置本地语音混响效果
  voiceReverbEnable: boolean = false
  wetGain: number = 0.0
  dryGain: number = 1.0
  damping: number = 1.0
  roomSize: number = 0.1
  decayTime: number = 0.1
  preDelay: number = 0.0

  //设置本地语音音效均衡，即自定义设置本地人声均衡波段的中心频率。
  voiceEqualizationEnable: boolean = false
  band31: number = 0.0
  band62: number = 0.0
  band125: number = 0.0
  band250: number = 0.0
  band500: number = 0.0
  band1K: number = 0.0
  band2K: number = 0.0
  band4K: number = 0.0
  band8K: number = 0.0
  band16K: number = 0.0
}

export enum FUNC {
  TAKE,
  PUT,
  COPY
}

function checkValid(obj: any) : boolean {
  return obj && (obj !== 'object')
}

export function writeToParcel(src: any, dest: any) {
  if(checkValid(src) && checkValid(dest)) {
    for(const [key, value] of Object.entries(src)) {
      dest[key] = value
    }
  }
}


export const Operate =  (obj: any, func: FUNC, ...argArray: any[]): void => {
  switch (func) {
    case FUNC.TAKE:
      __take_parcel__.call(obj)
      break;
    case FUNC.PUT:
      __put_parcel__.call(obj, argArray[0])
      break;
    case FUNC.COPY:
      __copy_file__.call(obj, argArray[0], argArray[1])
      break;
  }
}

function __take_parcel__() {
  try {
    let audioData: AudioModel = JSON.parse(this.data.getSync('audioData', '') as string)
    writeToParcel(audioData, this.audioModel)

    let videoData: VideoModel = JSON.parse(this.data.getSync('videoData', '') as string)
    writeToParcel(videoData, this.videoModel)

    let otherData: OtherModel = JSON.parse(this.data.getSync('otherData', '') as string)
    writeToParcel(otherData, this.otherModel)

    let dumpData: OtherModel = JSON.parse(this.data.getSync('dumpData', '') as string)
    writeToParcel(dumpData, this.dumpModel)

    let audioEffectData: OtherModel = JSON.parse(this.data.getSync('audioEffectData', '') as string)
    writeToParcel(audioEffectData, this.audioEffectModel)
  } catch (e) {
    console.info(this.TAG, JSON.stringify(e))
  }
}

function __put_parcel__(success?: Function) {

  let audioData = JSON.stringify(this.audioModel)
  let videoData = JSON.stringify(this.videoModel)
  let otherData = JSON.stringify(this.otherModel)
  let dumpData = JSON.stringify(this.dumpModel)
  let audioEffectData = JSON.stringify(this.audioEffectModel)

  this.data?.putSync('audioData', audioData)
  this.data?.putSync('videoData', videoData)
  this.data?.putSync('otherData', otherData)
  this.data?.putSync('dumpData', dumpData)
  this.data?.putSync('audioEffectData', audioEffectData)

  this.data?.flush(() => {
    if(success) {
      success()
    }
  })
}

function __copy_file__(urlPath: string, baseDir: string) {

  let readStream: fs.Stream|null = null
  let writeStream: fs.Stream|null = null

  try {
    let splits = urlPath.split('/')
    let fileName = splits[splits.length - 1]
    console.info(this.TAG, 'fileName: ' + fileName)

    const destDir = baseDir + '/media'
    if(!fs.accessSync(destDir)) {
      fs.mkdirSync(destDir)
      console.info(this.TAG, ' === Dest dir mkdir === ')
    }

    const destFile = destDir + '/' + fileName
    if(fs.accessSync(destFile)) {
      console.info(this.TAG, 'file: ' + destFile + ', is already exists.')
      return
    }

    let file = fs.openSync(urlPath, fs.OpenMode.READ_ONLY)
    let stats = fs.statSync(file.fd)

    let buffer = new ArrayBuffer(stats.size)
    readStream = fs.fdopenStreamSync(file.fd, 'r')
    let size = readStream.readSync(buffer)

    if(size != stats.size) {
      console.info(this.TAG, `file:${urlPath} read error.`)
      return
    }

    let operateFile = fs.openSync(destFile, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
    writeStream = fs.fdopenStreamSync(operateFile.fd, 'w')
    let writenLen = writeStream.writeSync(buffer)
    if(writenLen != buffer.byteLength) {
      console.info(this.TAG, `file:${destFile} write error.`)
    }
  } catch (e) {
    console.error(this.TAG, 'copyToBundle error: ' + JSON.stringify(e))
  } finally {
    try {
      if(readStream) {
        readStream.closeSync()
      }
      if(writeStream) {
        writeStream.flushSync()
        writeStream.closeSync()
      }
    } catch (e) {
      console.info(this.TAG, 'close stream error: ' + JSON.stringify(e))
    }
  }

}


