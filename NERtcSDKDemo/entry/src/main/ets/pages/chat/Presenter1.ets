import { NERtcConstants, NERtcSDK, NERtcCallbackEx} from '@nertc/nertc_sdk/Index';

import { NERtcPacketObserver} from '@nertc/nertc_sdk';
import DemoUser from '../../model/DemoUser';
import { ChatState, LoginInfo } from './ChatModel';
import UIDelegate, { OPERATOR } from './Delegate';
import ExternalOpusSource from '../../external/ExternalOpusSource';
import { Product } from '../../model/common'
import PushExternalH264Video from '../../external/ExternalH264Source1';
import fs from '@ohos.file.fs';
import { RtcDemoAudioFrameObserver, RtcDemoVideoFrameObserver } from '../../common/RtcDemoCallback';
import { preferences } from '@kit.ArkData';
import Prompt from '@ohos.promptAction';
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
import { VideoCaptureProcessing, VideoRenderProcessing } from 'libdataprocessing.so'
import { util } from '@kit.ArkTS';
import LiveStreamingKit from '../LiveStreamingKit';
import * as ModelUtil from './ModelHandleUtils'
import RtcLogicDelegate from './RtcDefaultCallbackEx'
import RtcLogicModel from './RtcLogicModel'

let TAG: string = 'MultiChat'
let login_: LoginInfo;

export default class ChatPresenter {

  private static instance: ChatPresenter = new ChatPresenter()
  private audioEncodedSource?: ExternalOpusSource
  private audioSubEncodedSource?: ExternalOpusSource

  //外部主流码流
  private videoEncodedSource?: PushExternalH264Video
  //外部辅流码流
  private videoSubEncodedSource?: PushExternalH264Video
  //第三流码流
  private videoThirdEncodedSource?: PushExternalH264Video
  //第四流码流
  private videoFourthEncodedSource?: PushExternalH264Video

  private preObserver?: DemoNERtcPreDecodeObserver|null
  private dir?: string
  private av_session: avSession.AVSession|null = null;

  //主流外部输入
  private externalAudioSourceMain: ExternalPcmSource|null = null
  private externalVideoSourceMain: ExternalYuvVideoSource| null = null

  //辅流外部输入
  private externalAudioSourceSub: ExternalPcmSource|null = null
  private externalVideoSourceSub: ExternalYuvVideoSource| null = null

  //第三流外部输入
  private externalVideoSourceThird: ExternalYuvVideoSource| null = null

  //第四流外部输入
  private externalVideoSourceFourth: ExternalYuvVideoSource| null = null

  private audioFrameObserver: RtcDemoAudioFrameObserver = new RtcDemoAudioFrameObserver(TAG);
  private isAudioFrameObserverEnabled: boolean = false;
  private videoFrameObserver: RtcDemoVideoFrameObserver = new RtcDemoVideoFrameObserver(TAG);
  private isVideoFrameObserverEnabled: boolean = false;

  //前处理 native object.
  private videoProcess: VideoCaptureProcessing|null = null
  //外部渲染 native object.
  private videoRender: VideoRenderProcessing|null = null

  //SEI
  private seiIndex: number = 1
  private type: number = 0 //0:普通入房 1:融合推流


  private pushAddressArray: string[] = ["rtmp://pd3ab725c.live.126.net/live/8e79fc0763174fd28ee70e786da7d404?wsSecret=4293eb4624811a854e9abcee760f6ea6&wsTime=1684825921",
  "rtmp://p21058434.live.126.net/live/3a42421848534290908190606cb69d5a?wsSecret=fbc1224f7a3fd63db3584eb0aa6dad81&wsTime=1684825865",
  "rtmp://pb6a1a684.live.126.net/live/892d0c580f9e44b89a65b5aa38550899?wsSecret=e302be5b55a2d28ba70401f48a42a72a&wsTime=1690198587",
  "rtmp://p13b79799.live.126.net/live/6356956ec4fc4e119352ecfad3e39c43?wsSecret=78914026fc11ae61a4d4cd267da47231&wsTime=1714116210",
  "rtmp://pf731f1c7.live.126.net/live/0c8c32bc4a09478ebbc834084092af07?wsSecret=610cbb44de7463c5249bea80f6bef633&wsTime=1714118848"]

  private rtcDemoLogicModel: RtcLogicModel = new RtcLogicModel()
  private rtcDemoLogicDelegate: RtcLogicDelegate = new RtcLogicDelegate(this.rtcDemoLogicModel)

  static getInstance(): ChatPresenter {
    return ChatPresenter.instance
  }

  setDir(dir: string) {
    this.dir = dir
    console.info(TAG, 'Set Dir: ' + dir)
  }

  getType() {
    return this.type;
  }
  setDelegate(delegate: UIDelegate) {
    this.rtcDemoLogicModel.SetDelegate(delegate)
  }

