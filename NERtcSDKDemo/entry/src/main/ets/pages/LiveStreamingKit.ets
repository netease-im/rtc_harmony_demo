import { NERtcConstants, NERtcSDK, NERtcCallbackEx} from '@nertc/nertc_sdk/Index';

export default class LiveStreamingKit{

  private static instance: LiveStreamingKit | null = null
  public static kPKStateIdle: number = 1
  public static kPKStateEnteringPK: number = 2
  public static kPKStateInPK: number = 3
  public static kPKStateLeavingPK: number = 4

  public static kSeatStateStateIdle: number = 1
  public static kSeatStateEnteringSeat: number = 2
  public static kSeatStateInSeat: number = 3
  public static kSeatStateLeavingSeat: number = 4

  private pkState: number = LiveStreamingKit.kPKStateIdle
  private seatState: number = LiveStreamingKit.kSeatStateStateIdle
  private pushAddress: string = ""
  private serverRecord: boolean = false
  private cdnPass: boolean = false
  private canvasWidth: number = 360
  private canvasHeight: number = 640
  private taskId: string = "1234567"
  private pushStreamConfig: NERtcConstants.NERtcPushStreamingConfig | undefined = undefined

  private constructor() {
    this.pkState = LiveStreamingKit.kPKStateIdle;
    this.seatState = LiveStreamingKit.kSeatStateStateIdle
  }

  static getInstance(): LiveStreamingKit {
    if (!LiveStreamingKit.instance) {
      LiveStreamingKit.instance = new LiveStreamingKit();
    }
    return LiveStreamingKit.instance
  }

  getPKState(): number {
    return this.pkState
  }

  getSeatState(): number {
    return this.seatState
  }

  setPushAddress(pushAddr: string) {
      this.pushAddress = pushAddr
  }

  setPushStreamingConfig(config: NERtcConstants.NERtcPushStreamingConfig) {
      this.pushStreamConfig = config;
  }

  setServerRecord(record: boolean) {
      this.serverRecord = record
  }

  setCdnPass(cdnPass: boolean) {
      this.cdnPass = cdnPass
  }

  stopLive() {
    NERtcSDK.getInstance().stopPushStreaming()
  }

  stopRelayAndRemoveLive() : number{
    let ret = NERtcSDK.getInstance().stopChannelMediaRelay()
    if(ret != 0){
      return -1
    }
    ret = NERtcSDK.getInstance().removeLiveStreamTask(this.taskId)
    console.log("liveStreamKit 停止旁路推流 ret:" + ret)
    this.pkState = LiveStreamingKit.kPKStateIdle
    console.log("liveStreamKit setPKState state:" + LiveStreamingKit.kPKStateIdle)
    if(ret != 0){
      return -1
    }
    return 0;
  }

  removeLive(): number {
    let ret = NERtcSDK.getInstance().removeLiveStreamTask(this.taskId)
    console.log("liveStreamKit 停止旁路推流 ret:" + ret)
    if(ret != 0){
      return -1
    }
    console.log("liveStreamKit setSeatState state:" + LiveStreamingKit.kPKStateIdle)
    this.seatState = LiveStreamingKit.kSeatStateStateIdle
    return 0;
  }

  clearPKAndSeat() {
    if(this.pkState != LiveStreamingKit.kPKStateIdle){
      this.stopRelayAndRemoveLive()
    }
    if(this.seatState != LiveStreamingKit.kSeatStateStateIdle){
      this.removeLive()
    }
  }

  createLiveStreamTaskInfo(remoteUid: string, localUid: string): NERtcConstants.NERtcLiveStreamTaskInfo {
    let info: NERtcConstants.NERtcLiveStreamTaskInfo = new NERtcConstants.NERtcLiveStreamTaskInfo
    info.taskID = this.taskId
    info.streamURL = this.pushAddress
    info.serverRecordEnabled = this.serverRecord
    info.lsMode = NERtcConstants.NERtcLiveStreamMode.kNERtcLsModeVideo

    let layout: NERtcConstants.NERtcLiveStreamLayout = new NERtcConstants.NERtcLiveStreamLayout
    info.layout = layout
    layout.width = this.canvasWidth * 2
    layout.height = this.canvasHeight * 2
    layout.backgroundColor = 0
    layout.users = []
    let localUser: NERtcConstants.NERtcLiveStreamUserTranscoding = new NERtcConstants.NERtcLiveStreamUserTranscoding
    localUser.uid = BigInt(localUid);
    localUser.x = 0
    localUser.y = 0
    localUser.videoPush = true
    localUser.audioPush = true
    localUser.width = this.canvasWidth
    localUser.height = this.canvasHeight
    layout.users?.push(localUser)

    let remoteUser: NERtcConstants.NERtcLiveStreamUserTranscoding = new NERtcConstants.NERtcLiveStreamUserTranscoding
    remoteUser.uid = BigInt(remoteUid);
    remoteUser.x = this.canvasWidth
    remoteUser.y = 0
    remoteUser.videoPush = true
    remoteUser.audioPush = true
    remoteUser.width = this.canvasWidth
    remoteUser.height = this.canvasHeight
    layout.users?.push(remoteUser)
    let sampleRate: number = NERtcConstants.NERtcLiveStreamAudioSampleRate.kNERtcLiveStreamAudioSampleRate44100
    let audioCodecProfile: number = NERtcConstants.NERtcLiveStreamAudioCodecProfile.kNERtcLiveStreamAudioCodecProfileLCAAC

    let config: NERtcConstants.NERtcLiveConfig = new NERtcConstants.NERtcLiveConfig
    config.singleVideoPassthrough = this.cdnPass
    config.sampleRate = sampleRate
    config.audioCodecProfile = audioCodecProfile

    info.config = config
    return info;
  }

