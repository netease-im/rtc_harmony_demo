// RtcDemoLogic + RtcDemoCallback 用于 sendable 对象与非 sendable 对象的交互
import { NERtcConstants } from '@nertc/nertc_sdk'

export interface IRtcDemoLogicDelegate {
  onJoinChannel: (result: number, channelId: bigint, elapsed: bigint, uid: bigint) => void;
  onLeaveChannel: (result: number)=> void;
  onUserJoined:(uid: bigint, extraInfo?: string)=> void;
  onUserLeave:(uid: bigint, reason: number, extraInfo?: string)=> void;
  onUserVideoStart:(uid: bigint, maxProfile: number)=> void;
  onUserVideoStop:(uid: bigint)=> void;
  onAudioMixingTimestampUpdate:(timestampMs: bigint)=> void;
  onAudioEffectTimestampUpdate:(id: number, timestampMs: bigint)=> void;
  onApiCallExecuted:(apiName: string, result: number, message: string)=> void;
  onFirstAudioFrameDecoded:(uid: bigint)=> void;
  onFirstVideoFrameDecoded:(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number)=> void;
  onUserSubStreamVideoStart:(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType)=>void;
  onUserSubStreamVideoStop:(uid: bigint)=>void;
  onLocalAudioVolumeIndication:(volume: number, vadFlag: boolean)=> void;
  onRemoteAudioVolumeIndication:(volumeArray: NERtcConstants.NERtcAudioVolumeInfo[], totalVolume: number)=> void;
  onLastMileProbeResult:(result: NERtcConstants.NERtcProbeResult) => void;
  onLastMileQuality:(quality: number) => void;
}

export class RtcDemoLogic {
  private static instance: RtcDemoLogic = new RtcDemoLogic();

  public static sharedInstance(): RtcDemoLogic {
    return RtcDemoLogic.instance;
  }

  private delegateList: Array<IRtcDemoLogicDelegate> = [];

  notifyOnJoinChannel(result: number, channelId: bigint, elapsed: bigint, uid: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onJoinChannel(result, channelId, elapsed, uid);
    });
  }

  notifyOnLeaveChannel(result: number): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onLeaveChannel(result);
    });
  }

  notifyOnUserJoined(uid: bigint, extraInfo?: string): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserJoined(uid, extraInfo);
    });
  }

  notifyOnUserLeave(uid: bigint, reason: number, extraInfo?: string): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserLeave(uid, reason, extraInfo);
    });
  }

  notifyOnUserVideoStart(uid: bigint, maxProfile: number): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserVideoStart(uid, maxProfile);
    });
  }

  notifyOnUserVideoStop(uid: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserVideoStop(uid);
    });
  }

  notifyOnAudioMixingTimestampUpdate(timestampMs: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onAudioMixingTimestampUpdate(timestampMs);
    });
  }

  notifyOnAudioEffectTimestampUpdate(id: number, timestampMs: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onAudioEffectTimestampUpdate(id, timestampMs);
    });
  }

  notifyOnApiCallExecuted(apiName: string, result: number, message: string): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onApiCallExecuted(apiName, result, message);
    });
  }

  notifyOnFirstAudioFrameDecoded(uid: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onFirstAudioFrameDecoded(uid)
    });
  }

  notifyOnFirstVideoFrameDecoded(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onFirstVideoFrameDecoded(streamType, userId, width, height)
    });
  }

  notifyOnUserSubStreamVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserSubStreamVideoStart(uid, maxProfile)
    });
  }

  notifyOnUserSubStreamVideoStop(uid: bigint): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onUserSubStreamVideoStop(uid)
    });
  }

  notifyOnLocalAudioVolumeIndication(volume: number, vadFlag: boolean): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onLocalAudioVolumeIndication(volume, vadFlag)
    });
  }

  notifyOnRemoteAudioVolumeIndication(volumeArray: NERtcConstants.NERtcAudioVolumeInfo[], totalVolume: number): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onRemoteAudioVolumeIndication(volumeArray, totalVolume)
    });
  }

  notifyOnLastmileQuality(quality: number):void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onLastMileQuality(quality)
    })
  }

  notifyOnLastmileProbeResult(result: NERtcConstants.NERtcProbeResult): void {
    this.delegateList.forEach((delegate: IRtcDemoLogicDelegate, index: number, delegateList: Array<IRtcDemoLogicDelegate>) => {
      delegate.onLastMileProbeResult(result)
    })
  }

  public addDelegate(delegate: IRtcDemoLogicDelegate): void {
    if (this.delegateList.indexOf(delegate) >= 0) {
      return;
    }

    this.delegateList.push(delegate);
  }

  public removeDelegate(delegate: IRtcDemoLogicDelegate): void {
    let index: number = this.delegateList.indexOf(delegate);
    if (index == -1) {
      return;
    }

    this.delegateList.splice(index, 1);
  }
}