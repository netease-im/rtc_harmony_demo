import ChatPresenter from '../Presenter1'
import { Prompt } from '@kit.ArkUI'
import { CallDetailDialog } from './CallDetailDialog';
import { SubDetailDialog } from './SubDetailDialog';
import { UI } from '../ChatModel';
import { WhiteBlackListDialog } from './WhiteBlackListDialog';
import { OtherModel } from '../../settings/model/common';
import { EditTextBaseDialog } from './EditTextBaseDialog';
import { MediaRelayDialog } from './MediaRelayDialog';
import { StartPKDialog } from './StartPKDialog';
import {StartSeatDialog} from './StartSeatDialog';
import LiveStreamingKit from '../../LiveStreamingKit';

export let gOtherModel: OtherModel

@Component
export struct MoreFunction {

  private TAG: string = 'MoreFunction'
  @Link uiType: UI

  @State mainVideoEnabled: boolean = false //主流视频开关
  @State subVideoEnabled: boolean = false //辅流视频开关
  @State thirdVideoEnabled: boolean = false //第三流视频开关
  @State fourthVideoEnabled: boolean = false //第四流视频开关
  @State mainVideoMute: boolean = false //主流视频mute
  @State subVideoMute: boolean = false //辅流视频mute
  @State thirdVideoMute: boolean = false //第三流视频mute
  @State fourthVideoMute: boolean = false //第四流视频mute
  @State mainAudioEnabled: boolean = false //主流音频开关
  @State subAudioEnabled: boolean = false //辅流音频开关
  @State mainAudioMute: boolean = false //主流音频静音开/关
  @State subAudioMute: boolean = false //辅流音频静音开/关
  @State localAudioPublished: boolean = false //本地音频发布开关

  @State encodeAudioEnabled: boolean = false  //音频裸流 开/关
  @State encodeSubAudioEnabled: boolean = false //音频辅流 开/关

  @State encodeVideoEnabled: boolean = false //视频裸流 开/关
  @State encodeSubVideoEnabled: boolean = false //辅流视频裸流开关
  @State earBackEnabled: boolean = false //耳返开关
  @State audioMixEnabled: boolean = false //伴音开关
  @State audioEffectEnable: boolean = false //音效开关
  @State screenShareEnable: boolean = false //屏幕共享
  @State speakerOnEnable: boolean = true //打开扬声器
  @State audioDumpEnable: boolean = false //audioDump
  @State externalMainAudioInputEnable: boolean = false //外部音频输入
  @State externalSubAudioInputEnable: boolean = false //外部辅流音频输入

  @State externalMainVideoInputEnable: boolean = false //外部视频输入
  @State externalSubVideoInputEnable: boolean = false //外部视频辅流输入
  @State externalThirdVideoInputEnable: boolean = false //第三流视频输入
  @State externalFourthVideoInputEnable: boolean = false //第四流视频辅流输入

  @State audioFrameObserverEnable: boolean = false; //音频数据回调
  @State videoFrameObserverEnable: boolean = false; //视频数据回调
  @State subscribeAllAudio: boolean = false //订阅/取消订阅所有用户音频
  @State enableAudioLoopBack: boolean = false //打开/关闭音频共享

  @State micMute: boolean = false //麦克风静音
  @State playoutDeviceMute: boolean = false //设置播放设备静音
  @State setRole: boolean = false //是否设置成观众

  @State captionMode: boolean = false
  @State startPKMode: boolean = false
  @State startSeatMode: boolean = false

  @State qosCallbackEnable: boolean = false //qos callback 回调
  @State preDecodeCallbackEnable: boolean = false //predecode callback 回调
  turnToSetting?: () => void;

  private fillStringToBigUint64Array(whiteBlackList: string|null): BigUint64Array|null {
    let array: BigUint64Array|null = null
    if(whiteBlackList) {
      let list = whiteBlackList.trim().split("#");
      if(list.length > 0) {
        array = new BigUint64Array(list.length)
        list.forEach((str, index) => {
          array?.fill(BigInt(str), index, index + 1)
        })
      }
    }
    return array
  }