  leaveSeat(): number {
    this.setSeatState(LiveStreamingKit.kPKStateLeavingPK)
    let ret = -1;
    if(this.pushStreamConfig != undefined) {
      ret = NERtcSDK.getInstance().startPushStreaming(this.pushStreamConfig)
      console.log("liveStreamKit 开始单推 ret:" + ret)
    }

    return ret

  }
  leavePK(): number {
    this.setPKState(LiveStreamingKit.kPKStateLeavingPK)
    //step1 开始cdn推流(startPushStreaming)
    let ret = -1;
    if(this.pushStreamConfig != undefined) {
      ret = NERtcSDK.getInstance().startPushStreaming(this.pushStreamConfig)
      console.log("liveStreamKit 开始单推 ret:" + ret)
    }

    return ret
    //step2 等待cdn推流结果回调(onStartPushStreaming)，
    //成功后停止mediaRelay(stopMediaRelay)和移除旁路推流任务(removeLiveStreamTask)

  }

  enterSeat(localUid: string, remoteUid: string): number {
    this.setSeatState(LiveStreamingKit.kPKStateEnteringPK)

    let liveStreamInfo: NERtcConstants.NERtcLiveStreamTaskInfo = this.createLiveStreamTaskInfo(remoteUid, localUid)
    let ret = NERtcSDK.getInstance().addLiveStreamTask(liveStreamInfo)
    console.log("liveStreamKit 开始旁路推流 ret:" + ret)
    if(ret != 0){
      console.log("liveStreamKit 旁路推流失败 ret:" + ret)
      return -1
    }
    return ret;
  }

  enterPK(channelName: string, token: string | undefined, localUid: string, remoteUid: string): number {
    this.setPKState(LiveStreamingKit.kPKStateEnteringPK)
    //step1 开始mediaRelay(startMediaRelay)
    let config: NERtcConstants.NERtcChannelMediaRelayConfiguration = new NERtcConstants.NERtcChannelMediaRelayConfiguration();
    let destMediaInfoArray: NERtcConstants.NERtcChannelMediaRelayInfo[] = [];

    let destMediaInfo: NERtcConstants.NERtcChannelMediaRelayInfo = {
      uid: BigInt(localUid),
      channelName: channelName,
      token: token == undefined ? "": token
    };
    destMediaInfoArray.push(destMediaInfo)

    config.destMediaInfoArray = destMediaInfoArray;
    let ret: number = NERtcSDK.getInstance().startChannelMediaRelay(config);
    console.log("liveStreamKit startChannelMediaRelay ret:" + ret)
    if(ret != 0){
      console.log("liveStreamKit startChannelMediaRelay failed ret:" + ret)
    }

    //step2 开启旁路推流任务(addLiveStream)
    let liveStreamInfo: NERtcConstants.NERtcLiveStreamTaskInfo = this.createLiveStreamTaskInfo(remoteUid, localUid)
    ret = NERtcSDK.getInstance().addLiveStreamTask(liveStreamInfo)
    console.log("liveStreamKit 开始旁路推流 ret:" + ret)
    if(ret != 0){
      console.log("liveStreamKit 旁路推流失败 ret:" + ret)
      return -1
    }
    //step3:等待旁路推流结果(onLiveStreamState)， 如果state为kNERtcLsStatePushing(505) 表示添加旁路任务成功，则停止cdn推流（stopPushStreaming）
    // step4:等待mediaRelay的结果(onNERtcEngineChannelMediaRelayStateDidChange:channelName:), 如果失败的话进行相应的重试操作
    return ret
  }

  setPKState(state: number){
    console.log("liveStreamKit setPKState state:" + state)
    this.pkState = state
  }

  setSeatState(state: number){
    console.log("liveStreamKit setSeatState state:" + state)
    this.seatState = state
  }
}