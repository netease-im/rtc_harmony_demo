import { NERtcConstants, NERtcSDK, NERtcCallbackEx} from '@nertc/nertc_sdk/Index';

import { NERtcPacketObserver} from '@nertc/nertc_sdk';
import Config from '../../common/Config';
import DemoUser from '../../model/DemoUser';
import { ChatState, DemoLogicMap, LocalVolumeInfo, LoginInfo } from './ChatModel';
import UIDelegate, { OPERATOR } from './Delegate';
import ExternalOpusSource from '../../external/ExternalOpusSource';
import { Product } from '../../model/common'
import PushExternalH264Video from '../../external/ExternalH264Source1';
import fs from '@ohos.file.fs';
import { RtcDemoAudioFrameObserver, RtcDemoVideoFrameObserver } from '../../common/RtcDemoCallback';
import { preferences } from '@kit.ArkData';
import Prompt from '@system.prompt';
import image from '@ohos.multimedia.image'
import { systemDateTime } from '@kit.BasicServicesKit';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';
import avSession from '@ohos.multimedia.avsession';
import { BusinessError } from '@ohos.base';
import { ExternalPcmSource } from '../../external/ExternalPcmSource';
import { ExternalYuvVideoSource } from '../../external/ExternalYuvVideoSource';
import { DemoNERtcPackageObserver } from './PackageObserver';
import { DemoNERtcPreDecodeObserver } from './PreDecodeObserver';
import { VideoModel, OtherModel, AudioModel, DumpModel, AudioEffectModel } from '../settings/model/common';

let state_: ChatState = ChatState.CHAT_IDLE
let TAG: string = 'MultiChat'
let delegates_: Array<UIDelegate> = []
let login_: LoginInfo;

export let gAudioModel: AudioModel
export let gVideoModel: VideoModel
export let gOtherModel: OtherModel
export let gDumpModel: DumpModel
export let gAudioEffectModel: AudioEffectModel

export default class ChatPresenter extends NERtcCallbackEx {

  private static instance: ChatPresenter = new ChatPresenter()
  private audioEncodedSource?: ExternalOpusSource
  private audioSubEncodedSource?: ExternalOpusSource

  //外部主流码流
  private videoEncodedSource?: PushExternalH264Video
  //外部辅流码流
  private videoSubEncodedSource?: PushExternalH264Video

  private preObserver?: DemoNERtcPreDecodeObserver|null
  private dir?: string
  private localUser: DemoUser|null = null
  private av_session: avSession.AVSession|null = null;

  //主流外部输入
  private externalAudioSourceMain: ExternalPcmSource|null = null
  private externalVideoSourceMain: ExternalYuvVideoSource| null = null

  //辅流外部输入
  private externalAudioSourceSub: ExternalPcmSource|null = null
  private externalVideoSourceSub: ExternalYuvVideoSource| null = null

  private audioFrameObserver: RtcDemoAudioFrameObserver = new RtcDemoAudioFrameObserver(TAG);
  private isAudioFrameObserverEnabled: boolean = false;
  private videoFrameObserver: RtcDemoVideoFrameObserver = new RtcDemoVideoFrameObserver(TAG);
  private isVideoFrameObserverEnabled: boolean = false;

  onJoinChannel(result: number, channelId: bigint, elapsed: bigint, uid: bigint): void {
    state_ = result == NERtcConstants.ErrorCode.NO_ERROR ? ChatState.CHAT_ED : ChatState.CHAT_IDLE;
    if (state_ == ChatState.CHAT_ED) {
      delegates_?.forEach(delegate_ => {
        if (!this.localUser) {
          this.localUser = new DemoUser(uid, true);
        }
        delegate_?.update(OPERATOR.ADD, this.localUser);
      });
      setTimeout(() => {
        if (gAudioModel) {
          let ret: number = NERtcSDK.getInstance().enableLocalAudio(gAudioModel.autoOpenAudio);
          console.info(TAG, 'EnableLocalAudio: ' + ret);
        }
        if (gVideoModel) {
          this.enableVideo(gVideoModel.autoEnableVideo);
        }
        this.enableSpeakerOn(true);
      });
    } else {
      delegates_?.forEach(delegate_ => {
        delegate_?.error('Join channel failed, result:' + result);
      });
    }
  }

  onLeaveChannel(result: number): void {
    state_ = ChatState.CHAT_IDLE;
    delegates_.forEach(delegate_ => {
      if (this.localUser) {
        delegate_?.update(OPERATOR.DEL, this.localUser);
      }
    });
  }

  onUserJoined(uid: bigint, extraInfo?: NERtcConstants.NERtcUserJoinExtraInfo | undefined): void {
    delegates_?.forEach(delegate_ => {
      let user = new DemoUser(uid);
      delegate_?.update(OPERATOR.ADD, user);
    });
  }

  onUserLeave(uid: bigint, reason: number, extraInfo?: NERtcConstants.NERtcUserLeaveExtraInfo | undefined): void {
    delegates_?.forEach(delegate_ => {
      let user = new DemoUser(uid);
      delegate_?.update(OPERATOR.DEL, user);
    });
  }

  onUserAudioStart(uid: bigint): void {}

  onUserAudioStop(uid: bigint): void {}

  onUserVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {}

  onUserVideoStop(uid: bigint): void {}

  onDisconnect(reason: number): void {}

  onClientRoleChange(oldRole: number, newRole: number): void {}

  onRecvSEIMsg(userId: bigint, data: Uint8Array, dataSize: number): void {}

  onFirstAudioFrameDecoded(uid: bigint): void {
    Prompt.showToast({
      message: `onFirstAudioFrameDecoded, uid:${uid}`
    });
  }

  onFirstVideoFrameDecoded(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number): void {
    Prompt.showToast({
      message: `onFirstVideoFrameDecoded, streamType:${streamType}, uid:${userId}, width:${width}, height:${height}`
    });
  }

  onUserSubStreamVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {
    delegates_?.forEach(delegate_ => {
      let canvasId = DemoUser.GeneratorSubCanvasId(uid);
      let obj: Map<string, Object | undefined> = new Map;
      obj.set('uid', uid);
      obj.set('xComponentIdSub', canvasId);
      delegate_?.update(OPERATOR.UPD, obj);
    });
  }

  onUserSubStreamVideoStop(uid: bigint): void {
    delegates_?.forEach(delegate_ => {
      let obj: DemoLogicMap = new Map;
      obj.set('uid', uid);
      obj.set('xComponentIdSub', undefined);
      delegate_?.update(OPERATOR.UPD, obj);
    });
  }

  onLocalAudioVolumeIndication(volume: number, vadFlag: boolean): void {
    delegates_?.forEach(delegate_ => {
      if (delegate_.localVolume) {
        delegate_.localVolume({
          volume: volume, vad: vadFlag
        });
      }
    });
  }

  onRemoteAudioVolumeIndication(volumeInfo: NERtcConstants.NERtcAudioVolumeInfo[], totalVolume: number): void {
    delegates_?.forEach(delegate_ => {
      if (delegate_.remoteVolume) {
        delegate_.remoteVolume(volumeInfo, totalVolume);
      }
    });
  }

  onLastmileProbeResult(result: NERtcConstants.NERtcProbeResult): void {
    delegates_?.forEach(delegate_ => {
      if(delegate_.networkQuality) {
        delegate_.networkQuality(null, result)
      }
    })
  }
  onLabFeatureCallback(key: string, param: Object): void {
  }
  onLastmileQuality(quality: number): void {
    delegates_?.forEach(delegate_ => {
      if(delegate_.networkQuality) {
        delegate_.networkQuality(quality, null)
      }
    })
  }

  onVirtualBackgroundSourceEnabled(enabled: boolean, reason: number): void {
    console.info(TAG, `onVirtualBackgroundSourceEnabled, enabled:${enabled}, reason:${reason}`);
    Prompt.showToast({
      message: `onVirtualBackgroundSourceEnabled, enabled:${enabled}, reason:${reason}` , duration: 3000
    });
  }

  static getInstance(): ChatPresenter {
    return ChatPresenter.instance
  }

  setDir(dir: string) {
    this.dir = dir
    console.info(TAG, 'Set Dir: ' + dir)
  }