  removeDelegate(delegate: UIDelegate) {
    this.rtcDemoLogicModel.RemoveDelegate(delegate)
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

  GetLogicDataModel(): RtcLogicModel {
    return this.rtcDemoLogicModel
  }

  resetParams(context: Context): void {
    this.rtcDemoLogicModel.LoadDataModel(context)
    this.beforeInitEngineTask()
    this.afterInitEngineTask()
    this.extendInitEngineTask()
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
    this.rtcDemoLogicModel.LoadDataModel(context)
    this.beforeInitEngineTask()
    let option: NERtcConstants.NERtcOption = { logLevel: NERtcConstants.LogLevel.INFO }
    const appKey = this.rtcDemoLogicModel.GetDemoAppKey()

    //**** 私有化设置 ****
    const privateAddress = this.rtcDemoLogicModel.GetPrivateAddress()
    if (privateAddress != null) {
      option.serverAddress = privateAddress
    }

    NERtcSDK.getInstance().init(context, appKey, this.rtcDemoLogicDelegate, option)
    this.afterInitEngineTask()
  }

  triggerCaptionMode(captionMode: boolean) {
    if(captionMode) {
      const otherModel = this.rtcDemoLogicModel.GetPreferenceOtherModel()
      let config: NERtcConstants.NERtcASRCaptionConfig = {
        src_language: otherModel.captionSource, dst_language: otherModel.captionDest
      }
      NERtcSDK.getInstance().startASRCaption(config)
    }else{
      NERtcSDK.getInstance().stopASRCaption()
    }
  }

  private beforeInitEngineTask = (): void => {
    let param: object = new Object();
    const audioMode = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    const videoMode = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    const otherMode = this.rtcDemoLogicModel.GetPreferenceOtherModel()

    //设置SDK日志是否加密，调试阶段关闭，上线阶段打开
    param["sdk.enable.encrypt.log"] = false;
    if (audioMode) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyAutoSubscribeAudio] = audioMode.autoSubAudio
    }
    if (videoMode) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyStartVideoWithBackCamera] = !videoMode.fontCamera

      if (videoMode.encodeMode == 0 || videoMode.encodeMode == 1) {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoEncodeMode] = 0
      } else {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoEncodeMode] = 1
      }

      if (videoMode.decodeMode == 0 || videoMode.decodeMode == 1) {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoDecodeMode] = 0
      } else {
        param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoDecodeMode] = 1
      }

      param[NERtcConstants.NERtcParameterKey.kNERtcKeyVideoSendMode] = videoMode.publishStreamType
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyAutoSubscribeVideo] = videoMode.autoSubVideo
    }

    if (otherMode) {
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordSpeaker] = otherMode.recordSpeaker
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordAudio] = otherMode.audioRecord
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordVideo] = otherMode.videoRecord
      param[NERtcConstants.NERtcParameterKey.kNERtcKeyServerRecordMode] = otherMode.recordMode

      if (otherMode.loginTimeOutTime > 0)
        param['sdk.join.max.time.out'] = otherMode.loginTimeOutTime

      //gop
      if (otherMode.gop != "") {
        param["sdk.cdn.gop"] = Number(otherMode.gop);

        //私有参数
        const privateParam = otherMode.privateParamSetting.trim()
        if (privateParam !== '') {
          ModelUtil.injectJsonValue(param, privateParam)
        }
      }

      NERtcSDK.getInstance().setParameters(param)
    }
  }

  private afterInitEngineTask = (): void => {

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    const otherModel = this.rtcDemoLogicModel.GetPreferenceOtherModel()
    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    const multiVideoModel = this.rtcDemoLogicModel.GetPreferenceMultiVideoModel()

    if (audioModel) {
      NERtcSDK.getInstance().setAudioProfile(audioModel.audioProfile, audioModel.audioScenario)
      NERtcSDK.getInstance().adjustRecordingSignalVolume(audioModel.recordVolume)
      NERtcSDK.getInstance().adjustPlaybackSignalVolume(audioModel.playoutVolume)
    }

    if (otherModel.captionMode) {
      let config: NERtcConstants.NERtcASRCaptionConfig = {
        src_language: otherModel.captionSource, dst_language: otherModel.captionDest
      }
      NERtcSDK.getInstance().startASRCaption(config)
    } else {
      NERtcSDK.getInstance().stopASRCaption()
    }

    if (videoModel) {
      //是否开启小流
      NERtcSDK.getInstance().enableDualStreamMode(videoModel.mainEnableDualStream)
      if (multiVideoModel) {
        NERtcSDK.getInstance().enableDualStreamMode(multiVideoModel.thirdEnableDualStream)
        NERtcSDK.getInstance().enableDualStreamMode(multiVideoModel.fourthEnableDualStream)
      }

      //主流设置
      let configMain: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
      configMain.maxProfile = videoModel.mainSendResolution
      configMain.degradationPreference = videoModel.mainEncodeFrameMode
      configMain.framerate = this.translateFrameRate(videoModel.mainEncodeFrameRate)
      configMain.cropMode = videoModel.mainCropMode
      configMain.mirrorMode = videoModel.mainMirrorMode

      let ret: number = NERtcSDK.getInstance().setLocalVideoConfig(configMain, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
      console.info(TAG, `set main localVideoConfig ret:${ret}, config:${JSON.stringify(configMain)}`)

      //第三流设置
      let configThird: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
      configThird.maxProfile = multiVideoModel.thirdSendResolution
      configThird.degradationPreference = multiVideoModel.thirdEncodeFrameMode
      configThird.framerate = this.translateFrameRate(multiVideoModel.thirdEncodeFrameRate)
      configThird.cropMode = multiVideoModel.thirdCropMode
      configThird.mirrorMode = multiVideoModel.thirdMirrorMode

      ret = NERtcSDK.getInstance().setLocalVideoConfig(configThird, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird)
      console.info(TAG, `set third localVideoConfig ret:${ret}, config:${JSON.stringify(configThird)}`)

      //第四流设置
      let configFourth: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
      configFourth.maxProfile = multiVideoModel.fourthSendResolution
      configFourth.degradationPreference = multiVideoModel.fourthEncodeFrameMode
      configFourth.framerate = this.translateFrameRate(multiVideoModel.fourthEncodeFrameRate)
      configFourth.cropMode = multiVideoModel.fourthCropMode
      configFourth.mirrorMode = multiVideoModel.fourthMirrorMode

      ret = NERtcSDK.getInstance().setLocalVideoConfig(configFourth, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth)
      console.info(TAG, `set fourth localVideoConfig ret:${ret}, config:${JSON.stringify(configFourth)}`)

      //设置主流capture.
      {
        let captureWidth = videoModel.mainCaptureWidth
        let captureHeight = videoModel.mainCaptureHeight

        if(captureWidth != 0 && captureHeight != 0) {
          NERtcSDK.getInstance().setCameraCaptureConfig({ width: captureWidth, height: captureHeight},
            NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
        }
      }

      //设置第三流capture.
      {
        let captureWidth = multiVideoModel.thirdCaptureWidth
        let captureHeight = multiVideoModel.thirdCaptureHeight

        if(captureWidth != 0 && captureHeight != 0) {
          NERtcSDK.getInstance().setCameraCaptureConfig({ width: captureWidth, height: captureHeight},
            NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird)
        }
      }

      //设置第四流capture.
      {
        let captureWidth = multiVideoModel.fourthCaptureWidth
        let captureHeight = multiVideoModel.fourthCaptureHeight

        if(captureWidth != 0 && captureHeight != 0) {
          NERtcSDK.getInstance().setCameraCaptureConfig({ width: captureWidth, height: captureHeight},
            NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth)
        }
      }

      //辅流设置
      let configSub: NERtcConstants.NERtcVideoEncodeConfiguration = new NERtcConstants.NERtcVideoEncodeConfiguration
      configSub.maxProfile = videoModel.subSendResolution
      configSub.degradationPreference = videoModel.subEncodeFrameMode
      configSub.framerate = this.translateFrameRate(videoModel.subEncodeFrameRate)
      configSub.cropMode = videoModel.subCropMode
      configSub.mirrorMode = videoModel.subMirrorMode
      ret = NERtcSDK.getInstance().setLocalVideoConfig(configSub, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
      console.info(TAG, `set sub localVideoConfig ret:${ret}, config:${JSON.stringify(configSub)}`)

      //设置辅流capture.
      {
        let captureWidth = videoModel.subCaptureWidth
        let captureHeight = videoModel.subCaptureHeight

        if(captureWidth != 0 && captureHeight != 0) {
          NERtcSDK.getInstance().setCameraCaptureConfig({width: captureWidth, height: captureHeight},
            NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub)
        }
      }

      // 回调
      if (this.isVideoFrameObserverEnabled != videoModel.enableFrameObserver) {
        this.isVideoFrameObserverEnabled = videoModel.enableFrameObserver;
        this.enableVideoFrameObserver(videoModel.enableFrameObserver);
      }
    }

    const dumpModel = this.rtcDemoLogicModel.GetPreferenceDumpModel()
    if (dumpModel && dumpModel.enableVideoDump) {
      let param: object = new Object();
      if (dumpModel.enableDumpCapturedYUV) {
        param["engine.video.video_dump_captured_yuv_mode"] = dumpModel.enableDumpCapturedYUV;
        param["engine.video.video_dump_captured_yuv_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpCapturedYUVMB);
        param["engine.video.video_dump_captured_yuv_interval"] = this.translateVideoDumpInterval(dumpModel.dumpCapturedYUVInterval);
      }
      if (dumpModel.enableDumpEncodeYUV) {
        param["engine.video.video_dump_encode_yuv_mode"] = dumpModel.enableDumpEncodeYUV;
        param["engine.video.video_dump_encode_yuv_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpEncodeYUVMB);
        param["engine.video.video_dump_encode_yuv_interval"] = this.translateVideoDumpInterval(dumpModel.dumpEncodeYUVInterval);
      }
      if (dumpModel.enableDumpEncodedVideo) {
        param["engine.video.video_dump_encode_video_mode"] = dumpModel.enableDumpEncodedVideo;
        param["engine.video.video_dump_encode_video_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpEncodedVideoMB);
      }
      //接收
      if (dumpModel.enableDumpDecodeVideo) {
        param["engine.video.video_dump_decode_video_mode"] = dumpModel.enableDumpDecodeVideo;
        param["engine.video.video_dump_decode_video_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpDecodeVideoMB);
      }
      if (dumpModel.enableDumpDecodedYUV) {
        param["engine.video.video_dump_decode_yuv_mode"] = dumpModel.enableDumpDecodedYUV;
        param["engine.video.video_dump_decode_yuv_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpDecodedYUVMB);
        param["engine.video.video_dump_decode_yuv_interval"] = this.translateVideoDumpInterval(dumpModel.dumpDecodedYUVInterval);
      }
      if (dumpModel.enableDumpPostProcessedYUV) {
        param["engine.video.video_dump_post_process_yuv_mode"] = dumpModel.enableDumpPostProcessedYUV;
        param["engine.video.video_dump_post_process_yuv_space"] = this.translateVideoDumpSpaceMB(dumpModel.maxSpaceForDumpPostProcessedYUVMB);
        param["engine.video.video_dump_post_process_yuv_interval"] = this.translateVideoDumpInterval(dumpModel.dumpPostProcessedYUVInterval);
      }
      NERtcSDK.getInstance().setParameters(param)
    }

    // other settings.
    if(otherModel) {
      let channelProfile = otherModel.channelProfile

      //下拉菜单的序号和定义的枚举类值不一致，这里做下调整
      if(channelProfile >= 2)
        channelProfile += 1

      let ret: number = NERtcSDK.getInstance().setChannelProfile(channelProfile)
      console.info(TAG, `setChannelProfile: ${ret}`)

      let mediaEncryptionIndex = otherModel.mediaEncryption
      let encryptionKey = otherModel.mediaEncryptionKey
      console.info(TAG, `mediaEncryption index: ${mediaEncryptionIndex}, encryptionKey: ${encryptionKey}`)

      if (mediaEncryptionIndex == 0) {
        //Disable.
        let ret = NERtcSDK.getInstance().enableEncryption(false)
        console.info(TAG, `Disable encryption, ret:${ret}`)
      } else if (mediaEncryptionIndex == 1) {
        //国密.
        let config: NERtcConstants.NERtcEncryptionConfig = {
          mode: NERtcConstants.EncryptionMode.GMCryptoSM4ECB,
          key: encryptionKey,
          observer: null
        }
        let ret = NERtcSDK.getInstance().enableEncryption(true, config)
        console.info(TAG, `Enable SM4ECB encryption, ret:${ret}`)
      } else if (mediaEncryptionIndex == 2) {
        //自定义加密.
        let observer: NERtcPacketObserver = new DemoNERtcPackageObserver()
        let config: NERtcConstants.NERtcEncryptionConfig = {
          mode: NERtcConstants.EncryptionMode.EncryptionModeCustom,
          key: encryptionKey,
          observer: observer
        }
        let ret = NERtcSDK.getInstance().enableEncryption(true, config)
        console.info(TAG, `Enable Custom encryption, ret:${ret}`)
      }
    }
  }

  private extendInitEngineTask = (): void => {
    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(audioModel) {
      //实时音量回调
      this.realTimeVolumeEnable(audioModel.captureVolumeEnable)
    }

    this.enableVoiceEffectIfNeeded()
    this.enableVirtualBackgroundIfNeeded()
  }

  private enableVirtualBackgroundIfNeeded()  : void {
    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    //是否打开
    let backData = new NERtcConstants.NERtcVirtualBackgroundSource()
    if (videoModel.virtualBackgroundEnable) {
      backData.backgroundSourceType = videoModel.virtualBackgroundType
      backData.color = videoModel.virtualBackgroundColor
      backData.blur_degree = videoModel.virtualBackgroundBlurDegree

      if (videoModel.virtualBackgroundSourceIndex == 0) {
        if(videoModel.virtualBackgroundSource && videoModel.virtualBackgroundSource.length > 0) {
          const splits = videoModel.virtualBackgroundSource.split('/')
          const fileName = splits[splits.length - 1]
          const lastPath = getContext().filesDir + "/media/" + fileName
          backData.source = lastPath
        }
      }
      else {
        let mediaDir = getContext(this).filesDir + "/media";
        let imageFilePath = mediaDir + "/" + "image_vb_sample_" + (videoModel.virtualBackgroundSourceIndex-1) + ".jpg";
        if (fs.accessSync(imageFilePath)) {
          backData.source = imageFilePath
        }
      }

      let force = videoModel.virtualBackgroundForce
      if(force) {
        console.info(TAG, 'User force open virtual background !!!')
      }

      NERtcSDK.getInstance().enableVirtualBackground(true, backData, force)
    }
    else {
      NERtcSDK.getInstance().enableVirtualBackground(false, backData)
    }
  }

  private enableVoiceEffectIfNeeded() : void {
    const audioEffectModel = this.rtcDemoLogicModel.GetPreferenceAudioEffectModel()
    if (audioEffectModel) {
      if (audioEffectModel.voiceChangerEffectsEnable) {
        NERtcSDK.getInstance().setAudioEffectPreset(audioEffectModel.voiceChangerEffectsType)
      }

      if (audioEffectModel.voiceBeautifierEffectsEnable) {
        NERtcSDK.getInstance().setVoiceBeautifierPreset(audioEffectModel.voiceBeautifierEffectsType)
      }

      if (audioEffectModel.voicePitchEnable) {
        NERtcSDK.getInstance().setLocalVoicePitch(audioEffectModel.voicePitch)
      }

      if (audioEffectModel.voiceReverbEnable) {
        let param: NERtcConstants.NERtcReverbParam = new NERtcConstants.NERtcReverbParam
        param.wetGain = audioEffectModel.wetGain
        param.dryGain = audioEffectModel.dryGain
        param.damping = audioEffectModel.damping
        param.roomSize = audioEffectModel.roomSize
        param.decayTime = audioEffectModel.decayTime
        param.preDelay = audioEffectModel.preDelay
        NERtcSDK.getInstance().setLocalVoiceReverbParam(param)
      }

      if (audioEffectModel.voiceEqualizationEnable) {
        NERtcSDK.getInstance().setLocalVoiceEqualization(0, audioEffectModel.band31)
        NERtcSDK.getInstance().setLocalVoiceEqualization(1, audioEffectModel.band62)
        NERtcSDK.getInstance().setLocalVoiceEqualization(2, audioEffectModel.band125)
        NERtcSDK.getInstance().setLocalVoiceEqualization(3, audioEffectModel.band250)
        NERtcSDK.getInstance().setLocalVoiceEqualization(4, audioEffectModel.band500)
        NERtcSDK.getInstance().setLocalVoiceEqualization(5, audioEffectModel.band1K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(6, audioEffectModel.band2K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(7, audioEffectModel.band4K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(8, audioEffectModel.band8K)
        NERtcSDK.getInstance().setLocalVoiceEqualization(9, audioEffectModel.band16K)
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

  clearCache(context: Context): void {
    let options: preferences.Options = { name: 'netease_settings' }
    let data = preferences.getPreferencesSync(getContext(), options)
    data.clearSync()
    Prompt.showToast({ message: '缓存清理成功' })
    this.rtcDemoLogicModel.LoadDataModel(context)
    this.release()
    this.init(context)
  }

  /**
   * 获取画布角度
   * @returns
   */
  GetCanvasBorderRadius(): number {
    return this.rtcDemoLogicModel.GetPreferenceOtherModel().canvasBorderRadius ?? 0
  }

  /**
   * 是否开启外部渲染
   * @returns
   */
  isExternalRender(): boolean {
    return this.rtcDemoLogicModel.GetPreferenceOtherModel().useExternalRender ?? false
  }

  join(login: LoginInfo): number {
    this.type = 0;
    try {
      NERtcSDK.getInstance().setStatsObserver({
        onRtcStats:(stats: NERtcConstants.NERtcStats): void =>{
          const MB_SIZE = 1024 * 1024
          let value = Number(stats.txBytes) / MB_SIZE
          const tx = value.toFixed(2)
          value = Number(stats.rxBytes) / MB_SIZE
          const rx = value.toFixed(2)

          let localRtcStats: string = `tx:${tx}MB, rx:${rx}MB cpu:${stats.cpuTotalUsage} v_lost:${stats.txVideoPacketLossRate} a_lost:${stats.txAudioPacketLossRate} upRtt:${stats.upRtt} downRtt:${stats.downRtt}`
          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            if (delegate.localRtcStats) {
              delegate.localRtcStats(localRtcStats)
            }
          })
        },

        onLocalAudioStats: (stats: NERtcConstants.NERtcAudioSendStats):void =>{
          let localAudioStat: string = ''
          stats.audioLayers?.forEach(stat => {
            let audioIndex = stat.streamType!!.valueOf() + 1
            localAudioStat += `a_${audioIndex}: ${stat.kbps}kbps vol:${stat.volume} cap_vol:${stat.capVolume} lost:${stat.lossRate} rtt:${stat.rtt}`
          })
          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            if (delegate.localAudioStats) {
              delegate.localAudioStats(localAudioStat)
            }
          })
        },

        onRemoteAudioStats: (statsArray: Array<NERtcConstants.NERtcAudioRecvStats>): void => {
          let maps: Map<bigint, string> = new Map
          statsArray?.forEach(info => {
            let remoteAudioStat: string = ''
            info.layers?.forEach(stat => {
              let audioIndex = stat.streamType!!.valueOf() + 1
              remoteAudioStat += `a_${audioIndex}: ${stat.kbps}kbps vol:${stat.volume} lost:${stat.lossRate} av_timestamp_diff:${stat.avTimestampDiff} peerToPeer:${stat.peerToPeerDelay}`
            })
            maps.set(info.uid, remoteAudioStat)
          })
          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            if (delegate.remoteAudioStats) {
              delegate.remoteAudioStats(maps)
            }
          })
        },

        onLocalVideoStats: (stats: NERtcConstants.NERtcVideoSendStats):void =>{

          let localVideoStat: string = ''
          let localVideoStat1: string = ''
          let localVideoStat2: string = ''
          stats.videoLayers?.forEach(stat => {
            if (stat.streamType == 1 || stat.streamType == 2) { //主视图 和 辅视图 显示在同一个窗口上
              localVideoStat += `cap: ${stat.capWidth}x${stat.capHeight} v${stat.streamType}: ${stat.width}x${stat.height}#${stat.encoderOutputFrameRate} enc:${stat.encoderBitrate} kbps encoderName:${stat.encoderName} bw:${stat.dropBwStrategyEnabled} \n`
            } else if (stat.streamType == 3) {
              localVideoStat1 = `cap: ${stat.capWidth}x${stat.capHeight} v${stat.streamType}: ${stat.width}x${stat.height}#${stat.encoderOutputFrameRate} enc:${stat.encoderBitrate} kbps encoderName:${stat.encoderName} bw:${stat.dropBwStrategyEnabled} \n`
            } else if (stat.streamType == 4) {
              localVideoStat2 = `cap: ${stat.capWidth}x${stat.capHeight} v${stat.streamType}: ${stat.width}x${stat.height}#${stat.encoderOutputFrameRate} enc:${stat.encoderBitrate} kbps encoderName:${stat.encoderName} bw:${stat.dropBwStrategyEnabled} \n`
            }
          })

          let maps: Map<number, string> = new Map
          if (localVideoStat !== '')
            maps.set(0, localVideoStat)
          if (localVideoStat1 !== '')
            maps.set(1, localVideoStat1)
          if (localVideoStat2 !== '')
            maps.set(2, localVideoStat2)

          if (maps.size == 0) return

          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            if (delegate.localVideoStats) {
              delegate.localVideoStats(maps)
            }
          })
        },

        onRemoteVideoStats: (statsArray: Array<NERtcConstants.NERtcVideoRecvStats>):void => {

          let maps: Map<bigint, Map<number, string>> = new Map
          statsArray?.forEach(info => {

            let remoteVideoStat: string = ''
            let remoteVideoStat1: string = ''
            let remoteVideoStat2: string = ''
            info.layers?.forEach((stat, index) => {
              if (stat.streamType == 1 || stat.streamType == 2) { //主视图 和 辅视图 显示在同一个窗口上
                remoteVideoStat += `v_${stat.streamType}: ${stat.width}x${stat.height}#${stat.fps} ${stat.receivedBitrate}kbps lost:${stat.packetLossRate} decoder:${stat.decoderName} peerToPeer:${stat.peerToPeerDelay}`
              } else if (stat.streamType == 3) {
                remoteVideoStat1 = `v_${stat.streamType}: ${stat.width}x${stat.height}#${stat.fps} ${stat.receivedBitrate}kbps lost:${stat.packetLossRate} decoder:${stat.decoderName} peerToPeer:${stat.peerToPeerDelay}`
              } else if (stat.streamType == 4) {
                remoteVideoStat2 = `v_${stat.streamType}: ${stat.width}x${stat.height}#${stat.fps} ${stat.receivedBitrate}kbps lost:${stat.packetLossRate} decoder:${stat.decoderName} peerToPeer:${stat.peerToPeerDelay}`
              }
            })

            let infos: Map<number, string> = new Map
            if (remoteVideoStat !== '') {
              infos.set(0, remoteVideoStat)
            }
            if (remoteVideoStat1 !== '') {
              infos.set(1, remoteVideoStat1)
            }
            if (remoteVideoStat2 !== '') {
              infos.set(2, remoteVideoStat2)
            }

            if (infos.size != 0) {
              maps.set(info.uid, infos)
            }
          })

          if (maps.size !== 0) {
            this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
              if (delegate.remoteVideoStats) {
                delegate.remoteVideoStats(maps)
              }
            })
          }
        },

        onNetworkQuality:(statsArray: Array<NERtcConstants.NERtcNetworkQualityInfo>):void => {

          let maps: Map<bigint, string> = new Map
          statsArray?.forEach(info => {
            let networkInfo = `network up:${info.upStatus} down:${info.downStatus}`
            maps.set(info.uid, networkInfo)
          })
          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            if (delegate.roomNetWorkQuality) {
              delegate.roomNetWorkQuality(maps)
            }
          })
        }
      })

      const otherModel = this.rtcDemoLogicModel.GetPreferenceOtherModel()
      if(otherModel) {
        /***
         * ################ setLocalPublishFallbackOption  ################
         * DISABLE: 上行网络较弱时，不对音视频流作回退处理，但不能保证音视频流的质量。
         * AUDIO_ONLY: 上行网络较弱时，只发布音频流。
         */
        let upFallbackOption = otherModel.upFallbackOption
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
        let downFallbackOption = otherModel.downFallbackOption
        if(downFallbackOption == 0) {
          streamOption = NERtcConstants.StreamFallbackOption.VIDEO_STREAM_LOW
        } else if(downFallbackOption == 1) {
          streamOption = NERtcConstants.StreamFallbackOption.AUDIO_ONLY
        }
        ret = NERtcSDK.getInstance().setRemoteSubscribeFallbackOption(streamOption)
        console.info(TAG, `setRemoteSubscribeFallbackOption ret:${ret}`)

        {
          //设置本地媒体优先级
          let listIndex = otherModel.mediaPriority
          let mediaPriority = -1
          if(listIndex == 0) {
            mediaPriority = NERtcConstants.MediaPriority.kNERtcMediaPriorityHigh
          } else if(listIndex == 1) {
            mediaPriority = NERtcConstants.MediaPriority.kNERtcMediaPriorityNormal
          }

          let mode = otherModel.isPreemptiveMode
          console.info(TAG, `Set preemptive mode: ${mode}`)
          if(mediaPriority != -1) {
            ret = NERtcSDK.getInstance().setLocalMediaPriority(mediaPriority, mode)
            console.info(TAG, `setLocalMediaPriority: ${mediaPriority}, ret:${ret}`)
          }
        }

        {
          //云代理相关的设置
          let listIndex = otherModel.cloudProxyOption
          let cloudProxyOption = NERtcConstants.NERtcTransportType.kNERtcTransportTypeNoneProxy
          if(listIndex == 1) {
            cloudProxyOption = NERtcConstants.NERtcTransportType.kNERtcTransportTypeUDPProxy
          }
          ret = NERtcSDK.getInstance().setCloudProxy(cloudProxyOption)
          console.info(TAG, `setCloudProxy: ${cloudProxyOption}, ret: ${ret}`)
        }
      }

      const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
      if(audioModel) {
        this.realTimeVolumeEnable(audioModel.captureVolumeEnable)
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
      const state = (ret == NERtcConstants.ErrorCode.NO_ERROR) ? ChatState.CHAT_ING : ChatState.CHAT_IDLE
      this.rtcDemoLogicModel.UpdateRtcRoomState(state)
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
    this.rtcDemoLogicModel.UpdateLocalDemoUser(null)
    this.enableBackgroundRunning(false);
  }

  private EnsureXComponentId(user: DemoUser, multiStream: "third" | "fourth" | null): string {
    let destXComponentId = user.xComponentIdMain
    if (multiStream != null && multiStream == "third") {
      destXComponentId = user.xComponentIdThird as string
    }
    if (multiStream != null && multiStream == "fourth") {
      destXComponentId = user.xComponentIdFourth as string
    }
    return destXComponentId
  }

  private EnsureStreamType(multiStream: "third" | "fourth" | null): NERtcConstants.NERtcVideoStreamType {
    let streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
    if (multiStream != null && multiStream == "third") {
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
    }
    if (multiStream != null && multiStream == "fourth") {
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
    }
    return streamType
  }

  detach(user: DemoUser, multiStream: "third" | 'fourth' | null): void {
    let useExternal = this.rtcDemoLogicModel.GetPreferenceOtherModel().useExternalRender
    if (useExternal) {
      let streamType = this.EnsureStreamType(multiStream)
      if(user.local) {
        let ret = NERtcSDK.getInstance().setLocalExternalVideoRender(streamType, null)
        console.info(TAG, `setLocalExternalVideoRender ret:${ret}`)
      } else {
        let ret = NERtcSDK.getInstance().setRemoteExternalVideoRender(user.uid, streamType, null)
        console.info(TAG, `setRemoteExternalVideoRender ret:${ret}`)
      }
    }
  }

  attach(user: DemoUser, multiStream: "third" | "fourth" | null): void {

    //fix issue for OMNRTCG2-58636
    if(login_ && login_.uid == '0') {
      login_.uid = user.uid.toString()
    }
    let isMe = user.uid.toString() === login_?.uid

    let useExternal = this.rtcDemoLogicModel.GetPreferenceOtherModel().useExternalRender
    if(!useExternal) {

      let scaleMode: number = NERtcConstants.NERtcVideoScalingMode.kNERtcVideoScaleFit
      const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
      if(videoModel) {
        scaleMode = videoModel.scaleMode
      }

      let mirrorMode = NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeAuto
      if (user.getCanvasMirror() != null) {
        mirrorMode = user.getCanvasMirror() ? NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeEnabled : NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeDisabled
      }
      let canvas: NERtcConstants.NERtcVideoCanvas = { canvasId: user.xComponentIdMain, scalingMode: scaleMode, mirrorMode: mirrorMode }
      if(multiStream != null && multiStream == "third"){
        canvas.canvasId = user.xComponentIdThird as string
      }else if(multiStream != null && multiStream == "fourth"){
        canvas.canvasId = user.xComponentIdFourth as string
      }

      let ret: number;
      if(isMe) {
        if(multiStream != null){
          let streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
          if(multiStream == "fourth")
            streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
          ret = NERtcSDK.getInstance().setupLocalVideoCanvas(canvas, streamType)
        }else {
          ret = NERtcSDK.getInstance().setupLocalVideoCanvas(canvas)
        }
      } else {
        if(multiStream != null){
          let streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
          if(multiStream == "fourth")
            streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
          ret = NERtcSDK.getInstance().setupRemoteVideoCanvas(canvas, user.uid, streamType)
        }else{
          ret = NERtcSDK.getInstance().setupRemoteVideoCanvas(canvas, user.uid)
        }
      }
      console.info(TAG, `uid:${user.uid} setup canvas ret:${ret}`)
    } else {

      //外部渲染逻辑
      if(this.videoRender == null)
        this.videoRender = new VideoRenderProcessing()

      if(isMe) {
        let destXComponentId: string = this.EnsureXComponentId(user, multiStream)
        console.info(TAG, `local xcomponment id: ${destXComponentId}`)
        let canvas: NERtcConstants.NERtcExternalVideoCanvas = {
          nativePlugin: this.videoRender!!.getRenderHandle(destXComponentId)
        }
        let ret = NERtcSDK.getInstance().setLocalExternalVideoRender(this.EnsureStreamType(multiStream), canvas)
        console.info(TAG, `setLocalExternalVideoRender: ${ret}`)
      } else {
        let destXComponentId: string = this.EnsureXComponentId(user, multiStream)
        console.info(TAG, `remote xcomponment id: ${destXComponentId}`)
        let canvas: NERtcConstants.NERtcExternalVideoCanvas = {
          nativePlugin: this.videoRender!!.getRenderHandle(destXComponentId)
        }
        let streamType = this.EnsureStreamType(multiStream)
        let ret = NERtcSDK.getInstance().setRemoteExternalVideoRender(user.uid, streamType, canvas)
        console.info(TAG, `setRemoteExternalVideoRender: uid:${user.uid}, ret:${ret}`)
      }
    }
  }

  attachSub(user: DemoUser): void {
    if(!user.xComponentIdSub) {
      return
    }
    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    let useExternal = this.rtcDemoLogicModel.GetPreferenceOtherModel().useExternalRender
    if(!useExternal) {
      let scaleMode: number = NERtcConstants.NERtcVideoScalingMode.kNERtcVideoScaleFit
      if(videoModel) {
        scaleMode = videoModel.scaleMode
      }

      let mirrorMode = NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeAuto
      if (user.getCanvasMirror() != null) {
        mirrorMode = user.getCanvasMirror() ? NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeEnabled : NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeDisabled
      }

      let canvas: NERtcConstants.NERtcVideoCanvas = { canvasId: user.xComponentIdSub,
        scalingMode: scaleMode, mirrorMode: mirrorMode }
      let ret:  number;
      if(user.local) {
        ret = NERtcSDK.getInstance().setupLocalSubStreamVideoCanvas(canvas)
      } else {
        ret = NERtcSDK.getInstance().setupRemoteSubStreamVideoCanvas(canvas, user.uid)
      }
      console.info(TAG, `uid:${user.uid}, setup sub canvas local:${user.local} ret:${ret}`)
    } else {
      //外部渲染逻辑
      if(this.videoRender == null)
        this.videoRender = new VideoRenderProcessing()

      let canvas: NERtcConstants.NERtcExternalVideoCanvas = {
        nativePlugin: this.videoRender!!.getRenderHandle(user.xComponentIdSub)
      }
      if (user.local) {
        let ret = NERtcSDK.getInstance().setLocalExternalVideoRender(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, canvas)
        console.info(TAG, `setLocalExternalVideoRender subStream, ret:${ret}`)
      } else {
        let ret = NERtcSDK.getInstance().setRemoteExternalVideoRender(user.uid, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, canvas)
        console.info(TAG, `setRemoteExternalVideoRender subStream, ret:${ret}`)
      }
    }
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

  startPushStreaming(login: LoginInfo) {
    const otherModel = this.rtcDemoLogicModel.GetPreferenceOtherModel()
    let config:NERtcConstants.NERtcPushStreamingConfig = new NERtcConstants.NERtcPushStreamingConfig
    config.url = this.pushAddressArray[otherModel.pushAddressIndex]
    console.info(TAG, `startPushStreaming config.url:${config.url}`)
    if(otherModel.pushAddress != "") {
      config.url = otherModel.pushAddress
    }
    LiveStreamingKit.getInstance().setPushAddress(config.url)
    LiveStreamingKit.getInstance().setPushStreamingConfig(config)
    LiveStreamingKit.getInstance().setServerRecord(otherModel.serverRecord)
    LiveStreamingKit.getInstance().setCdnPass(otherModel.cdnPass)
    login_ = login;
    config.streamingRoomInfo = new NERtcConstants.NERtcStreamingRoomInfo
    config.streamingRoomInfo.uid = BigInt(login.uid)
    config.streamingRoomInfo.channelName = login.cname
    config.streamingRoomInfo.token = login?.token ?? ""
    this.rtcDemoLogicModel.UpdatePushStreamUid(config.streamingRoomInfo.uid)
    this.type = 1;
    let ret: number = NERtcSDK.getInstance().startPushStreaming(config)
    console.log("liveStreamKit 开始单推")
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `开始融合推流`})
    } else {
      Prompt.showToast({ message: `融合推流失败:${ret}`})
    }
    return ret
  }

  stopPushStreaming() {
    let ret: number = NERtcSDK.getInstance().stopPushStreaming()
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `结束融合推流`})
    } else {
      Prompt.showToast({ message: `结束推流失败:${ret}`})
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

    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()
    if(localUser) {
      if(enabled && ret == NERtcConstants.ErrorCode.NO_ERROR) {
        localUser.xComponentIdSub = localUser.generatorSubCanvasId()
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser));
        })
      } else {
        localUser.xComponentIdSub = undefined
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser));
        })
      }
    }
  }

  enableThirdVideo(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalVideo(enabled, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird)
    console.info(TAG, `enableThirdVideo enabled:${enabled}, result:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地第三流视频:${enabled?'开':'关'}`})
    } else {
      Prompt.showToast({ message: `本地第三流视频操作失败:${ret}`})
      return;
    }
    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()
    let user = new DemoUser(localUser?.uid as bigint, true, "third");
    if(enabled) {
      this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
        delegate.update(OPERATOR.ADD, user);
      })
    }else{
      this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
        delegate.update(OPERATOR.DEL, user);
      })
    }
  }

  enableFourthVideo(enabled: boolean) {
    let ret: number = NERtcSDK.getInstance().enableLocalVideo(enabled, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth)
    console.info(TAG, `enableFourthVideo enabled:${enabled}, result:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `本地第四流视频:${enabled?'开':'关'}`})
    } else {
      Prompt.showToast({ message: `本地第四流视频操作失败:${ret}`})
    }

    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()
    let user = new DemoUser(localUser?.uid as bigint, true, "fourth");
    if(enabled) {
      this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
        delegate.update(OPERATOR.ADD, user);
      })
    }else{
      this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
        delegate.update(OPERATOR.DEL, user);
      })
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

  muteThirdVideo(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalVideo(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird, mute)
    console.info(TAG, `muteThirdVideo mute:${mute}, ret:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `第三流视频:${mute ? 'mute':'unmute'} ret:${ret}`})
    }
  }

  muteFourthVideo(mute: boolean) {
    let ret: number = NERtcSDK.getInstance().muteLocalVideo(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth, mute)
    console.info(TAG, `muteFourthVideo mute:${mute}, ret:${ret}`)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `第四流视频:${mute ? 'mute':'unmute'} ret:${ret}`})
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

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(!audioModel.audioMixUrl && !audioModel.audioMixPath) {
      Prompt.showToast({ message: '请设置伴音播放路径' })
      return
    }

    if(enabled) {
      let option: NERtcConstants.NERtcCreateAudioMixingOption = new NERtcConstants.NERtcCreateAudioMixingOption

      let lastPath: string
      if(audioModel.audioMixUrl.trim() != '') {
        lastPath = audioModel.audioMixUrl
      } else {
        const splits = audioModel.audioMixPath.split('/')
        const fileName = splits[splits.length - 1]
        lastPath = getContext().filesDir + "/media/" + fileName
      }

      option.path = lastPath
      option.loopCount = audioModel.audioMixLoopNum
      option.sendEnabled = audioModel.audioMixIsSend
      option.playbackEnabled = audioModel.audioMixIsPlay

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
    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    let ret: number = NERtcSDK.getInstance().setAudioMixingPitch(audioModel.audioMixPitch)
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置伴音音调失败':${ret}`})
    }
  }

  enableAudioEffect(enabled: boolean) {
    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(!audioModel.audioEffect1Url) {
      Prompt.showToast({ message: '请设置音效播放路径' })
      return
    }

    if(enabled) {
      const splits = audioModel.audioEffect1Url.split('/')
      const fileName = splits[splits.length - 1]
      const lastPath = getContext().filesDir + "/media/" + fileName

      let option: NERtcConstants.NERtcCreateAudioEffectOption = new NERtcConstants.NERtcCreateAudioEffectOption
      option.path = lastPath
      option.loopCount = audioModel.audioEffect1LoopNum
      option.sendEnabled = audioModel.audioEffect1IsSend
      option.playbackEnabled = audioModel.audioEffect1IsPlay

      let ret: number = NERtcSDK.getInstance().playEffect(1, option)
      console.info(TAG, `playEffect id:1, ret:${ret}`)
    } else {
      let ret: number = NERtcSDK.getInstance().stopEffect(1)
      console.info(TAG, `stopEffect id:1, ret:${ret}`)
    }
  }

  setAudioEffectPitch() {
    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    let ret: number = NERtcSDK.getInstance().setEffectPitch(1, audioModel.audioEffect1Pitch)
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `设置音调音调失败':${ret}`})
    }
  }

  enableScreenShare(enable: boolean) {
    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()
    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    if(enable) {
      let profile: number = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD1080P
      if(videoModel.screenSendResolution == 0) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileStandard
      } else if(videoModel.screenSendResolution == 1) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD720P
      } else if(videoModel.screenSendResolution == 2) {
        profile = NERtcConstants.NERtcVideoProfileType.kNERtcVideoProfileHD1080P
      }

      let frameRate: number = NERtcConstants.NERtcVideoFrameRate.kNERtcVideoFrameRateFps30
      switch (videoModel.screenFrameRate) {
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
      if (videoModel.screenMode == 1) {
        contentPrefer = NERtcConstants.NERtcSubStreamContentPrefer.kNERtcSubStreamContentPreferDetails;
      }
      let config: NERtcConstants.NERtcScreenConfiguration = new NERtcConstants.NERtcScreenConfiguration
      config.maxProfile = profile
      config.framerate = frameRate
      config.minFramerate = videoModel.screenMinFrameRate
      config.bitrate = videoModel.screenBitRate
      config.minBitrate = videoModel.screenMinBitRate
      config.contentPrefer = contentPrefer;

      let ret: number = NERtcSDK.getInstance().startScreenCapture(config)
      console.info(TAG, `startScreenCapture, ret: ${ret}`)

      if(ret == NERtcConstants.ErrorCode.NO_ERROR && localUser) {
        localUser.xComponentIdSub = localUser.generatorSubCanvasId()
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser));
        })
      }
    } else {
      let ret: number = NERtcSDK.getInstance().stopScreenCapture()
      console.info(TAG, `stopScreenCapture, ret: ${ret}`)
      if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
        if(localUser) {
          localUser.xComponentIdSub = undefined
          this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
            delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser));
          })
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
      }, 500)
    }
  }

  getSpeakerState() {
    let ret = NERtcSDK.getInstance().isSpeakerphoneOn()
    Prompt.showToast({ message: `扬声器状态:${ret ? '开':'关'}`})
  }

  enableAudioDump(enabled: boolean) {

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    let type: number = NERtcConstants.NERtcAudioDumpType.kNERtcAudioDumpTypeWAV
    if(audioModel) {
      type = audioModel.audioDumpType
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

  private ensureMediaStreamType(): number {
    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    let streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
    if(videoModel.previewStreamType == 0){
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
    }else if(videoModel.previewStreamType == 1){
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub
    }else if(videoModel.previewStreamType == 2){
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
    }else if(videoModel.previewStreamType == 3){
      streamType = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
    }
    return streamType
  }

  startPreview(login: LoginInfo) {
    login_ = login
    this.enableVirtualBackgroundIfNeeded()
    let streamType = this.ensureMediaStreamType()
    let ret: number = NERtcSDK.getInstance().startVideoPreview(streamType)
    Prompt.showToast({ message: `打开预览:${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
    this.enableBackgroundRunning(true);
  }

  stopPreview() {
    let streamType = this.ensureMediaStreamType()
    let ret: number = NERtcSDK.getInstance().stopVideoPreview(streamType)
    Prompt.showToast({ message: `关闭预览:${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
    this.enableBackgroundRunning(false)
  }

  getCurrentStreamType(): number {
    return this.rtcDemoLogicModel.GetPreferenceVideoModel().previewStreamType
  }

  takeSnapShot(user: DemoUser) {
    try {
      let streamType = '_main'
      if(user.multiStream == null){
        streamType = user.userCheckIsMainStream() ? '_main' : '_sub'
      }else{
        streamType = "_" + user.multiStream
      }
      let fileName = String(user.uid) + "_" + systemDateTime.getTime() + streamType + ".jpg"
      const path: string = getContext().filesDir + "/" + fileName + ".jpg"
      console.info(TAG, `path: ` + path)
      let streamTypeSnap = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
      if(user.multiStream == null){
        if(user.userCheckIsMainStream())
          streamTypeSnap = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
        else
          streamTypeSnap = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub
      }else{
        if(user.multiStream == "third")
          streamTypeSnap = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
        else
          streamTypeSnap = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
      }
      if(user.local) {
        NERtcSDK.getInstance().takeLocalSnapshot(streamTypeSnap, {
          onTakeSnapshotResult: (errorCode: number, image_?: PixelMap | undefined) => {
            this.saveSnapshotEncapsulation(errorCode, image_, path);
          }
        })
      } else {
        NERtcSDK.getInstance().takeRemoteSnapshot(user.uid, streamTypeSnap, {
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

    let useExternalRender = this.rtcDemoLogicModel.GetPreferenceOtherModel().useExternalRender

    let scaleMode = user.getScaleMode()
    if (!useExternalRender) {

      let mirrorMode = NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeAuto
      let mirror = user.getCanvasMirror()
      if (mirror != null) {
        mirrorMode = mirror ? NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeEnabled : NERtcConstants.NERtcVideoMirrorMode.kNERtcVideoMirrorModeDisabled
      }

      let streamTypeStyle = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
      if(user.multiStream == null){
        if(user.userCheckIsMainStream())
          streamTypeStyle = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain
        else
          streamTypeStyle = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub
      }else{
        if(user.multiStream == "third")
          streamTypeStyle = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird
        else
          streamTypeStyle = NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth
      }
      if(user.local) {
        if(streamTypeStyle == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain) {
          NERtcSDK.getInstance().setupLocalVideoCanvas({ canvasId: user.xComponentIdMain, mirrorMode: mirrorMode, scalingMode: scaleMode }, streamTypeStyle)
        }else if(streamTypeStyle ==  NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub) {
          NERtcSDK.getInstance().setupLocalSubStreamVideoCanvas({ canvasId: user.xComponentIdSub as string, mirrorMode: mirrorMode, scalingMode: scaleMode })
        }else if(streamTypeStyle ==  NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) {
          NERtcSDK.getInstance().setupLocalVideoCanvas({ canvasId: user.xComponentIdThird as string, mirrorMode: mirrorMode, scalingMode: scaleMode }, streamTypeStyle)
        }else if(streamTypeStyle == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) {
          NERtcSDK.getInstance().setupLocalVideoCanvas({ canvasId: user.xComponentIdFourth as string, mirrorMode: mirrorMode, scalingMode: scaleMode }, streamTypeStyle)
        }
      } else {
        if(user.userCheckIsMainStream()) {
          NERtcSDK.getInstance().setupRemoteVideoCanvas({ canvasId: user.xComponentIdMain, mirrorMode: mirrorMode, scalingMode: scaleMode }, user.uid, streamTypeStyle)
        } else {
          NERtcSDK.getInstance().setupRemoteSubStreamVideoCanvas({ canvasId: user.xComponentIdSub ?? '', mirrorMode: mirrorMode, scalingMode: scaleMode }, user.uid)
        }
      }
    } else {
      //外部渲染场景

      let mirrorMode = -1
      let mirror = user.getCanvasMirror()
      if (mirror != null) {
        mirrorMode = mirror ? 1 : 0
      }
      if (this.videoRender == null)
        this.videoRender = new VideoRenderProcessing()
      let xcomponment_id = user.userCheckIsMainStream() ? user.xComponentIdMain : user.xComponentIdSub
      this.videoRender.changeCanvasStyle(xcomponment_id, mirrorMode, scaleMode)
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

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(audioModel) {
      volumeDuration = audioModel.captureVolumeIndicationDuration
      vad = audioModel.captureVolumeVAD
    }

    let ret: number = NERtcSDK.getInstance().enableAudioVolumeIndication(enabled, BigInt(volumeDuration), vad)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR) {
      Prompt.showToast({ message: `实时音量${enabled?'开启':'关闭'}成功`})
    }
  }

  enablePushExternalAudioInput(enabled: boolean): boolean {

    //Fix crash for OMNRTCG2-58947.
    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(!audioModel.externalAudioInputUrl || audioModel.externalAudioInputUrl == '') {
      Prompt.showToast({ message: '请设置外部音频输入路径'})
      return false
    }

    if(audioModel.externalAudioInputChannelNum == 0 || audioModel.externalAudioInputSampleRate == 0) {
      Prompt.showToast({ message: '外部音频输入参数错误'})
      return false
    }

    if(enabled) {
      let inputFile = audioModel.externalAudioInputUrl.split("/")
      let fileName = inputFile[inputFile.length - 1]

      let type: number = NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeMain
      if(!this.externalAudioSourceMain) {
        this.externalAudioSourceMain = new ExternalPcmSource(Product.RTC_DEMO, type, fileName, audioModel.externalAudioInputSampleRate, audioModel.externalAudioInputChannelNum)
      }
      if(NERtcSDK.getInstance().enableLocalAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalAudioSource(true, audioModel.externalAudioInputSampleRate, audioModel.externalAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) {
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
      if(NERtcSDK.getInstance().setExternalAudioSource(false, audioModel.externalAudioInputSampleRate, audioModel.externalAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) {
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

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(audioModel.externalSubAudioInputUrl == '') {
      Prompt.showToast({ message: '请设置外部音频输入路径'})
      return false
    }

    if(audioModel.externalSubAudioInputSampleRate == 0 || audioModel.externalSubAudioInputChannelNum == 0) {
      Prompt.showToast({ message: '外部音频输入参数错误'})
      return false
    }

    if(enabled) {
      let inputFile = audioModel.externalSubAudioInputUrl.split("/")
      let fileName = inputFile[inputFile.length - 1]

      let type: number = NERtcConstants.NERtcAudioStreamType.kNERtcAudioStreamTypeSub
      if(!this.externalAudioSourceSub) {
        this.externalAudioSourceSub = new ExternalPcmSource(Product.RTC_DEMO, type, fileName, audioModel.externalSubAudioInputSampleRate, audioModel.externalSubAudioInputChannelNum)
      }
      if(NERtcSDK.getInstance().enableLocalSubStreamAudio(false) != NERtcConstants.ErrorCode.NO_ERROR) return false
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(true, audioModel.externalSubAudioInputSampleRate, audioModel.externalSubAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) return false
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
      if(NERtcSDK.getInstance().setExternalSubStreamAudioSource(false, audioModel.externalSubAudioInputSampleRate, audioModel.externalSubAudioInputChannelNum) != NERtcConstants.ErrorCode.NO_ERROR) return false
      this.externalAudioSourceSub?.stop()
      this.externalAudioSourceSub = null
      Prompt.showToast({ message: '外部音频辅流关闭成功'})
    }
    return true
  }

  enablePushExternalVideoInput(enabled: boolean): boolean {

    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    if(videoModel.externalVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(videoModel.externalVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }

    if(enabled) {

      let inputFile = videoModel.externalVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceMain) {
        this.externalVideoSourceMain = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain, fileName, videoModel.externalVideoWidth, videoModel.externalVideoHeight, videoModel.externalVideoFrameRate, videoModel.externalVideoRotation)
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

  sendSEI() {
    let sendMsg: string = '发送SEI:' + this.seiIndex++
    const encoder = new util.TextEncoder()
    let uint8Array = encoder.encodeInto(sendMsg)
    let ret = NERtcSDK.getInstance().sendSEIMsg(uint8Array, uint8Array.length)
    console.info(TAG, `SendSEIMsg: ret:${ret}`)
  }

  enableSubPushExternalVideoInput(enabled: boolean): boolean {

    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()

    if(videoModel.externalSubVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(videoModel.externalSubVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }

    if(enabled) {

      let inputFile = videoModel.externalSubVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceSub) {
        this.externalVideoSourceSub = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeSub, fileName, videoModel.externalSubVideoWidth, videoModel.externalSubVideoHeight, videoModel.externalSubVideoFrameRate, videoModel.externalSubVideoRotation)
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
      if(result && localUser) {
        Prompt.showToast({ message: '外部辅流视频输入开启成功' })
        let canvasId = localUser.generatorSubCanvasId();
        localUser.xComponentIdSub = canvasId
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser))
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
      if(localUser) {
        localUser.xComponentIdSub = undefined
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.UPD, DemoUser.newInstance(localUser))
        })
      }
    }
    return true
  }

  enableThirdPushExternalVideoInput(enabled: boolean): boolean {

    const multiVideoModel = this.rtcDemoLogicModel.GetPreferenceMultiVideoModel()
    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()

    if(multiVideoModel.externalThirdVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(multiVideoModel.externalThirdVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }
    let user = new DemoUser(localUser?.uid as bigint, true, "third");
    if(enabled) {

      let inputFile = multiVideoModel.externalThirdVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceThird) {
        this.externalVideoSourceThird = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird, fileName, multiVideoModel.externalThirdVideoWidth, multiVideoModel.externalThirdVideoHeight, multiVideoModel.externalThirdVideoFrameRate, multiVideoModel.externalThirdVideoRotation)
      }

      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) != NERtcConstants.ErrorCode.NO_ERROR){
        return false
      }

      if(NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }


      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.videoThirdEncodedSource) {
        this.videoThirdEncodedSource.stop()
        this.videoThirdEncodedSource = undefined
      }
      let result = this.externalVideoSourceThird.start()
      if(result && localUser) {
        Prompt.showToast({ message: '外部辅流视频输入开启成功' })
        let canvasId = localUser.generatorThirdCanvasId();
        localUser.xComponentIdThird = canvasId
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.ADD, user);
        })
      }
    } else {
      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      this.externalVideoSourceThird?.stop()
      this.externalVideoSourceThird = null
      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) == NERtcConstants.ErrorCode.NO_ERROR) {
        console.info(TAG, 'open camera success')
      }
      Prompt.showToast({ message: '外部辅流视频输入关闭成功'})
      if(localUser) {
        localUser.xComponentIdThird = undefined
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.DEL, user);
        })
      }
    }
    return true
  }

  enableFourthPushExternalVideoInput(enabled: boolean): boolean {

    const multiVideoModel = this.rtcDemoLogicModel.GetPreferenceMultiVideoModel()
    const localUser = this.rtcDemoLogicModel.GetLocalDemoUser()
    if(multiVideoModel.externalFourthVideoType != 0){
      Prompt.showToast({ message: '文件类型目前仅支持YUV420P'})
      return false
    }

    if(multiVideoModel.externalFourthVideoPath == '') {
      Prompt.showToast({ message: '请设置外部输入文件路径'})
      return false
    }
    let user = new DemoUser(localUser?.uid as bigint, true, "fourth");
    if(enabled) {

      let inputFile = multiVideoModel.externalFourthVideoPath.split('/')
      let fileName = inputFile[inputFile.length - 1]
      if(!this.externalVideoSourceFourth) {
        this.externalVideoSourceFourth = new ExternalYuvVideoSource(Product.RTC_DEMO, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth, fileName, multiVideoModel.externalFourthVideoWidth, multiVideoModel.externalFourthVideoHeight, multiVideoModel.externalFourthVideoFrameRate, multiVideoModel.externalFourthVideoRotation)
      }

      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) != NERtcConstants.ErrorCode.NO_ERROR){
        return false
      }

      if(NERtcSDK.getInstance().setExternalVideoSource(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }

      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }


      /**
       * @see Overmind-id: OMNRTCG2-57526
       */
      if(this.videoFourthEncodedSource) {
        this.videoFourthEncodedSource.stop()
        this.videoFourthEncodedSource = undefined
      }

      let result = this.externalVideoSourceFourth.start()
      if(result && localUser) {
        Prompt.showToast({ message: '外部辅流视频输入开启成功' })
        let canvasId = localUser.generatorFourthCanvasId();
        localUser.xComponentIdFourth = canvasId
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.ADD, user);
        })
      }
    } else {
      if(NERtcSDK.getInstance().enableLocalVideo(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      if(NERtcSDK.getInstance().setExternalVideoSource(false, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) != NERtcConstants.ErrorCode.NO_ERROR) {
        return false
      }
      this.externalVideoSourceFourth?.stop()
      this.externalVideoSourceFourth = null
      if(NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) == NERtcConstants.ErrorCode.NO_ERROR) {
        console.info(TAG, 'open camera success')
      }
      Prompt.showToast({ message: '外部辅流视频输入关闭成功'})
      if(localUser) {
        localUser.xComponentIdFourth = undefined
        this.rtcDemoLogicModel.GetDelegates().forEach(delegate => {
          delegate.update(OPERATOR.DEL, user);
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

  setRemoteAudioHighPriority(uid: bigint, enable: boolean) {
    let ret = NERtcSDK.getInstance().setRemoteHighPriorityAudioStream(enable, uid)
    Prompt.showToast({ message: `设置音频高优先级 uid:${uid}, enable:${enable}, ret:${ret}`})
  }

  enterPK(cname: string, remoteUid: string): number {
    let ret = LiveStreamingKit.getInstance().enterPK(cname, login_.token, login_.uid, remoteUid)
    return ret;
  }

  enterSeat(remoteUid: string): number {
    let ret = LiveStreamingKit.getInstance().enterSeat(login_.uid, remoteUid)
    return ret;
  }

  leavePK(): number {
    let ret = LiveStreamingKit.getInstance().leavePK()
    return ret;
  }

  leaveSeat(): number {
    let ret = LiveStreamingKit.getInstance().leaveSeat()
    return ret;
  }

  switchChannel(cname: string) {
    this.rtcDemoLogicModel.SetSwitchChannelName(cname)
    console.info(TAG, `switchChannel: ${cname}`)
    let ret = NERtcSDK.getInstance().switchChannel('', cname)
    Prompt.showToast({ message: `切换房间 cname: ${cname}, ret: ${ret}`})
  }

  aiManualInterrupt(dstUid: bigint) {
    let ret = NERtcSDK.getInstance().aiManualInterrupt(dstUid)
    Prompt.showToast({ message: `ai打断 uid: ${dstUid}, ret: ${ret}`})
  }

  switchCamera() {
    let ret: number = NERtcSDK.getInstance().switchCamera()
    Prompt.showToast({ message: `切换摄像头:${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
  }

  enableAudioFrameObserver(enable: boolean): void {

    const audioModel = this.rtcDemoLogicModel.GetPreferenceAudioModel()
    if(audioModel) {
      let format: NERtcConstants.NERtcAudioFrameRequestFormat = new NERtcConstants.NERtcAudioFrameRequestFormat
      format.channels = audioModel.audioCallbackChannel
      format.sampleRate = audioModel.audioCallbackSampleRate
      format.opMode = audioModel.audioCallbackReadOnly ? NERtcConstants.NERtcAudioFrameOpMode.kNERtcAudioFrameOpModeReadOnly : NERtcConstants.NERtcAudioFrameOpMode.kNERtcAudioFrameOpModeReadWrite
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

    const videoModel = this.rtcDemoLogicModel.GetPreferenceVideoModel()
    let index = 0
    if(videoModel) {
      index = videoModel.openVideoFrameObserverWays
    }

    if(index == 0) {
      //typescript
      if (enable) {
        this.videoFrameObserver.setFileDir(this.dir!);
        result = NERtcSDK.getInstance().setVideoFrameObserver(this.videoFrameObserver);
      } else {
        result = NERtcSDK.getInstance().setVideoFrameObserver(null);
        this.videoFrameObserver.clearUp();
      }
    } else {
      //c++
      if(this.videoProcess == null) {
        this.videoProcess = new VideoCaptureProcessing()
      }

      if(enable) {
        let filePath = this.dir! + "/VideoFrameObserver"
        console.info(TAG, `Last save file path: ${filePath}`)
        try {
          if(!fs.accessSync(filePath)) {
            fs.mkdirSync(filePath)
          }
        } catch (e) {
          console.error(TAG, `create folder failed: ${JSON.stringify(e)}`)
        }
        this.videoProcess.setFilePath(filePath)
        let ptr = this.videoProcess.getNativeHandle()
        console.info(TAG, `Get VideoProcess ptr: ${ptr.toString(16)}`)
        let result = NERtcSDK.getInstance().setExternalVideoProcessPlugin(ptr)
        console.info(TAG, `Set External video process plugin: ${result}`)
      } else {
        NERtcSDK.getInstance().setExternalVideoProcessPlugin(BigInt(0))
      }
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
    const otherModel = this.rtcDemoLogicModel.GetPreferenceOtherModel()
    if(enabled) {
      let upBitRate = otherModel.upLinkBitRate
      let downBitRate = otherModel.downLinkBitRate
      let upLinkProbe = otherModel.upLinkProbe
      let downLinkProbe = otherModel.downLinkProbe

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

  queryVirtualBackgroundSupport(): void {
    let result = NERtcSDK.getInstance().getFeatureSupportedType(NERtcConstants.NERtcFeatureType.VIRTUAL_BACKGROUND)
    if (result != NERtcConstants.ErrorCode.ENGINE_ERROR_INVALID_STATE) {
      if (result == NERtcConstants.NERtcFeatureSupportType.FEATURE_SUPPORT_FULL) {
        Prompt.showToast({ message: '虚拟背景支持'})
      } else if (result == NERtcConstants.NERtcFeatureSupportType.FEATURE_SUPPORT_HARDWARE_LIMIT) {
        Prompt.showToast({ message: '由于硬件原因，虚拟背景不支持'})
      } else if (result == NERtcConstants.NERtcFeatureSupportType.FEATURE_SUPPORT_PERFORMANCE_LIMIT) {
        Prompt.showToast({ message: '设备性能不足，但是您仍然可通过强制开启来打开'})
      }
    } else {
      Prompt.showToast({ message: '引擎状态错误!' })
    }
  }

  startMediaRelay(channelNames: Array<string>, update: boolean) {
    console.info(TAG, `startChannelMediaRelay, channelNames: ${channelNames}`)
    let destMediaInfoArray = new Array<NERtcConstants.NERtcChannelMediaRelayInfo>()
    channelNames.forEach(channel => {
      if (channel !== '') {
        let destMediaInfo: NERtcConstants.NERtcChannelMediaRelayInfo = {
          uid: BigInt(login_.uid),
          channelName: channel,
          token: ''
        }
        destMediaInfoArray.push(destMediaInfo)
      }
    })
    let config : NERtcConstants.NERtcChannelMediaRelayConfiguration = {
      destMediaInfoArray: destMediaInfoArray
    }
    let ret: number;
    if (update) {
      ret = NERtcSDK.getInstance().updateChannelMediaRelay(config)
      console.info(TAG, `updateChannelMediaRelay ret:${ret}`)
    } else {
      ret = NERtcSDK.getInstance().startChannelMediaRelay(config)
      console.info(TAG, `startChannelMediaRelay ret:${ret}`)
    }
  }

  stopMediaRelay() {
    let ret = NERtcSDK.getInstance().stopChannelMediaRelay()
    console.info(TAG, `stopChannelMediaRelay ret:${ret}`)
  }

  release() {
    NERtcSDK.getInstance().setStatsObserver(null)
    NERtcSDK.getInstance().release()
    console.info(TAG, 'Call release done.')
    this.rtcDemoLogicModel.UpdateLocalDemoUser(null)
    this.isAudioFrameObserverEnabled = false;
    this.isVideoFrameObserverEnabled = false;
    this.audioFrameObserver.clearUp();
    this.videoFrameObserver.clearUp();
  }

}