  whiteBlackDialog: CustomDialogController = new CustomDialogController({
    builder: WhiteBlackListDialog({
      callback: (blackList: string|null, pubWhiteList:string|null, subWhiteList) => {
        let black_list_array = this.fillStringToBigUint64Array(blackList)
        let pub_white_list_array = this.fillStringToBigUint64Array(pubWhiteList)
        let sub_white_list_array = this.fillStringToBigUint64Array(subWhiteList)
        ChatPresenter.getInstance().setBlackWhiteList(black_list_array, pub_white_list_array, sub_white_list_array)
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  subscribeDialog: CustomDialogController = new CustomDialogController({
    builder: SubDetailDialog({
      title: '订阅/取消订阅',
      callback: (stream: number, type: number, dual: number, subscribe: boolean, uid?: bigint) => {
        if(uid !== undefined) {
          ChatPresenter.getInstance().subscribe(uid, stream, type, dual, subscribe)
          Prompt.showToast({ message: `${subscribe ? '订阅':'取消订阅'} uid:${uid} ${stream == 0 ? '音频':'视频'} ${type == 0 ? '主流':'辅流'}`, duration: 3000 })
        } else {
          Prompt.showToast({ message: '没有输入uid.'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  highPriorityDialog: CustomDialogController = new CustomDialogController({
    builder: EditTextBaseDialog({
      title: '设置音频高优先级',
      callback: (uid: string) => {
        if(uid !== undefined && uid !== '') {
          ChatPresenter.getInstance().setRemoteAudioHighPriority(BigInt(uid), true)
        } else {
          Prompt.showToast({ message: '没有输入uid.'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  switchChannelDialog: CustomDialogController = new CustomDialogController({
    builder: EditTextBaseDialog({
      title: '切换房间',
      callback: (cname: string) => {
        if(cname !== undefined && cname !== '') {
          ChatPresenter.getInstance().switchChannel(cname)
        } else {
          Prompt.showToast({ message: '没有填入cname'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  mBeginPKDialog: CustomDialogController = new CustomDialogController({
    builder: StartPKDialog({
      callback: (channelName: string, remoteUid: string) => {
        if(channelName !== undefined && channelName !== '') {
          channelName = channelName.trim()
          remoteUid = remoteUid.trim()
          let ret = ChatPresenter.getInstance().enterPK(channelName, remoteUid)
          if(ret == 0){
            this.startPKMode = true
          }else{
            this.startPKMode = false
          }
        } else {
          Prompt.showToast({ message: '没有填入channelName'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  mBeginSeatDialog: CustomDialogController = new CustomDialogController({
    builder: StartSeatDialog({
      callback: (remoteUid: string) => {
        if(remoteUid !== undefined && remoteUid !== '') {
          remoteUid = remoteUid.trim()
          let ret = ChatPresenter.getInstance().enterSeat(remoteUid)
          if(ret == 0){
            this.startSeatMode = true
          }else{
            this.startSeatMode = false
          }
        } else {
          Prompt.showToast({ message: '没有填入Uid'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })

  aiManualInterruptDialog: CustomDialogController = new CustomDialogController({
    builder: EditTextBaseDialog({
      title: 'ai打断 输入uid',
      callback: (uid: string) => {
        if(uid !== undefined && uid !== '') {
          ChatPresenter.getInstance().aiManualInterrupt(BigInt(uid))
        } else {
          Prompt.showToast({ message: '没有输入打断uid'})
        }
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    cornerRadius: 10
  })
  mediaRelayDialog: CustomDialogController = new CustomDialogController({
    builder: MediaRelayDialog({
      addCB: (input: string) => {
        let result = input.split("#")
        ChatPresenter.getInstance().startMediaRelay(result, false)
      },
      updateCB: (input: string) => {
        let result = input.split("#")
        ChatPresenter.getInstance().startMediaRelay(result, true)
      },
      stopCB: () => {
        ChatPresenter.getInstance().stopMediaRelay()
      },
      roleCB: (role: boolean) => {
        ChatPresenter.getInstance().setClientRole(role)
      }
    }),
    alignment: DialogAlignment.Center,
    width: '80%',
    height: '40%',
    cornerRadius: 10
  })

  build() {
    Grid(){

      if(this.uiType == UI.AUDIO) {

        GridItem() {
          Button(!this.mainAudioEnabled ? '主流音频开':'主流音频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableAudio(!this.mainAudioEnabled)
            this.mainAudioEnabled = !this.mainAudioEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.subAudioEnabled ? '辅流音频开':'辅流音频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableSubAudio(!this.subAudioEnabled)
            this.subAudioEnabled = !this.subAudioEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.mainAudioMute ? '主流音频Mute':'主流音频UnMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteAudio(!this.mainAudioMute)
            this.mainAudioMute = !this.mainAudioMute
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.subAudioMute ? '辅流音频Mute':'辅流音频UnMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteSubAudio(!this.subAudioMute)
            this.subAudioMute = !this.subAudioMute
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.localAudioPublished ? '发布音频':'停止发布', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().publishAudio(!this.localAudioPublished)
            this.localAudioPublished = !this.localAudioPublished
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.encodeAudioEnabled ? '主流裸流开' : "主流裸流关", { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            if(!this.encodeAudioEnabled) {
              let file = 'input_48k_ch2.opus'
              ChatPresenter.getInstance().enablePushAudioEncodeFrame(true, file)
            } else {
              ChatPresenter.getInstance().enablePushAudioEncodeFrame(false)
            }
            this.encodeAudioEnabled = !this.encodeAudioEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.encodeSubAudioEnabled ? '辅流裸流开':'辅流裸流关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            if(!this.encodeSubAudioEnabled) {
              let file = 'input_48k_ch2.opus'
              ChatPresenter.getInstance().enablePushSubAudioEncodeFrame(true, file)
            } else {
              ChatPresenter.getInstance().enablePushSubAudioEncodeFrame(false)
            }
            this.encodeSubAudioEnabled = !this.encodeSubAudioEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.earBackEnabled ? "耳返开" : "耳返关", { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableEarBack(!this.earBackEnabled)
            this.earBackEnabled = !this.earBackEnabled
            console.info(this.TAG, 'earBackEnabled : ' + this.earBackEnabled)
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.audioMixEnabled ? '伴音开':'伴音关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableAudioMix(!this.audioMixEnabled)
            this.audioMixEnabled = !this.audioMixEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('设置伴音音调', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().setAudioMixingPitch()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.audioEffectEnable ? '音效开':'音效关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableAudioEffect(!this.audioEffectEnable)
            this.audioEffectEnable = !this.audioEffectEnable
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('设置音效音调', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().setAudioEffectPitch()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.speakerOnEnable ? '扬声器开' : '扬声器关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableSpeakerOn(!this.speakerOnEnable)
            this.speakerOnEnable = !this.speakerOnEnable
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('扬声器状态', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().getSpeakerState()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.audioDumpEnable ? 'AudioDump开' : 'AudioDump关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableAudioDump(!this.audioDumpEnable)
            this.audioDumpEnable = !this.audioDumpEnable
          }).width('100%').height(50).fontSize(13).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalMainAudioInputEnable ? '音频主流输入开': '音频主流输入关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enablePushExternalAudioInput(!this.externalMainAudioInputEnable)
            this.externalMainAudioInputEnable = !this.externalMainAudioInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalSubAudioInputEnable ? '音频辅流输入开':'音频辅流输入关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enablePushSubExternalAudioInput(!this.externalSubAudioInputEnable)
            this.externalSubAudioInputEnable = !this.externalSubAudioInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.audioFrameObserverEnable ? '开音频数据回调': '关音频数据回调', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.audioFrameObserverEnable = !this.audioFrameObserverEnable
            ChatPresenter.getInstance().enableAudioFrameObserver(this.audioFrameObserverEnable);
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }
        
        GridItem() {
          Button(!this.subscribeAllAudio ? 'subAllAudio':'unsubAllAudio', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().subscribeAllAudio(!this.subscribeAllAudio)
            this.subscribeAllAudio = !this.subscribeAllAudio
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('设置黑白名单', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            this.whiteBlackDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.enableAudioLoopBack ? '打开音频共享':'关闭音频共享', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableLoopBack(!this.enableAudioLoopBack)
            this.enableAudioLoopBack = !this.enableAudioLoopBack
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.micMute ? '麦克风静音':'取消静音', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().setMicMute(!this.micMute)
            this.micMute = !this.micMute
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.playoutDeviceMute ? '播放设备静音':'取消静音', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().setPlayoutDeviceMute(!this.playoutDeviceMute)
            this.playoutDeviceMute = !this.playoutDeviceMute
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }
      }
      if(this.uiType == UI.VIDEO_MULTI) {
        GridItem() {
          Button(!this.thirdVideoEnabled ? '第三流开':'第三流关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableThirdVideo(!this.thirdVideoEnabled)
            this.thirdVideoEnabled = !this.thirdVideoEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.fourthVideoEnabled ? '第四流开':'第四流关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableFourthVideo(!this.fourthVideoEnabled)
            this.fourthVideoEnabled = !this.fourthVideoEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.thirdVideoMute ? '第三流Mute':'unMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteThirdVideo(!this.thirdVideoMute)
            this.thirdVideoMute = !this.thirdVideoMute
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.fourthVideoMute ? '第四流Mute':'UnMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteFourthVideo(!this.fourthVideoMute)
            this.fourthVideoMute = !this.fourthVideoMute
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalThirdVideoInputEnable ? '三流外部视频开': '三流外部视频关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableThirdPushExternalVideoInput(!this.externalThirdVideoInputEnable)
            this.externalThirdVideoInputEnable = !this.externalThirdVideoInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalFourthVideoInputEnable ? '四流外部视频开': '四流外部视频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableFourthPushExternalVideoInput(!this.externalFourthVideoInputEnable)
            this.externalFourthVideoInputEnable = !this.externalFourthVideoInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

      }
      if(this.uiType == UI.VIDEO) {

        GridItem() {
          Button(!this.mainVideoEnabled ? '主流视频开':'主流视频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableVideo(!this.mainVideoEnabled)
            this.mainVideoEnabled = !this.mainVideoEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.subVideoEnabled ? '辅流视频开':'辅流视频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableSubVideo(!this.subVideoEnabled)
            this.subVideoEnabled = !this.subVideoEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.mainVideoMute ? '主流视频Mute':'主流视频unMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteVideo(!this.mainVideoMute)
            this.mainVideoMute = !this.mainVideoMute
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.subVideoMute ? '辅流视频Mute':'辅流视频UnMute', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().muteSubVideo(!this.subVideoMute)
            this.subVideoMute = !this.subVideoMute
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.encodeVideoEnabled ? "视频裸流开" : "视频裸流关", { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            if(!this.encodeVideoEnabled) {
              let file = 'output.h264'
              ChatPresenter.getInstance().enablePushVideoEncodeFrame(true, file)
            } else {
              ChatPresenter.getInstance().enablePushVideoEncodeFrame(false)
            }
            this.encodeVideoEnabled = !this.encodeVideoEnabled
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.encodeSubVideoEnabled ? '辅流视频裸流开':'辅流视频裸流关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            if(!this.encodeSubVideoEnabled) {
              let file = 'output.h264'
              ChatPresenter.getInstance().enablePubSubVideoEncodedFrame(true, file)
            } else {
              ChatPresenter.getInstance().enablePubSubVideoEncodedFrame(false)
            }
            this.encodeSubVideoEnabled = !this.encodeSubVideoEnabled
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.screenShareEnable ? '屏幕共享开':'屏幕共享关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enableScreenShare(!this.screenShareEnable)
            this.screenShareEnable = !this.screenShareEnable
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalMainVideoInputEnable ? '外部主流视频开': '外部主流视频关', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().enablePushExternalVideoInput(!this.externalMainVideoInputEnable)
            this.externalMainVideoInputEnable = !this.externalMainVideoInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.externalSubVideoInputEnable ? '外部辅流视频开': '外部辅流视频关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableSubPushExternalVideoInput(!this.externalSubVideoInputEnable)
            this.externalSubVideoInputEnable = !this.externalSubVideoInputEnable
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button('切换摄像头', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().switchCamera()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.videoFrameObserverEnable ? '开视频数据回调': '关视频数据回调', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.videoFrameObserverEnable = !this.videoFrameObserverEnable
            ChatPresenter.getInstance().enableVideoFrameObserver(this.videoFrameObserverEnable);
          }).width('100%').height(50).fontSize(12).borderRadius(10)
        }

        GridItem() {
          Button(!this.qosCallbackEnable ? 'Qos回调开':'Qos回调关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enableQosCallback(!this.qosCallbackEnable)
            this.qosCallbackEnable = !this.qosCallbackEnable
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.preDecodeCallbackEnable ? '解码前处理开':'解码前处理关', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().enablePreDecodeCallback(!this.preDecodeCallbackEnable)
            this.preDecodeCallbackEnable = !this.preDecodeCallbackEnable
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('发送SEI', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().sendSEI()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }
      }

      if(this.uiType == UI.OTHER) {

        GridItem() {
          Button('会内设置', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            if(this.turnToSetting) this.turnToSetting()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('订阅', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.subscribeDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('上传日志', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().upload()
            Prompt.showToast({ message: 'upload log success.', duration: 2000 })
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('自定义上报', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
            ChatPresenter.getInstance().reportCustomEvent()
            Prompt.showToast({ message: '自定义上报成功，请查看qs'})
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.setRole ? '设置观众':'设置主播', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().setClientRole(!this.setRole)
            this.setRole = !this.setRole
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(!this.captionMode ? '开启字幕':'关闭字幕', {type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            ChatPresenter.getInstance().triggerCaptionMode(!this.captionMode)
            this.captionMode = !this.captionMode
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('ai打断', {type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.aiManualInterruptDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('音频高优先级', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.highPriorityDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('切换房间', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.switchChannelDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button('跨房间推流', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            this.mediaRelayDialog.open()
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

        GridItem() {
          Button(this.startPKMode ? '结束PK':'开始PK', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            if(this.startPKMode == false) {
              this.mBeginPKDialog.open()
            }else{
              let ret = ChatPresenter.getInstance().leavePK()
              if(ret == 0){
                this.startPKMode = false
              }else{
                this.startPKMode = true
              }
            }
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }
        GridItem() {
          Button(this.startSeatMode ? '结束连麦':'开始连麦', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
            if(this.startSeatMode == false) {
              this.mBeginSeatDialog.open()
            }else{
              let ret = ChatPresenter.getInstance().leaveSeat()
              if(ret == 0){
                this.startSeatMode = false
              }else{
                this.startSeatMode = true
              }
            }
          }).width('100%').height(50).fontSize(15).borderRadius(10)
        }

      }
    }.width('100%').height(250).columnsTemplate('1fr 1fr 1fr').backgroundColor(Color.Grey).columnsGap(5).rowsGap(5).padding(5)
  }
}