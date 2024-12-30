import { NERtcCallbackEx, NERtcConstants, NERtcSDK } from "@nertc/nertc_sdk";
import { ChatState, DemoLogicMap } from "./ChatModel";
import { OPERATOR } from "./Delegate";
import { Prompt } from "@kit.ArkUI";
import DemoUser from "../../model/DemoUser";
import LiveStreamingKit from "../LiveStreamingKit";
import { util } from '@kit.ArkTS';
import RtcLogicModel from './RtcLogicModel'

export default class RtcDefaultCallbackEx extends NERtcCallbackEx {

  private TAG: string = 'RtcDefaultCallbackEx'
  private logicModel: RtcLogicModel|null = null

  constructor(logicModel: RtcLogicModel) {
    super();
    this.logicModel = logicModel
  }

  onAddLiveStreamTask(taskId: string, url: string, errorCode: number): void {

  }
  onUpdateLiveStreamTask(taskId: string, url: string, errorCode: number): void {

  }
  onRemoveLiveStreamTask(taskId: string, errorCode: number): void {

  }

  onJoinChannel(result: number, channelId: bigint, elapsed: bigint, uid: bigint): void {
    const roomState = result == NERtcConstants.ErrorCode.NO_ERROR ? ChatState.CHAT_ED : ChatState.CHAT_IDLE;
    this.logicModel?.UpdateRtcRoomState(roomState)
    if(result == NERtcConstants.ErrorCode.NO_ERROR && this.logicModel?.GetLastSwitchChannelName()) {

      this.logicModel.GetDelegates().forEach(delegate => {
        const switchChannelName = this.logicModel?.GetLastSwitchChannelName()
        if(delegate.changeTitle && switchChannelName != null)
          delegate.changeTitle(switchChannelName)
      })
    }

    if (this.logicModel?.GetRtcRoomState() == ChatState.CHAT_ED) {
      let localUser = this.logicModel.GetLocalDemoUser()
      this.logicModel.GetDelegates().forEach(delegate => {
        if (!localUser) {
          localUser = new DemoUser(uid, true);
          this.logicModel?.UpdateLocalDemoUser(localUser)
        }
        delegate.update(OPERATOR.ADD, localUser);
      })
      const audioModel = this.logicModel.GetPreferenceAudioModel()
      const videoModel = this.logicModel.GetPreferenceVideoModel()
      setTimeout(() => {
        if (audioModel) {
          let ret: number = NERtcSDK.getInstance().enableLocalAudio(audioModel.autoOpenAudio);
          console.info(this.TAG, 'EnableLocalAudio: ' + ret);
        }
        if (videoModel) {
          let ret = NERtcSDK.getInstance().enableLocalVideo(true, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
          Prompt.showToast({ message: `本地主流视频打开${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
        }
        let ret = NERtcSDK.getInstance().setSpeakerphoneOn(true)
        if (ret == NERtcConstants.ErrorCode.NO_ERROR) {
          setTimeout(() => {
            let on: boolean = NERtcSDK.getInstance().isSpeakerphoneOn()
            console.info(this.TAG, 'isSpeakerphoneOn: ' + on)
          }, 500)
        }
      });
    } else {
      this.logicModel?.GetDelegates().forEach(delegate => {
        delegate.error('Join channel failed, result:' + result);
      })
    }
  }

  onLeaveChannel(result: number): void {
    this.logicModel?.UpdateRtcRoomState(ChatState.CHAT_IDLE)
    this.logicModel?.GetDelegates().forEach(delegate => {
      const localUser = this.logicModel?.GetLocalDemoUser()
      if (localUser) {
        delegate.update(OPERATOR.DEL, localUser)
      }
    })
  }

  onUserJoined(uid: bigint, extraInfo?: NERtcConstants.NERtcUserJoinExtraInfo | undefined): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      let user = new DemoUser(uid);
      delegate.update(OPERATOR.ADD, user);
    })
  }

  onUserLeave(uid: bigint, reason: number, extraInfo?: NERtcConstants.NERtcUserLeaveExtraInfo | undefined): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      let user = new DemoUser(uid);
      delegate.update(OPERATOR.DEL, user);
    })
  }

  onUserAudioStart(uid: bigint): void {
    Prompt.showToast({ message: `用户:${uid} 音频主流开启`, duration: 2000 })
  }

  onUserAudioMute(uid: bigint, muted: boolean): void {
    Prompt.showToast({ message: `用户:${uid} 主流音频${muted ? '静音':'取消静音'}`})
  }

  onUserAudioStop(uid: bigint): void {
    Prompt.showToast({ message: `用户:${uid} 音频主流关闭`, duration: 2000 })
  }

  onUserSubStreamAudioStart(uid: bigint): void {
    Prompt.showToast({ message: `用户${uid} 音频辅流开启`, duration: 2000 })
  }

  onUserSubStreamAudioStop(uid: bigint): void {
    Prompt.showToast({ message: `用户${uid} 音频辅流关闭`, duration: 2000 })
  }

  onUserSubStreamAudioMute(uid: bigint, muted: boolean): void {
    Prompt.showToast({ message: `用户${uid} 音频辅流${muted ? '静音':'取消静音'}`})
  }

  onUserVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType, streamType?: NERtcConstants.NERtcVideoStreamType): void {
    if(streamType == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) {
      this.logicModel?.GetDelegates().forEach(delegate => {
        let user = new DemoUser(uid, false, "third");
        delegate.update(OPERATOR.ADD, user);
      })
    }else if(streamType == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) {
      this.logicModel?.GetDelegates().forEach(delegate => {
        let user = new DemoUser(uid, false, "fourth");
        delegate.update(OPERATOR.ADD, user);
      })
    }
    Prompt.showToast({ message: `用户:${uid} streamType:${streamType} 视频流开启`})
  }

  onUserVideoMute(uid: bigint, muted: boolean, streamType?: NERtcConstants.NERtcVideoStreamType | undefined): void {
    Prompt.showToast({ message: `用户:${uid} streamType:${streamType} ${muted ? '静音':'取消静音'}`})
  }

  onUserVideoStop(uid: bigint, streamType?: NERtcConstants.NERtcVideoStreamType): void {
    if(streamType == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeThird) {
      this.logicModel?.GetDelegates().forEach(delegate => {
        let user = new DemoUser(uid, false, "third");
        delegate.update(OPERATOR.DEL, user);
      })
    }else if(streamType == NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeFourth) {
      this.logicModel?.GetDelegates().forEach(delegate => {
        let user = new DemoUser(uid, false, "fourth");
        delegate.update(OPERATOR.DEL, user);
      })
    }
    Prompt.showToast({ message: `用户${uid} streamType:${streamType} 视频流关闭`})
  }

  onDisconnect(reason: number): void {
    Prompt.showToast({ message: `onDisconnect reason:${reason}`})
  }

  onClientRoleChange(oldRole: number, newRole: number): void {
    Prompt.showToast({ message: `onClientRoleChange: role:${newRole == 0 ? '主播':'观众'}`})
  }

  onRecvSEIMsg(userId: bigint, data: Uint8Array, dataSize: number): void {
    const decoder = new util.TextDecoder('utf8')
    const str: string = decoder.decode(data)
    Prompt.showToast({ message: `Recv user:${userId} sei msg:${str}`})
  }

  onLocalVideoRenderSizeChanged(videoType: NERtcConstants.NERtcVideoStreamType, width: number, height: number): void {
    Prompt.showToast({
      message: `onLocalVideoRenderSizeChanged, videoType:${videoType}, width:${width}, height:${height}`
    });
  }
  onAsrCaptionStateChanged(state: NERtcConstants.NERtcAsrCaptionState, code: number, message: string): void {
    Prompt.showToast({
      message: `onAsrCaptionStateChanged, state:${state}, code:${code}, message:${message}`
    });
  }
  onAsrCaptionResult(asrResults: NERtcConstants.NERtcAsrCaptionResult[]): void {
    let message = ""
    for(let i = 0;i < asrResults.length;i++){
      message += "uid:" + asrResults[i].uid +" isLocalUser:" + asrResults[i].isLocalUser + " language:" + asrResults[i].language + " tLanguage:" + asrResults[i].translationLanguage + " content:" + asrResults[i].content + " translatedText:" + asrResults[i].translatedText
      message += "\n"
    }
    Prompt.showToast({
      message: `OnAsrCaptionResult, asrResults:${message}`
    });
  }
  onRemoteVideoSizeChanged(uid: bigint, videoType: NERtcConstants.NERtcVideoStreamType, width: number, height: number): void {
    Prompt.showToast({
      message: `onRemoteVideoSizeChanged, uid:${uid}, videoType:${videoType}, width:${width}, height:${height}`
    });
  }
  onUserSubStreamVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      let canvasId = DemoUser.GeneratorSubCanvasId(uid);
      let obj: Map<string, Object | undefined> = new Map;
      obj.set('uid', uid);
      obj.set('xComponentIdSub', canvasId);
      delegate.update(OPERATOR.UPD, obj);
    })
  }

  onUserSubStreamVideoMute(uid: bigint, muted: boolean): void {
    Prompt.showToast({ message: `onUserSubStreamVideoMute uid:${uid} ${muted ? '静音':'取消静音'}`})
  }

  onUserSubStreamVideoStop(uid: bigint): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      let obj: DemoLogicMap = new Map;
      obj.set('uid', uid);
      obj.set('xComponentIdSub', undefined);
      delegate.update(OPERATOR.UPD, obj);
    })
  }

  onLocalAudioVolumeIndication(volume: number, vadFlag: boolean): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      if (delegate.localVolume) {
        delegate.localVolume({
          volume: volume, vad: vadFlag
        });
      }
    })
  }

  onRemoteAudioVolumeIndication(volumeInfo: NERtcConstants.NERtcAudioVolumeInfo[], totalVolume: number): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      if (delegate.remoteVolume) {
        delegate.remoteVolume(volumeInfo, totalVolume);
      }
    })
  }

  onLastmileProbeResult(result: NERtcConstants.NERtcProbeResult): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      if(delegate.networkQuality) {
        delegate.networkQuality(null, result)
      }
    })
  }

  onLabFeatureCallback(key: string, param: string): void {
  }

  onPushStreamingReconnectedSuccess(): void {
    Prompt.showToast({
      message: `onPushStreamingReconnectedSuccess` , duration: 2000
    });
  }

  onPushStreamingReconnecting(reason: number): void {
    Prompt.showToast({
      message: `onPushStreamingReconnecting reason: ${reason}` , duration: 2000
    });
  }

  onLiveStreamState(taskId: string, url: string, stateCode: number): void {
    if(stateCode == NERtcConstants.LiveStreamState.STATE_PUSHING) {
      if(LiveStreamingKit.getInstance().getPKState() == LiveStreamingKit.kPKStateEnteringPK){
        LiveStreamingKit.getInstance().stopLive()
        LiveStreamingKit.getInstance().setPKState(LiveStreamingKit.kPKStateInPK)
        console.log("liveStreamKit 停止单推")
      }
      if(LiveStreamingKit.getInstance().getSeatState() == LiveStreamingKit.kSeatStateEnteringSeat) {
        LiveStreamingKit.getInstance().stopLive()
        LiveStreamingKit.getInstance().setSeatState(LiveStreamingKit.kSeatStateInSeat)
        console.log("liveStreamKit 停止单推")
      }
    }
  }

  onStartPushStreaming(result: number, channelId: bigint): void {
    console.log("liveStreamKit getPKState: " + LiveStreamingKit.getInstance().getPKState() + " getSeatState: " + LiveStreamingKit.getInstance().getSeatState())
    if(LiveStreamingKit.getInstance().getPKState() == LiveStreamingKit.kPKStateIdle && LiveStreamingKit.getInstance().getSeatState() == LiveStreamingKit.kSeatStateStateIdle) {
      let roomState = result == NERtcConstants.ErrorCode.NO_ERROR ? ChatState.CHAT_ED : ChatState.CHAT_IDLE;
      this.logicModel?.UpdateRtcRoomState(roomState)

      let pushStreamUid = this.logicModel?.GetPushStreamUid() ?? 0n
      if (roomState == ChatState.CHAT_ED) {

        let localUser = this.logicModel?.GetLocalDemoUser()
        if (pushStreamUid > 0n) {
          this.logicModel?.GetDelegates().forEach(delegate => {
            if (!localUser) {
              localUser = new DemoUser(pushStreamUid, true);
              this.logicModel?.UpdateLocalDemoUser(localUser)
            }
            delegate.update(OPERATOR.ADD, localUser);
          })
        }

        const audioModel = this.logicModel?.GetPreferenceAudioModel()
        const videoModel = this.logicModel?.GetPreferenceVideoModel()
        setTimeout(() => {
          if (audioModel) {
            let ret: number = NERtcSDK.getInstance().enableLocalAudio(audioModel.autoOpenAudio);
            console.info(this.TAG, 'EnableLocalAudio: ' + ret);
          }
          if (videoModel) {
            let ret = NERtcSDK.getInstance().enableLocalVideo(videoModel.autoEnableVideo, NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
            Prompt.showToast({ message: `打开主流视频${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
          }

          let ret = NERtcSDK.getInstance().setSpeakerphoneOn(true)
          Prompt.showToast({ message: `打开音频${ret == NERtcConstants.ErrorCode.NO_ERROR ? '成功':'失败'}`})
        });
      } else {
        this.logicModel?.GetDelegates().forEach(delegate => {
          delegate.error('Join channel failed, result:' + result)
        })
      }
      Prompt.showToast({
        message: `onStartPushStreaming result: ${result} + channelId: ${channelId}`, duration: 2000
      });
    }else {
      if(LiveStreamingKit.getInstance().getPKState() != LiveStreamingKit.kPKStateIdle){
        LiveStreamingKit.getInstance().stopRelayAndRemoveLive()
      }

      if(LiveStreamingKit.getInstance().getSeatState() != LiveStreamingKit.kSeatStateStateIdle){
        LiveStreamingKit.getInstance().removeLive()
      }
    }
  }
  onStopPushStreaming(result: number): void {
    Prompt.showToast({
      message: `onStopPushStreaming result: ${result}` , duration: 2000
    });
  }
  onLastmileQuality(quality: number): void {
    this.logicModel?.GetDelegates().forEach(delegate => {
      if (delegate.networkQuality) {
        delegate.networkQuality(quality, null)
      }
    })
  }

  onVirtualBackgroundSourceEnabled(enabled: boolean, reason: number): void {
    console.info(this.TAG, `onVirtualBackgroundSourceEnabled, enabled:${enabled}, reason:${reason}`);
    Prompt.showToast({
      message: `onVirtualBackgroundSourceEnabled, enabled:${enabled}, reason:${reason}` , duration: 3000
    });
  }

  onVideoDeviceStateChanged(deviceState: number): void {
    console.info(this.TAG, `onVideoDeviceStateChanged: deviceState:${deviceState}`)
  }

  onMediaRelayStatesChange(state: number, channelName: string): void {
    console.info(this.TAG, `onMediaRelayStatesChange state:${state}, channelName:${channelName}`)
  }

  onMediaRelayReceiveEvent(event: number, code: number, channelName: string): void {
    console.info(this.TAG, `onMediaRelayReceiveEvent event:${event}, code:${code}, channelName:${channelName}`)
  }

  onFirstAudioDataReceived(uid: bigint): void {
    console.info(this.TAG, `onFirstAudioDataReceived uid:${uid}`)
    Prompt.showToast({ message: `uid:${uid} first audio data received.`, duration: 2000 })
  }

  onFirstAudioFrameDecoded(uid: bigint): void {
    console.info(this.TAG, `onFirstAudioFrameDecoded uid:${uid}`)
    Prompt.showToast({
      message: `onFirstAudioFrameDecoded uid:${uid}`
    });
  }

  onFirstVideoDataReceived(streamType: NERtcConstants.NERtcVideoStreamType, uid: bigint): void {
    console.info(this.TAG, `onFirstVideoDataReceived uid:${uid}, streamType:${streamType}`)
    Prompt.showToast({ message: `uid:${uid} first video data received, streamType:${streamType}`})
  }

  onFirstVideoFrameDecoded(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number): void {
    console.info(this.TAG, `onFirstVideoFrameDecoded uid:${userId}, streamType:${streamType} ${width}x${height}`)
    Prompt.showToast({
      message: `onFirstVideoFrameDecoded, streamType:${streamType}, uid:${userId}, width:${width}, height:${height}`
    });
  }

  onFirstVideoFrameRender(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number, elapsedTime: bigint): void {
    console.info(this.TAG, `onFirstVideoFrameRender uid:${userId}, streamType:${streamType}, width:${width}xheight:${height}`)
    Prompt.showToast({ message: `uid:${userId} first video frame render, width:${width}, height:${height}`})
  }

}