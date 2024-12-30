import { ChatState } from "./ChatModel"
import UIDelegate from "./Delegate"
import { ArrayList } from "@kit.ArkTS"
import {
  AudioEffectModel,
  AudioModel, DumpModel, OtherModel, VideoModel, VideoModelMulti } from "../settings/model/common"
import { preferences } from "@kit.ArkData"
import { NERtcConstants } from "@nertc/nertc_sdk"
import * as ModelUtil from './ModelHandleUtils'
import Config from "../../common/Config"
import DemoUser from "../../model/DemoUser"

export default class RtcLogicModel {

  private TAG: string = 'RtcLogicModel'
  private roomState = ChatState.CHAT_IDLE
  private delegates: ArrayList<UIDelegate> = new ArrayList
  //切换房间名，暂存
  private switchChannelName: string|null = null
  private localUser: DemoUser|null = null
  private pushStreamingUid: bigint = BigInt(0)

  private audioModel: AudioModel|null = null
  private videoModel: VideoModel|null = null
  private videoModelMulti: VideoModelMulti|null = null
  private otherModel: OtherModel|null = null
  private dumpModel: DumpModel|null = null
  private audioEffectModel: AudioEffectModel|null = null

  //Demo safe mode.
  private safeMode: boolean = true
  private privateKey: string = ''
  private privateAddress: NERtcConstants.NERtcServerAddress|null = null
  private privateTokenUrl: string = ''

  LoadDataModel(context: Context) {
    let options: preferences.Options = { name: 'netease_settings' }
    let data = preferences.getPreferencesSync(context, options)

    let localAudioData = data.getSync('audioData', '') as string
    let localVideoData = data.getSync('videoData', '') as string
    let localVideoDataMulti = data.getSync('videoDataMulti', '') as string
    let localOtherData = data.getSync('otherData', '') as string
    let localDumpData = data.getSync('dumpData', '') as string
    let localAudioEffectData = data.getSync('audioEffectData', '') as string
    this.safeMode = data.getSync('safeMode', true) as boolean

    try {
      this.audioModel = JSON.parse(localAudioData)
      this.videoModel = JSON.parse(localVideoData)
      this.videoModelMulti = JSON.parse(localVideoDataMulti)
      this.otherModel = JSON.parse(localOtherData)
      this.dumpModel = JSON.parse(localDumpData)
      this.audioEffectModel = JSON.parse(localAudioEffectData)

    } catch (e) {
      console.info(this.TAG, JSON.stringify(e))
      this.audioModel = new AudioModel()
      this.videoModel = new VideoModel()
      this.videoModelMulti = new VideoModelMulti()
      this.otherModel = new OtherModel()
      this.dumpModel = new DumpModel()
      this.audioEffectModel = new AudioEffectModel()
    }

    try {
      //获取私有化地址
      this.privateAddress = JSON.parse(this.otherModel!!.privateAddress)
      //获取私有化appkey.
      this.privateKey = ModelUtil.GetJsonValue(this.privateAddress, 'appkey');
      //Demo token url.
      this.privateTokenUrl = ModelUtil.GetJsonValue(this.privateAddress, 'demoServer')
    } catch (e) {
      console.error(this.TAG, `Parse private address failed, reason:${JSON.stringify(e)}`)
      this.privateAddress = null
      this.privateKey = ''
      this.privateTokenUrl = ''
    }
  }

  UpdatePushStreamUid(uid: bigint) {
    this.pushStreamingUid = uid
  }

  GetPushStreamUid(): bigint {
    return this.pushStreamingUid
  }

  UpdateLocalDemoUser(user: DemoUser|null) {
    this.localUser = user
  }

  GetLocalDemoUser(): DemoUser|null {
    return this.localUser
  }

  GetDemoAppKey(): string {

    //Demo代码预埋的 appkey.
    let debug = this.GetDemoDebugMode()
    let appKey :string = debug ? Config.APP_KEY_DEBUG : Config.APP_KEY

    //如果用户配置了就用客户的
    if (this.otherModel && this.otherModel.appKey !== '') {
      appKey = this.otherModel.appKey
    }

    //如果配置了私有化的，则优先使用私有化的appkey.
    if (this.privateKey !== '') {
      appKey = this.privateKey
    }
    return appKey
  }

  GetDemoTokenUrl(): string {
    let debug = this.GetDemoDebugMode()
    let tokenUrl = debug ? Config.Demo_DEBUG_TOKEN_SERVER : Config.DEMO_TOKEN_SERVER
    if (this.privateTokenUrl !== '') {
      tokenUrl = this.privateTokenUrl
    }
    return tokenUrl
  }

  GetDemoSafeMode(): boolean {
    return this.safeMode
  }

  GetDemoDebugMode(): boolean {
    return this.otherModel?.debug ?? true //默认：测试环境
  }

  SaveDemoSaveMode(safeMode: boolean) : void {
    let options: preferences.Options = { name: 'netease_settings'}
    let data = preferences.getPreferencesSync(getContext(), options)
    data.putSync('safeMode', safeMode)
    this.safeMode = safeMode
  }

  GetPrivateAddress(): NERtcConstants.NERtcServerAddress|null {
    return this.privateAddress
  }

  GetPreferenceAudioModel(): AudioModel {
    return this.audioModel!!
  }

  GetPreferenceVideoModel(): VideoModel {
    return this.videoModel!!
  }

  GetPreferenceMultiVideoModel(): VideoModelMulti {
    return this.videoModelMulti!!
  }

  GetPreferenceOtherModel(): OtherModel {
    return this.otherModel!!
  }

  GetPreferenceDumpModel(): DumpModel {
    return this.dumpModel!!
  }

  GetPreferenceAudioEffectModel(): AudioEffectModel {
    return this.audioEffectModel!!
  }

  GetLastSwitchChannelName(): string|null {
    return this.switchChannelName
  }

  SetSwitchChannelName(channelName: string) {
    this.switchChannelName = channelName
  }

  GetRtcRoomState(): ChatState {
    return this.roomState
  }

  UpdateRtcRoomState(state: ChatState) {
    this.roomState = state
  }

  SetDelegate(delegate: UIDelegate) {
    if (!this.delegates.has(delegate)) {
      this.delegates.add(delegate)
      console.info(this.TAG, 'setDelegate size: ' + this.delegates.length)
    } else {
      console.info(this.TAG, 'delegate is exits.')
    }
  }

  RemoveDelegate(delegate: UIDelegate) {
    if (this.delegates.has(delegate)) {
      this.delegates.remove(delegate)
    } else {
      console.info(this.TAG, 'delegate not found.')
    }
  }

  GetDelegates(): ArrayList<UIDelegate> {
    return this.delegates
  }

}