  setDelegate(delegate: UIDelegate) {

    if(delegates_.indexOf(delegate) !== -1) {
      console.info(TAG, 'delegate is exits.')
    } else {
      delegates_?.push(delegate)
      console.info(TAG, 'setDelegate size: ' + delegates_.length)
    }
  }

  removeDelegate(delegate: UIDelegate) {

    let index = delegates_.indexOf(delegate)
    if(index !== -1) {
      delegates_.splice(index, 1)
    } else {
      console.info(TAG, 'delegate not found.')
    }
  }

  enableBackgroundRunning(enable:boolean): void {
    if (enable) {
      this.createAVSession();
      this.startBackgroundRunning();
    } else {
      this.stopBackgroundRunning();
      this.destroyAVSession();
    }
  }

  resetParams(context: Context): void {
    this.loadModel(context)
    this.before()
    this.after()
    this.extend()
  }

  createAVSession(): void {
    avSession.createAVSession(getContext(this), TAG, "video").then((session: avSession.AVSession) => {
      console.info(TAG, "createAVSession succeed");
      this.av_session = session;
    }).catch((err: BusinessError) => {
      console.error(TAG, `createAVSession failed, code:${err.code}, message:${err.message}`);
    })
  }

  destroyAVSession(): void {
    this.av_session?.deactivate().then(() => {
      this.av_session?.destroy().then(() => {
        this.av_session = null;
      }).catch((err: BusinessError) => {
        console.error(TAG, `destroy avSession failed, code:${err.code}, message:${err.message}`);
      });
    }).catch((err: BusinessError) => {
      console.error(TAG, `deactivate avSession failed, code:${err.code}, message:${err.message}`);
    });
  }

  startBackgroundRunning(): void {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: "com.netease.rtcdemo",
          abilityName: "EntryAbility"
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
      let backgroundModes: string[] = ["audioRecording", "audioPlayback"];
      backgroundTaskManager.startBackgroundRunning(getContext(this), backgroundModes, wantAgentObj).then((taskNotification: backgroundTaskManager.ContinuousTaskNotification) => {
        console.info(TAG, `startBackgroundRunning succeed`);
      }).catch((err: BusinessError) => {
        console.error(TAG, `startBackgroundRunning failed, code:${err.code}, message:${err.message}`);
      });
    });
  }

  stopBackgroundRunning(): void {
    backgroundTaskManager.stopBackgroundRunning(getContext(this)).then(() => {
      console.info(TAG, `stopBackgroundRunning succeed`);
    }).catch((err: BusinessError) => {
      console.error(TAG, `stopBackgroundRunning failed, code:${err.code}, message:${err.message}`);
    });
  }

  init(context: Context) {
    this.loadModel(context)

    this.before()
    let option: NERtcConstants.NERtcOption = { logLevel: NERtcConstants.LogLevel.INFO }
    NERtcSDK.getInstance().init(context, Config.APP_KEY_DEBUG, this, option)
    this.after()
  }

  private loadModel(context: Context) {
    let options: preferences.Options = { name: 'netease_settings' }
    let data = preferences.getPreferencesSync(context, options)

    let localAudioData = data.getSync('audioData', '') as string
    let localVideoData = data.getSync('videoData', '') as string
    let localOtherData = data.getSync('otherData', '') as string
    let localDumpData = data.getSync('dumpData', '') as string
    let localAudioEffectData = data.getSync('audioEffectData', '') as string

    try {
      gAudioModel = JSON.parse(localAudioData)
      gVideoModel = JSON.parse(localVideoData)
      gOtherModel = JSON.parse(localOtherData)
      gDumpModel = JSON.parse(localDumpData)
      gAudioEffectModel = JSON.parse(localAudioEffectData)
    } catch (e) {
      console.info(TAG, JSON.stringify(e))
      gAudioModel = new AudioModel()
      gVideoModel = new VideoModel()
      gOtherModel = new OtherModel()
      gDumpModel = new DumpModel()
      gAudioEffectModel = new AudioEffectModel()
    }
  }
  triggerCaptionMode(captionMode: boolean) {
    let param: object = new Object();
    param["sdk.enable.asr.caption"] = captionMode
    param["sdk.asr.caption.src.language"] = gOtherModel.captionSource
    param["sdk.asr.caption.dst.language"] = gOtherModel.captionDest
    NERtcSDK.getInstance().setParameters(param)

    param["sdk.private.api.request.asr.caption"] = ''
    NERtcSDK.getInstance().setParameters(param)
  }
  private before = (): void => {
    let param: object = new Object();
    //设置SDK日志是否加密，调试阶段关闭，上线阶段打开
    param["sdk.enable.encrypt.log"] = false;
    if(gAudioModel) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyAutoSubscribeAudio] = gAudioModel.autoSubAudio
    }
    if(gVideoModel) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyStartVideoWithBackCamera] = !gVideoModel.fontCamera

      if(gVideoModel.encodeMode == 0 || gVideoModel.encodeMode == 1) {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoEncodeMode] = 0
      } else {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoEncodeMode] = 1
      }

      if(gVideoModel.decodeMode == 0 || gVideoModel.decodeMode == 1) {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoDecodeMode] = 0
      } else {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoDecodeMode] = 1
      }

      param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoSendMode] = gVideoModel.publishStreamType
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyAutoSubscribeVideo] = gVideoModel.autoSubVideo
    }

    if(gOtherModel) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordSpeaker] = gOtherModel.recordSpeaker
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordAudio] = gOtherModel.audioRecord
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordVideo] = gOtherModel.videoRecord
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordMode] = gOtherModel.recordMode
    }
    if(gOtherModel.captionMode) {
      param["sdk.enable.asr.caption"] = gOtherModel.captionMode
      param["sdk.asr.caption.src.language"] = gOtherModel.captionSource
      param["sdk.asr.caption.dst.language"] = gOtherModel.captionDest
    }
    NERtcSDK.getInstance().setParameters(param)
  }

  private after = (): void => {
    // setTimeout(() => { // 临时的bug，后面去掉
      if(gAudioModel) {
        NERtcSDK.getInstance().setAudioProfile(gAudioModel.audioProfile, gAudioModel.audioScenario)
        NERtcSDK.getInstance().adjustRecordingSignalVolume(gAudioModel.recordVolume)
        NERtcSDK.getInstance().adjustPlaybackSignalVolume(gAudioModel.playoutVolume)
        // 回调
        if (this.isAudioFrameObserverEnabled != gAudioModel.enableFrameObserver) {
          this.isAudioFrameObserverEnabled = gAudioModel.enableFrameObserver;
          this.enableAudioFrameObserver(gAudioModel.enableFrameObserver);
        }
      }

      if(gVideoModel) {
        //是否开启小流
        NERtcSDK.getInstance().enableDualStreamMode(gVideoModel.mainEnableDualStream)

        //主流设置
        let configMain: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
        configMain.maxProfile = gVideoModel.mainSendResolution
        configMain.degradationPreference = gVideoModel.mainEncodeFrameMode
        configMain.framerate = this.translateFrameRate(gVideoModel.mainEncodeFrameRate)
        configMain.cropMode = gVideoModel.mainCropMode
        configMain.mirrorMode = gVideoModel.mainMirrorMode

        let ret: number = NERtcSDK.getInstance().setLocalVideoConfig(configMain, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
        console.info(TAG, `set main localVideoConfig ret:${ret}, config:${JSON.stringify(configMain)}`)

        //设置主流capture.
        {
          let captureWidth = gVideoModel.mainCaptureWidth
          let captureHeight = gVideoModel.mainCaptureHeight

          if(captureWidth != 0 && captureHeight != 0) {
            NERtcSDK.getInstance().setCameraCaptureConfig({ width: captureWidth, height: captureHeight},
              NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
          }
        }

        //辅流设置
        let configSub: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
        configSub.maxProfile = gVideoModel.subSendResolution
        configSub.degradationPreference = gVideoModel.subEncodeFrameMode
        configSub.framerate = this.translateFrameRate(gVideoModel.subEncodeFrameRate)
        configSub.cropMode = gVideoModel.subCropMode
        configSub.mirrorMode = gVideoModel.subMirrorMode
        ret = NERtcSDK.getInstance().setLocalVideoConfig(configSub, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
        console.info(TAG, `set sub localVideoConfig ret:${ret}, config:${JSON.stringify(configSub)}`)

        //设置辅流capture.
        {
          let captureWidth = gVideoModel.subCaptureWidth
          let captureHeight = gVideoModel.subCaptureHeight

          if(captureWidth != 0 && captureHeight != 0) {
            NERtcSDK.getInstance().setCameraCaptureConfig({width: captureWidth, height: captureHeight},
              NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
          }
        }

        // 回调
        if (this.isVideoFrameObserverEnabled != gVideoModel.enableFrameObserver) {
          this.isVideoFrameObserverEnabled = gVideoModel.enableFrameObserver;
          this.enableVideoFrameObserver(gVideoModel.enableFrameObserver);
        }
      }

      if (gDumpModel && gDumpModel.enableVideoDump) {
        let param: object = new Object();
        if (gDumpModel.enableDumpCapturedYUV) {
          param["engine.video.video_dump_captured_yuv_mode"] = gDumpModel.enableDumpCapturedYUV;
          param["engine.video.video_dump_captured_yuv_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpCapturedYUVMB);
          param["engine.video.video_dump_captured_yuv_interval"] = this.translateVideoDumpInterval(gDumpModel.dumpCapturedYUVInterval);
        }
        if (gDumpModel.enableDumpEncodeYUV) {
          param["engine.video.video_dump_encode_yuv_mode"] = gDumpModel.enableDumpEncodeYUV;
          param["engine.video.video_dump_encode_yuv_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpEncodeYUVMB);
          param["engine.video.video_dump_encode_yuv_interval"] = this.translateVideoDumpInterval(gDumpModel.dumpEncodeYUVInterval);
        }
        if (gDumpModel.enableDumpEncodedVideo) {
          param["engine.video.video_dump_encode_video_mode"] = gDumpModel.enableDumpEncodedVideo;
          param["engine.video.video_dump_encode_video_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpEncodedVideoMB);
        }
        //接收
        if (gDumpModel.enableDumpDecodeVideo) {
          param["engine.video.video_dump_decode_video_mode"] = gDumpModel.enableDumpDecodeVideo;
          param["engine.video.video_dump_decode_video_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpDecodeVideoMB);
        }
        if (gDumpModel.enableDumpDecodedYUV) {
          param["engine.video.video_dump_decode_yuv_mode"] = gDumpModel.enableDumpDecodedYUV;
          param["engine.video.video_dump_decode_yuv_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpDecodedYUVMB);
          param["engine.video.video_dump_decode_yuv_interval"] = this.translateVideoDumpInterval(gDumpModel.dumpDecodedYUVInterval);
        }
        if (gDumpModel.enableDumpPostProcessedYUV) {
          param["engine.video.video_dump_post_process_yuv_mode"] = gDumpModel.enableDumpPostProcessedYUV;
          param["engine.video.video_dump_post_process_yuv_space"] = this.translateVideoDumpSpaceMB(gDumpModel.maxSpaceForDumpPostProcessedYUVMB);
          param["engine.video.video_dump_post_process_yuv_interval"] = this.translateVideoDumpInterval(gDumpModel.dumpPostProcessedYUVInterval);
        }

        NERtcSDK.getInstance().setParameters(param)
      }

      // other settings.
      if(gOtherModel) {
        let channelProfile = gOtherModel.channelProfile
        let ret: number = NERtcSDK.getInstance().setChannelProfile(channelProfile)
        console.info(TAG, `setChannelProfile: ${ret}`)
      }

    // }, 1000)
  }

  private extend = (): void => {
    if(gAudioModel) {
      //实时音量回调
      this.realTimeVolumeEnable(gAudioModel.captureVolumeEnable)
    }

    this.enableVoiceEffectIfNeeded()
    this.enableVirtualBackgroundIfNeeded()
  }

  private enableVirtualBackgroundIfNeeded()  : void {
    //是否打开
    let backData = new NERtcConstants.NERtcVirtualBackgroundSource()
    if (gVideoModel.virtualBackgroundEnable) {
      backData.backgroundSourceType = gVideoModel.virtualBackgroundType
      backData.color = gVideoModel.virtualBackgroundColor
      backData.blur_degree = gVideoModel.virtualBackgroundBlurDegree

      if (gVideoModel.virtualBackgroundSourceIndex == 0) {
        if(gVideoModel.virtualBackgroundSource && gVideoModel.virtualBackgroundSource.length > 0) {
          const splits = gVideoModel.virtualBackgroundSource.split('/')
          const fileName = splits[splits.length - 1]
          const lastPath = getContext().filesDir + "/media/" + fileName
          backData.source = lastPath
        }
      }
      else {
        let mediaDir = getContext(this).filesDir + "/media";
        let imageFilePath = mediaDir + "/" + "image_vb_sample_" + (gVideoModel.virtualBackgroundSourceIndex-1) + ".jpg";
        if (fs.accessSync(imageFilePath)) {
          backData.source = imageFilePath
        }
      }

      NERtcSDK.getInstance().enableVirtualBackground(true, backData)
    }
    else {
      NERtcSDK.getInstance().enableVirtualBackground(false, backData)
    }
  }

  private enableVoiceEffectIfNeeded() : void {
    if (gAudioEffectModel) {
      if (gAudioEffectModel.voiceChangerEffectsEnable) {
        NERtcSDK.getInstance().setAudioEffectPreset(gAudioEffectModel.voiceChangerEffectsType)
      }

      if (gAudioEffectModel.voiceBeautifierEffectsEnable) {
        NERtcSDK.getInstance().setVoiceBeautifierPreset(gAudioEffectModel.voiceBeautifierEffectsType)
      }

      if (gAudioEffectModel.voicePitchEnable) {
        NERtcSDK.getInstance().setLocalVoicePitch(gAudioEffectModel.voicePitch)
      }

      if (gAudioEffectModel.voiceReverbEnable) {
        let param: NERtcConstants.NERtcReverbParam = new NERtcConstants.NERtcReverbParam
        param.wetGain = gAudioEffectModel.wetGain
        param.dryGain = gAudioEffectModel.dryGain
        param.damping = gAudioEffectModel.damping
        param.roomSize = gAudioEffectModel.roomSize
        param.decayTime = gAudioEffectModel.decayTime
        param.preDelay = gAudioEffectModel.preDelay
        NERtcSDK.getInstance().setLocalVoiceReverbParam(param)
      }

      if (gAudioEffectModel.voiceEqualizationEnable) {
        NERtcSDK.getInstance().setLocalVoiceEqualization(0, gAudioEffectModel.band31)
        NERtcSDK.getInstance().setLocalVoiceEqualization(1, gAudioEffectModel.band62)
        NERtcSDK.getInstance().setLocalVoiceEqualization(2, gAudioEffectModel.band125)
        NERtcSDK.getInstance().setLocalVoiceEqualization(3, gAudioEffectModel.band250)
        NERtcSDK.getInstance().setLocalVoiceEqualization(4, gAudioEffectModel.band500)
        NERtcSDK.getInstance().setLocalVoiceEqualization(5, gAudioEffectModel.band1K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(6, gAudioEffectModel.band2K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(7, gAudioEffectModel.band4K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(8, gAudioEffectModel.band8K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(9, gAudioEffectModel.band16K)
      }
    }
  }

  private translateVideoDumpSpaceMB(index: number): number {
      let space: number
      switch(index) {
        case 0:
          space = 256
          break;
        case 1:
          space = 512
          break;
        case 2:
          space = 1024
          break;
        case 3:
          space = 2048
          break;
        case 4:
          space = 4096
          break;
        default:
          space = 1024
          break;
      }

      return space
  }

  private translateVideoDumpInterval(index: number): number {
    let interval: number
    switch(index) {
      case 0:
        interval = 10
        break;
      case 1:
        interval = 500
        break;
      case 2:
        interval = 1000
        break;
      case 3:
        interval = 2000
        break;
      default:
        interval = 10
        break;
    }
    return interval
  }

  private translateFrameRate(index: number): NERtcConstants.NERtcVideoFrameRate {
    let frameRate: NERtcConstants.NERtcVideoFrameRate
    switch(index) {
      case 0:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps7
        break;
      case 1:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps10
        break;
      case 2:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps15
        break;
      case 3:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps24
        break;
      case 4:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps30
        break;
      case 5:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFpsDefault
        break;
      default:
        frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps24
        break;
    }
    return frameRate
  }

  checkPermission(): boolean {
    let list: string[]|null = NERtcSDK.getInstance().checkPermission()
    if(!list) {
      Prompt.showToast({ message : '未能成功检查权限' })
      return false
    }
    if(list.length > 0) {
      Prompt.showToast({ message: `缺失权限列表: ${JSON.stringify(list)}`})
      return false
    }
    Prompt.showToast({ message: '权限无缺失'})
    return true
  }

  clearCache(): void {
    let options: preferences.Options = { name: 'netease_settings' }
    let data = preferences.getPreferencesSync(getContext(), options)
    data.clearSync()
    Prompt.showToast({ message: '缓存清理成功' })
  }

  /**
   * 获取画布角度
   * @returns
   */
  GetCanvasBorderRadius(): number {
    return gOtherModel.canvasBorderRadius ?? 0
  }

  join(login: LoginInfo): number {
    try {
      if(gOtherModel && gOtherModel.chatDetail) {
        NERtcSDK.getInstance().setStatsObserver({
          onRtcStats:(stats: NERtcConstants.NERtcStats): void =>{
            let detailInfo = JSON.stringify(stats, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onRtcStats: ${detailInfo}`)
            delegates_?.forEach(delegate_ => {
              if(delegate_?.detail) {
                delegate_?.detail(detailInfo)
              }
            });
          },

          onLocalAudioStats: (stats: NERtcConstants.NERtcAudioSendStats):void =>{
            let detailInfo = JSON.stringify(stats, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onLocalAudioStats: ${detailInfo}`)
          },

          onRemoteAudioStats: (statsArray: Array<NERtcConstants.NERtcAudioRecvStats>): void => {
            let detailInfo = JSON.stringify(statsArray, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onRemoteAudioStats: ${detailInfo}`)
          },

          onLocalVideoStats: (stats: NERtcConstants.NERtcVideoSendStats):void =>{
            let detailInfo = JSON.stringify(stats, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onLocalVideoStats: ${detailInfo}`)
          },

          onRemoteVideoStats: (statsArray: Array<NERtcConstants.NERtcVideoRecvStats>):void => {
            let detailInfo = JSON.stringify(statsArray, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onRemoteVideoStats: ${detailInfo}`)
          },

          onNetworkQuality:(statsArray: Array<NERtcConstants.NERtcNetworkQualityInfo>):void => {
            let detailInfo = JSON.stringify(statsArray, (key, value: Object) => {
              if(typeof value === "bigint") {
                return String(value)
              }
              return value
            })
            console.info('statsObserver', `onNetworkQuality: ${detailInfo}`)
          }
        })
      }

      if(gOtherModel) {
        /***
         * ################ setLocalPublishFallbackOption  ################
         * DISABLE: 上行网络较弱时，不对音视频流作回退处理，但不能保证音视频流的质量。
         * AUDIO_ONLY: 上行网络较弱时，只发布音频流。
         */
        let upFallbackOption = gOtherModel.upFallbackOption
        let streamOption: number  = NERtcConstants.StreamFallbackOption.DISABLED
        if(upFallbackOption == 1) {
          streamOption = NERtcConstants.StreamFallbackOption.AUDIO_ONLY
        }
        let ret: number = NERtcSDK.getInstance().setLocalPublishFallbackOption(streamOption)
        console.info(TAG, `setLocalPublishFallbackOption ret:${ret}`)

        /***
         * ################ setRemoteSubscribeFallbackOption  ################
         * VIDEO_STREAM_LOW: 在下行网络条件较差的情况下，SDK 将只接收视频小流，即低分辨率、低码率视频流。
         * AUDIO_ONLY: 下行网络较弱时，先尝试只接收视频小流，即低分辨率、低码率视频流。如果网络环境无法显示视频，则再回退到只接收音频流。
         */
        let downFallbackOption = gOtherModel.downFallbackOption
        if(downFallbackOption == 0) {
          streamOption = NERtcConstants.StreamFallbackOption.VIDEO_STREAM_LOW
        } else if(downFallbackOption == 1) {
          streamOption = NERtcConstants.StreamFallbackOption.AUDIO_ONLY
        }
        ret = NERtcSDK.getInstance().setRemoteSubscribeFallbackOption(streamOption)
        console.info(TAG, `setRemoteSubscribeFallbackOption ret:${ret}`)
      }

      if(gAudioModel) {
        this.realTimeVolumeEnable(gAudioModel.captureVolumeEnable)
      }
    } catch (e) {
      console.error(TAG, JSON.stringify(e))
    }


    let format = new NERtcConstants.NERtcAudioFrameRequestFormat
    format.channels = 1
    format.sampleRate = 16000
    format.opMode = NERtcConstants.NERtcAudioFrameOpMode.kNERtcAudioFrameOpModeReadOnly
    NERtcSDK.getInstance().setMixedAudioFrameParameters(format)
    NERtcSDK.getInstance().setPlaybackAudioFrameParameters(format)
    NERtcSDK.getInstance().setRecordingAudioFrameParameters(format)

    login_ = login;
    let ret: number = NERtcConstants.ErrorCode.NO_ERROR
    if(login) {
      ret = NERtcSDK.getInstance().joinChannel(login?.token ?? "", login?.cname, BigInt(login?.uid))
      state_ = (ret == NERtcConstants.ErrorCode.NO_ERROR) ? ChatState.CHAT_ING : ChatState.CHAT_IDLE
      console.info(TAG, "=== Invoke join End. ===")
      this.enableBackgroundRunning(true);
      this.enableVoiceEffectIfNeeded();
      this.enableVirtualBackgroundIfNeeded()
    } else {
      console.error(TAG, 'LoginInfo is empty.')
    }
    return ret
  }

  leave() {
    NERtcSDK.getInstance().setStatsObserver(null)
    let ret: number = NERtcSDK.getInstance().leaveChannel()
    console.info(TAG, 'Leave channel ret: ' + ret)
    // remoteUsers_ = []
    this.localUser = null
    this.enableBackgroundRunning(false);
  }

  attach(user: DemoUser): void {

    let scaleMode: number = NERtcConstants.NERtcVideoScalingMode.kNERtcVideoScaleFit
    if(gVideoModel) {
      scaleMode = gVideoModel.scaleMode
    }

    let canvas: NERtcConstants.NERtcVideoCanvas = { canvasId: user.xComponentIdMain, scalingMode: scaleMode }
    //fix issue for OMNRTCG2-58636
    if(login_ && login_.uid == '0') {
      login_.uid = user.uid.toString()
    }
    let isMe = user.uid.toString() === login_?.uid
    let ret: number;
    if(isMe) {
      ret = NERtcSDK.getInstance().setupLocalVideoCanvas(canvas)
    } else {
      ret = NERtcSDK.getInstance().setupRemoteVideoCanvas(canvas, user.uid)
    }
    console.info(TAG, `uid:${user.uid} setup canvas ret:${ret}`)
  }

  attachSub(user: DemoUser): void {
    if(!user.xComponentIdSub) {
      return
    }

    let scaleMode: number = NERtcConstants.NERtcVideoScalingMode.kNERtcVideoScaleFit
    if(gVideoModel) {
      scaleMode = gVideoModel.scaleMode
    }

    let canvas: NERtcConstants.NERtcVideoCanvas = { canvasId: user.xComponentIdSub,
     scalingMode: scaleMode }
    let ret:  number;
    if(user.local) {
      ret = NERtcSDK.getInstance().setupLocalSubStreamVideoCanvas(canvas)
    } else {
      ret = NERtcSDK.getInstance().setupRemoteSubStreamVideoCanvas(canvas, user.uid)
    }
    console.info(TAG, `uid:${user.uid}, setup sub canvas local:${user.local} ret:${ret}`)
  }

  enableVideo(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalVideo(enabled, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
    console.info(TAG, `enableVideo enabled:${enabled}, result:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地主流视频:${enabled?'开':'关'}`})
    } else {
      Prompt.showToast({ message: `本地主流视频操作失败:${ret}`})
    }
  }

  enableSubVideo(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalVideo(enabled, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
    console.info(TAG, `enableSubVideo enabled:${enabled}, result:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地辅流视频:${enabled?'开':'关'}`})
    } else {
      Prompt.showToast({ message: `本地辅流视频操作失败:${ret}`})
    }

    if(this.localUser) {
      if(enabled && ret == NERtcConstants.ErrorCode.NO_ERROR) {
        this.localUser.xComponentIdSub = this.localUser.generatorSubCanvasId()
        delegates_?.forEach(delegate_ => {
          delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser));
        });
      } else {
        this.localUser.xComponentIdSub = undefined
        delegates_?.forEach(delegate_ => {
          delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser));
        });
      }
    }
  }

  muteVideo(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalVideo(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain, mute)
    console.info(TAG, `muteVideo mute:${mute}, ret:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地主流视频:${mute ? 'mute':'unmute'} ret:${ret}`})
    }
  }

  muteSubVideo(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalVideo(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, mute)
    console.info(TAG, `muteSubVideo mute:${mute}, ret:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地辅流视频:${mute ? 'mute':'unmute'} ret:${ret}`})
    }
  }

  enableAudio(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalAudio(enabled)
    console.info(TAG, `enableAudio enabled:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地音频:${enabled?'开':'关'}`})
    }
  }

  enableSubAudio(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalSubStreamAudio(enabled)
    console.info(TAG, `enableSubAudio enabled:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地辅流音频:${enabled?'开':'关'}`})
    } else {
      Prompt.showToast({ message: `操作辅流音频失败:${ret}`})
    }
  }

  muteAudio(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalAudioStream(mute)
    console.info(TAG, `mute main audio stream mute:${mute}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `主流音频${mute ? 'Mute':'UnMute'} ret:${ret}`})
    }
  }

  muteSubAudio(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalSubStreamAudio(mute)
    console.info(TAG, `mute sub audio stream mute:${mute}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `辅流音频${mute ? 'Mute':'UnMute'} ret:${ret}`})
    }
  }

  publishAudio(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableMediaPub(NERtcConstants.NERtcMediaPublishType.kNERtcMediaPublishTypeAudio, enabled)
    console.info(TAG, `pushAudio enabled:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地音频发布:${enabled ? '开':'关'}`})
    }
  }

  upload() {
    NERtcSDK.getInstance().uploadSdkInfo()
    console.info(TAG, 'upload sdk info done.')
  }

  reportCustomEvent(): number {
    let param: Map<string, Object> = new Map;
    param.set('test01', 1)
    param.set('test02', '2')
    return NERtcSDK.getInstance().reportCustomEvent('ohos_test', '0x11', param)
  }

  setClientRole(audience: boolean): void {
    let ret = NERtcSDK.getInstance().setClientRole(audience ? NERtcConstants.NERtcClientRole.kNERtcClientRoleAudience : NERtcConstants.NERtcClientRole.kNERtcClientRoleBroadcaster)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置${audience ? '观众':'主播'}成功`})
    }
  }

  muteLocalAudio(enable: boolean): void {
    let ret: number = NERtcSDK.getInstance().muteLocalAudioStream(enable)
    console.info(TAG, `muteLocalAudioStream enabled: ${enable}, ret: ${ret}`)
  }

  enableMediaCryptoCustom(enabled: boolean): number {
    if(enabled) {
      let observer: NERtcPacketObserver = new DemoNERtcPackageObserver();
      let config: NERtcConstants.NERtcEncryptionConfig = {
        mode: NERtcConstants.EncryptionMode.EncryptionModeCustom,
        key: 'I_am_a_key',
        observer: observer
      }
      return NERtcSDK.getInstance().enableEncryption(enabled, config)
    } else {
      let config: NERtcConstants.NERtcEncryptionConfig = {
        mode: NERtcConstants.EncryptionMode.EncryptionModeCustom,
        key: 'I_am_a_key',
        observer: null
      }
      return NERtcSDK.getInstance().enableEncryption(enabled, config)
    }
  }

  enableMediaCryptoSM4(enabled: boolean): void {
    let config: NERtcConstants.NERtcEncryptionConfig = {
      mode: NERtcConstants.EncryptionMode.GMCryptoSM4ECB,
      key: "I_am_a_key",
      observer: null
    }
    NERtcSDK.getInstance().enableEncryption(enabled, config);
  }

  enablePushAudioEncodeFrame(enabled: boolean, path?: string): boolean {
    if(enabled) {
      if(!path) return false
      if(!this.audioEncodedSource) {
        this.audioEncodedSource = new ExternalOpusSource(Product.RTC_DEMO, NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain, path, 48000, 2)
      }
      if(NERtcSDK.getInstance().enableLocalAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalAudioSource(true, 48000, 2) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().enableLocalAudio(true) != NERtcConstants.ErrorCode.NO_ERROR) return false

      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.externalAudioSourceMain) {
        this.externalAudioSourceMain.stop()
        this.externalAudioSourceMain = null
      }
      return this.audioEncodedSource.start()
    } else {
      if(this.audioEncodedSource) {
        this.audioEncodedSource.stop()
        this.audioEncodedSource = undefined
      }
      if(NERtcSDK.getInstance().enableLocalAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalAudioSource(false, 48000, 2) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().enableLocalAudio(true) != NERtcConstants.ErrorCode.NO_ERROR) return false
    }
    return true
  }

  enablePushSubAudioEncodeFrame(enabled: boolean, path?: string): boolean {
    if(enabled) {
      if(!path) return false
      if(!this.audioSubEncodedSource) {
        this.audioSubEncodedSource = new ExternalOpusSource(Product.RTC_DEMO, NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeSub, path, 48000, 2)
      }
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(true, 48000, 2) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(true) != NERtcConstants.ErrorCode.NO_ERROR) return false

      if(this.externalAudioSourceSub) {
        this.externalAudioSourceSub.stop()
        this.externalAudioSourceSub = null
      }
      return this.audioSubEncodedSource.start()
    } else {
      if(this.audioSubEncodedSource) {
        this.audioSubEncodedSource.stop()
        this.audioSubEncodedSource = undefined
      }
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(false, 48000, 2) != NERtcConstants.ErrorCode.NO_ERROR) return false
    }
    return true
  }

  enablePushVideoEncodeFrame(enabled: boolean, path?: string): boolean {
    if(enabled) {
      if(!path || !this.dir) return false
      NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
      NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
      NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
      if (!this.videoEncodedSource) {
        this.videoEncodedSource = new PushExternalH264Video(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain, path, 640, 480, 15);
      }

      /**
       * DEMO bug, 如果开启外部视频输入，再推裸流无效，因为鸿蒙同一线程只能执行一个 interval.
       * @see Overmind-id OMNRTCG2-57526
       */
      if(this.externalVideoSourceMain){
        this.externalVideoSourceMain.stop()
        this.externalVideoSourceMain = null
      }

      this.videoEncodedSource.start();
    } else {
      if(this.videoEncodedSource) {
        this.videoEncodedSource.stop()
        this.videoEncodedSource = undefined
      }
      NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
      NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
      NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain);
    }
    return true
  }

  enablePubSubVideoEncodedFrame(enabled: boolean, path?: string): boolean {
    if(enabled) {
      if(!path || !this.dir) return false
      NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub);
      NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub);
      NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub);

      if (!this.videoSubEncodedSource) {
        this.videoSubEncodedSource = new PushExternalH264Video(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, path, 640, 480, 15);
      }

      /**
       * @see Overmind-id OMNRTCG2-57526
       */
      if(this.externalVideoSourceSub) {
        this.externalVideoSourceSub.stop()
        this.externalVideoSourceSub = null
      }

      if(this.videoSubEncodedSource.start()) {
        Prompt.showToast({ message: '辅流裸流开启成功'})
      }
    } else {
      if(this.videoSubEncodedSource) {
        this.videoSubEncodedSource.stop()
        this.videoSubEncodedSource = undefined
      }
      NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
      NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
      NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
    }
    return true
  }

  enableQosCallback(enable: boolean): void {
    if(enable) {
      NERtcSDK.getInstance().setVideoEncoderQosObserver({
        onRequestSendKeyFrame: (streamType: NERtcConstants.NERtcVideoStreamType): void => {
          console.info(TAG, 'onRequestSendKeyFrame streamType: ' + streamType)
        },
        onBitrateUpdated: (bitrateBps: number, streamType: NERtcConstants.NERtcVideoStreamType): void => {
          console.info(TAG, 'onBitrateUpdated bitrateBps: ' + bitrateBps + ", streamType: " + streamType)
        },
        onVideoCodecUpdated: (videoCodeType: NERtcConstants.NERtcVideoCodecType,
          streamType: NERtcConstants.NERtcVideoStreamType): void => {
          console.info(TAG, 'onVideoCodecUpdated videoCodeType: ' + videoCodeType + ", streamType: " + streamType)
        }
      })
    } else {
      if(this.preObserver) {
        this.preObserver.clear()
        this.preObserver = null
      }
      NERtcSDK.getInstance().setVideoEncoderQosObserver(null)
    }
  }

  enablePreDecodeCallback(enable: boolean): void {
    if(enable) {
      if(!this.preObserver) {
        let predecodeDir = this.dir + "/predecode"
        this.preObserver = new DemoNERtcPreDecodeObserver(predecodeDir)
      }

      let result: number = NERtcSDK.getInstance().setPreDecodeObserver(this.preObserver);
      if(result == NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: '开启前处理回调成功'})
      }
    } else {
      NERtcSDK.getInstance().setPreDecodeObserver(null)
    }
  }

  enableEarBack(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableEarback(enabled)
    console.info(TAG, 'enableEarback ret: ' + ret)
    ret = NERtcSDK.getInstance().setEarbackVolume(100)
    console.info(TAG, 'setEarbackVolume 100, ret: ' + ret)
  }

  enableAudioMix(enabled: boolean) {

    if(!gAudioModel.audioMixUrl && !gAudioModel.audioMixPath) {
      Prompt.showToast({ message: '请设置伴音播放路径' })
      return
    }

    if(enabled) {
      let option: NERtcConstants.NERtcCreateAudioMixingOption = new NERtcConstants.NERtcCreateAudioMixingOption

      let lastPath: string
      if(gAudioModel.audioMixUrl.trim() != '') {
        lastPath = gAudioModel.audioMixUrl
      } else {
        const splits = gAudioModel.audioMixPath.split('/')
        const fileName = splits[splits.length - 1]
        lastPath = getContext().filesDir + "/media/" + fileName
      }

      option.path = lastPath
      option.loopCount = gAudioModel.audioMixLoopNum
      option.sendEnabled = gAudioModel.audioMixIsSend
      option.playbackEnabled = gAudioModel.audioMixIsPlay

      let ret: number = NERtcSDK.getInstance().startAudioMixing(option)
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: '播放伴音失败' })
      }
    } else {
      let ret: number = NERtcSDK.getInstance().stopAudioMixing()
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: '停止伴音失败' })
      }
    }
  }

  setAudioMixingPitch() {
    let ret: number = NERtcSDK.getInstance().setAudioMixingPitch(gAudioModel.audioMixPitch)
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置伴音音调失败':${ret}`})
    }
  }

  enableAudioEffect(enabled: boolean) {

    if(!gAudioModel.audioEffect1Url) {
      Prompt.showToast({ message: '请设置音效播放路径' })
      return
    }

    if(enabled) {
      const splits = gAudioModel.audioEffect1Url.split('/')
      const fileName = splits[splits.length - 1]
      const lastPath = getContext().filesDir + "/media/" + fileName

      let option: NERtcConstants.NERtcCreateAudioEffectOption = new NERtcConstants.NERtcCreateAudioEffectOption
      option.path = lastPath
      option.loopCount = gAudioModel.audioEffect1LoopNum
      option.sendEnabled = gAudioModel.audioEffect1IsSend
      option.playbackEnabled = gAudioModel.audioEffect1IsPlay

      let ret: number = NERtcSDK.getInstance().playEffect(1, option)
      console.info(TAG, `playEffect id:1, ret:${ret}`)
    } else {
      let ret: number = NERtcSDK.getInstance().stopEffect(1)
      console.info(TAG, `stopEffect id:1, ret:${ret}`)
    }
  }

  setAudioEffectPitch() {
    let ret: number = NERtcSDK.getInstance().setEffectPitch(1, gAudioModel.audioEffect1Pitch)
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置音调音调失败':${ret}`})
    }
  }

  enableScreenShare(enable: boolean) {
    if(enable) {

      let profile: number = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD1080P
      if(gVideoModel.screenSendResolution == 0) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileStandard
      } else if(gVideoModel.screenSendResolution == 1) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD720P
      } else if(gVideoModel.screenSendResolution == 2) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD1080P
      }

      let frameRate: number = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps30
      switch (gVideoModel.screenFrameRate) {
        case 0:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps7
          break;
        case 1:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps10
          break;
        case 2:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps15
          break;
        case 3:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps24
          break;
        case 4:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps30
          break;
        default:
          frameRate = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFpsDefault
          break;
      }

      let contentPrefer: NERtcConstants.NERtcSubStreamContentPrefer = NERtcConstants.NERtcSubStreamContentPrefer.kNERtcSubStreamContentPreferMotion;
      if (gVideoModel.screenMode == 1) {
        contentPrefer = NERtcConstants.NERtcSubStreamContentPrefer.kNERtcSubStreamContentPreferDetails;
      }
      let config: NERtcConstants.NERtcScreenConfiguration = new NERtcConstants.NERtcScreenConfiguration
      config.maxProfile = profile
      config.framerate = frameRate
      config.minFramerate = gVideoModel.screenMinFrameRate
      config.bitrate = gVideoModel.screenBitRate
      config.minBitrate = gVideoModel.screenMinBitRate
      config.contentPrefer = contentPrefer;

      let ret: number = NERtcSDK.getInstance().startScreenCapture(config)
      console.info(TAG, `startScreenCapture, ret: ${ret}`)

      if(ret == NERtcConstants.ErrorCode.NO_ERROR && this.localUser) {
        this.localUser.xComponentIdSub = this.localUser.generatorSubCanvasId()
        delegates_?.forEach(delegate_ => {
          delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser));
        });
      }
    } else {
      let ret: number = NERtcSDK.getInstance().stopScreenCapture()
      console.info(TAG, `stopScreenCapture, ret: ${ret}`)
      if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
        if(this.localUser) {
          this.localUser.xComponentIdSub = undefined
          delegates_?.forEach(delegate_ => {
            delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser));
          });
        }
      }
    }
  }

  enableSpeakerOn(enabled: boolean ) {
    let ret: number = NERtcSDK.getInstance().setSpeakerphoneOn(enabled)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      setTimeout(() => {
        let on: boolean = NERtcSDK.getInstance().isSpeakerphoneOn()
        console.info(TAG, 'isSpeakerphoneOn: ' + on)
        Prompt.showToast({ message: `设置扬声器: ${on ? '开': '关'}`})
      }, 500)
    }
  }

  enableAudioDump(enabled: boolean) {

    let type: number = NERtcConstants.NERtcAudioDumpType.kNERtcAudioDumpTypeWAV
    if(gAudioModel) {
      type = gAudioModel.audioDumpType
      console.info(TAG, `audio dump type: ${type}`)
    }

    if(enabled) {
      let ret: number = NERtcSDK.getInstance().startAudioDumpWithType(type)
      if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: '音频DUMP开启' })
      }
    } else {
      let ret: number = NERtcSDK.getInstance().stopAudioDump()
      if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: '音频Dump关闭' })
      }
    }
  }

  startPreview(login: LoginInfo) {
    login_ = login
    this.enableVirtualBackgroundIfNeeded()
    let ret: number = NERtcSDK.getInstance().startVideoPreview(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
    Prompt.showToast({ message: `打开预览:${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
  }

  takeSnapShot(user: DemoUser) {
    try {
      let streamType = user.userCheckIsMainStream() ? '_main' : '_sub'
      let fileName = String(user.uid) + "_" + systemDateTime.getTime() + streamType + ".jpg"
      const path: string = getContext().filesDir + "/" + fileName + ".jpg"
      console.info(TAG, `path: ` + path)
      if(user.local) {
        NERtcSDK.getInstance().takeLocalSnapshot(user.userCheckIsMainStream() ? NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain : NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, {
          onTakeSnapshotResult: (errorCode: number, image_?: PixelMap | undefined) => {
            this.saveSnapshotEncapsulation(errorCode, image_, path);
          }
        })
      } else {
        NERtcSDK.getInstance().takeRemoteSnapshot(user.uid, user.userCheckIsMainStream() ? NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain : NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, {
          onTakeSnapshotResult: (errorCode: number, image_?: PixelMap | undefined) => {
            this.saveSnapshotEncapsulation(errorCode, image_, path)
          }
        })
      }
    } catch (e) {
      console.info(TAG, 'takeSnapshot error:' + JSON.stringify(e))
    }
  }

  private saveSnapshotEncapsulation(errorCode: number, image_?: image.PixelMap, path?: string) {
    if(errorCode == NERtcConstants.ErrorCode.NO_ERROR && image_) {
      let packOpts: image.PackingOption = { format: "image/jpeg", quality: 100 }
      let file = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
      const imagePackerApi: image.ImagePacker = image.createImagePacker();
      imagePackerApi.packToFile(image_, file.fd, packOpts, (err: BusinessError) => {
        if(err) {
          console.error(TAG, 'packToFile failed. message: ' + err.message)
          Prompt.showToast({ message: '截图失败, 原因:' + err.message})
        } else {
          Prompt.showToast({ message: '截图成功,保存路径:' + path })
        }
      })
    }
  }

  changeCanvasStyle(user: DemoUser): void {

    let mirrorMode: number = user.getCanvasMirror() ? NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeEnabled :
      NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeDisabled
    let scaleMode = user.getScaleMode()

    if(user.local) {
      if(user.userCheckIsMainStream()) {
        NERtcSDK.getInstance().setupLocalVideoCanvas({ canvasId: user.xComponentIdMain, mirrorMode: mirrorMode, scalingMode: scaleMode })
      } else {
        NERtcSDK.getInstance().setupLocalSubStreamVideoCanvas({ canvasId: user.xComponentIdSub ?? '', mirrorMode: mirrorMode, scalingMode: scaleMode })
      }
    } else {
      if(user.userCheckIsMainStream()) {
        NERtcSDK.getInstance().setupRemoteVideoCanvas({ canvasId: user.xComponentIdMain, mirrorMode: mirrorMode, scalingMode: scaleMode }, user.uid)
      } else {
        NERtcSDK.getInstance().setupRemoteSubStreamVideoCanvas({ canvasId: user.xComponentIdSub ?? '', mirrorMode: mirrorMode, scalingMode: scaleMode }, user.uid)
      }
    }
  }


  subscribeAllAudio(enabled: boolean): void {
    let ret: number = NERtcSDK.getInstance().subscribeAllRemoteAudioStreams(enabled)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `${enabled?'订阅':'取消订阅'}所有用户音频成功`})
    }
  }

  enableLoopBack(enabled: boolean): void {
    let ret: number = NERtcSDK.getInstance().enableLoopBackRecording(enabled)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `${enabled?'打开':'关闭'}音频共享成功`})
    }
  }

  setMicMute(mute: boolean): void {
    let ret: number = NERtcSDK.getInstance().setRecordDeviceMute(mute)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `麦克风设置${mute? '静音': '取消静音'}成功`})
    }
  }

  setPlayoutDeviceMute(mute: boolean): void {
    let ret: number = NERtcSDK.getInstance().setPlayoutDeviceMute(mute)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置播放设备${mute ? '静音':'取消静音'}成功`})
    }
  }

  realTimeVolumeEnable(enabled: boolean): void {
    let volumeDuration = 200
    let vad = false

    if(gAudioModel) {
      volumeDuration = gAudioModel.captureVolumeIndicationDuration
      vad = gAudioModel.captureVolumeVAD
    }

    let ret: number = NERtcSDK.getInstance().enableAudioVolumeIndication(enabled, BigInt(volumeDuration), vad)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `实时音量${enabled?'开启':'关闭'}成功`})
    }
  }

  enablePushExternalAudioInput(enabled: boolean): boolean {

    //Fix crash for OMNRTCG2-58947.
    if(!gAudioModel.externalAudioInputUrl || gAudioModel.externalAudioInputUrl == '') {
      Prompt.showToast({ message: '请设置外部音频输入路径'})
      return false
    }

    if(gAudioModel.externalAudioInputChannelNum == 0 || gAudioModel.externalAudioInputSampleRate == 0) {
      Prompt.showToast({ message: '外部音频输入参数错误'})
      return false
    }

    if(enabled) {
      let inputFile = gAudioModel.externalAudioInputUrl.split("/")
      let fileName = inputFile[inputFile.length - 1]

      let type: number = NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain
      if(!this.externalAudioSourceMain) {
        this.externalAudioSourceMain = new ExternalPcmSource(Product.RTC_DEMO, type, fileName, gAudioModel.externalAudioInputSampleRate, gAudioModel.externalAudioInputChannelNum)
      }
      if(NERtcSDK.getInstance().enableLocalAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalAudioSource(true, gAudioModel.externalAudioInputSampleRate, gAudioModel.externalAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().enableLocalAudio(true) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.audioEncodedSource) {
        this.audioEncodedSource.stop()
        this.audioEncodedSource = undefined
      }

      this.externalAudioSourceMain.start()
      Prompt.showToast({ message: `外部音频启动成功`})
    } else {
      if(NERtcSDK.getInstance().enableLocalAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalAudioSource(false, gAudioModel.externalAudioInputSampleRate, gAudioModel.externalAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().enableLocalAudio(true) == NERtcConstants.ErrorCode.NO_ERROR) {
        console.info(TAG, 'open mic success.')
      }
      this.externalAudioSourceMain?.stop();
      this.externalAudioSourceMain = null
      Prompt.showToast({ message: `外部音频关闭成功`})
    }
    return true
  }

  enablePushSubExternalAudioInput(enabled: boolean): boolean {

    if(gAudioModel.externalSubAudioInputUrl == '') {
      Prompt.showToast({ message: '请设置外部音频输入路径'})
      return false
    }

    if(gAudioModel.externalSubAudioInputSampleRate == 0 || gAudioModel.externalSubAudioInputChannelNum == 0) {
      Prompt.showToast({ message: '外部音频输入参数错误'})
      return false
    }

    if(enabled) {
      let inputFile = gAudioModel.externalSubAudioInputUrl.split("/")
      let fileName = inputFile[inputFile.length - 1]

      let type: number = NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeSub
      if(!this.externalAudioSourceSub) {
        this.externalAudioSourceSub = new ExternalPcmSource(Product.RTC_DEMO, type, fileName, gAudioModel.externalSubAudioInputSampleRate, gAudioModel.externalSubAudioInputChannelNum)
      }
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(true, gAudioModel.externalSubAudioInputSampleRate, gAudioModel.externalSubAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(true) != NERtcConstants.ErrorCode.NO_ERROR) return false

      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.audioSubEncodedSource) {
        this.audioSubEncodedSource.stop()
        this.audioSubEncodedSource = undefined
      }
      this.externalAudioSourceSub.start()
      Prompt.showToast({ message: '外部音频辅流启动成功'})
    } else {
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(false, gAudioModel.externalSubAudioInputSampleRate, gAudioModel.externalSubAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) return false
      this.externalAudioSourceSub?.stop()
      this.externalAudioSourceSub = null
      Prompt.showToast({ message: '外部音频辅流关闭成功'})
    }
    return true
  }

  enablePushExternalVideoInput(enabled: boolean): boolean {

    if(gVideoModel.externalVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(gVideoModel.externalVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }

    if(enabled) {

      let inputFile = gVideoModel.externalVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceMain) {
        this.externalVideoSourceMain = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain, fileName, gVideoModel.externalVideoWidth, gVideoModel.externalVideoHeight, gVideoModel.externalVideoFrameRate, gVideoModel.externalVideoRotation)
      }

      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) != NERtcConstants.ErrorCode.NO_ERROR){
        return false
      }

      if(NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.videoEncodedSource) {
        this.videoEncodedSource.stop()
        this.videoEncodedSource = undefined
      }

      this.externalVideoSourceMain.start()
      Prompt.showToast({ message: '外部视频输入开启成功' })
    } else {

      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      if(NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      this.externalVideoSourceMain?.stop()
      this.externalVideoSourceMain = null

      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) == NERtcConstants.ErrorCode.NO_ERROR) {
        console.info(TAG, 'open camera success')
      }
      Prompt.showToast({ message: '外部视频输入关闭成功'})
    }
    return true
  }


  enableSubPushExternalVideoInput(enabled: boolean): boolean {

    if(gVideoModel.externalSubVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(gVideoModel.externalSubVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }

    if(enabled) {

      let inputFile = gVideoModel.externalSubVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceSub) {
        this.externalVideoSourceSub = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, fileName, gVideoModel.externalSubVideoWidth, gVideoModel.externalSubVideoHeight, gVideoModel.externalSubVideoFrameRate, gVideoModel.externalSubVideoRotation)
      }

      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) != NERtcConstants.ErrorCode.NO_ERROR){
        return false
      }

      if(NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }


      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.videoSubEncodedSource) {
        this.videoSubEncodedSource.stop()
        this.videoSubEncodedSource = undefined
      }

      let result = this.externalVideoSourceSub.start()
      if(result && this.localUser) {
        Prompt.showToast({ message: '外部辅流视频输入开启成功' })
        let canvasId = this.localUser.generatorSubCanvasId();
        this.localUser.xComponentIdSub = canvasId
        delegates_?.forEach(delegate_ => {
          delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser))
        })
      }
    } else {
      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      this.externalVideoSourceSub?.stop()
      this.externalVideoSourceSub = null
      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) == NERtcConstants.ErrorCode.NO_ERROR) {
        console.info(TAG, 'open camera success')
      }
      Prompt.showToast({ message: '外部辅流视频输入关闭成功'})
      if(this.localUser) {
        this.localUser.xComponentIdSub = undefined
        delegates_?.forEach(delegate_ => {
          delegate_?.update(OPERATOR.UPD, DemoUser.newInstance(this.localUser))
        })
      }
    }
    return true
  }

  subscribe(uid: bigint, stream: number, type: number, dual: number, subscribe: boolean): void {
    if(stream == 0) { //audio
      if(type == 0) {
        NERtcSDK.getInstance().subscribeRemoteAudioStream(uid, subscribe)
      } else {
        NERtcSDK.getInstance().subscribeRemoteSubStreamAudio(uid, subscribe)
      }
    } else if(stream == 1) { //video
      if(type == 0) {
        let subType: number = (dual == 0) ? NERtcConstants.NERtcRemoteVideoSubscribeType.kNERtcRemoteVideoSubscribeTypeHigh:NERtcConstants.NERtcRemoteVideoSubscribeType.kNERtcRemoteVideoSubscribeTypeLow
        NERtcSDK.getInstance().subscribeRemoteVideo(uid, subscribe, subType)
      } else {
        NERtcSDK.getInstance().subscribeRemoteSubStreamVideo(uid, subscribe)
      }
    }
  }

  switchCamera() {
    let ret: number = NERtcSDK.getInstance().switchCamera()
    Prompt.showToast({ message: `切换摄像头:${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
  }

  enableAudioFrameObserver(enable: boolean): void {

    if(gAudioModel) {
      let format: NERtcConstants.NERtcAudioFrameRequestFormat = new NERtcConstants.NERtcAudioFrameRequestFormat
      format.channels = gAudioModel.audioCallbackChannel
      format.sampleRate = gAudioModel.audioCallbackSampleRate
      format.opMode = gAudioModel.audioCallbackReadOnly ? NERtcConstants.NERtcAudioFrameOpMode.kNERtcAudioFrameOpModeReadOnly : NERtcConstants.NERtcAudioFrameOpMode.kNERtcAudioFrameOpModeReadWrite
      NERtcSDK.getInstance().setMixedAudioFrameParameters(format)
      NERtcSDK.getInstance().setPlaybackAudioFrameParameters(format)
      NERtcSDK.getInstance().setRecordingAudioFrameParameters(format)
      NERtcSDK.getInstance().setPlaybackBeforeMixingAudioFrameParameters(format)
    }

    let result: number = NERtcConstants.ErrorCode.NO_ERROR;
    if (enable) {
      this.audioFrameObserver.setFileDir(this.dir!);
      result = NERtcSDK.getInstance().setAudioFrameObserver(this.audioFrameObserver);
    } else {
      result = NERtcSDK.getInstance().setAudioFrameObserver(null);
      this.audioFrameObserver.clearUp();
    }
    if (enable) {
      Prompt.showToast({ message: `音频数据回调已开启, result:${result}` });
    } else {
      Prompt.showToast({ message: `音频数据回调已关闭，result:${result}` });
    }
  }

  enableVideoFrameObserver(enable: boolean): void {
    let result: number = NERtcConstants.ErrorCode.NO_ERROR;
    if (enable) {
      this.videoFrameObserver.setFileDir(this.dir!);
      result = NERtcSDK.getInstance().setVideoFrameObserver(this.videoFrameObserver);
    } else {
      result = NERtcSDK.getInstance().setVideoFrameObserver(null);
      this.videoFrameObserver.clearUp();
    }
    if (enable) {
      Prompt.showToast({ message: `视频数据回调已开启, result:${result}` });
    } else {
      Prompt.showToast({ message: `视频数据回调已关闭，result:${result}` });
    }
  }

  /**
   * 设置黑白名单
   * @param blackList
   * @param whiteList
   */
  setBlackWhiteList(blackList: BigUint64Array|null, pubWhiteList: BigUint64Array|null, subWhiteList: BigUint64Array|null) {
    let setBlackListRet: number = NERtcSDK.getInstance().setSubscribeAudioBlacklist(blackList, NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain)
    let setPubWhiteListRet: number = NERtcSDK.getInstance().setSubscribeAudioWhitelist(pubWhiteList)
    let setSubWhiteListRet: number = NERtcSDK.getInstance().setAudioSubscribeOnlyBy(subWhiteList)
    Prompt.showToast({ message:
    `设置黑名单列表:${ blackList ? [...blackList] : 'null'}, 设置结果:${setBlackListRet} \n
     设置上行白名单列表:${ pubWhiteList ? [...pubWhiteList] : 'null'}, 设置结果:${setPubWhiteListRet} \n
     设置下行白名单列表:${ subWhiteList ? [...subWhiteList] : 'null'}, 设置结果:${setSubWhiteListRet}`})
  }

  enableLastMileProbe(enabled: boolean): number {

    let ret: number = NERtcConstants.ErrorCode.NO_ERROR
    if(enabled) {
      let upBitRate = gOtherModel.upLinkBitRate
      let downBitRate = gOtherModel.downLinkBitRate
      let upLinkProbe = gOtherModel.upLinkProbe
      let downLinkProbe = gOtherModel.downLinkProbe

      let config: NERtcConstants.NERtcLastmileProbeConfig = {
        probeUplink: upLinkProbe,
        probeDownlink: downLinkProbe,
        expectedUplinkBitrate: BigInt(upBitRate),
        expectedDownlinkBitrate: BigInt(downBitRate)
      }
      ret = NERtcSDK.getInstance().startLastmileProbeTest(config)
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        Prompt.showToast({ message: `开启测速失败:${ret}, 请检查 设置-其他-网络测速 是否开启`})
      }
    } else {
      ret = NERtcSDK.getInstance().stopLastmileProbeTest()
      Prompt.showToast({ message: `停止测速:${ret}`})
    }
    return ret
  }

  release() {
    NERtcSDK.getInstance().setStatsObserver(null)
    NERtcSDK.getInstance().release()
    console.info(TAG, 'Call release done.')
    this.localUser = null
    this.isAudioFrameObserverEnabled = false;
    this.isVideoFrameObserverEnabled = false;
    this.audioFrameObserver.clearUp();
    this.videoFrameObserver.clearUp();
  }

}
