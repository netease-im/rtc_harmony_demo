// RtcDemoLogic + RtcDemoCallback 用于 sendable 对象与非 sendable 对象的交互

import { NERtcCallbackEx, NERtcConstants, NERtcAudioFrameObserver, NERtcVideoFrameObserver } from 'sdk'
import { RtcDemoLogic } from './RtcDemoLogic'
import RtcDemoFileManager, { RtcDemoFileInfo } from './RtcDemoFileManager';
import RtcDemoTimeUtil from './RtcDemoTimeUtil'
import { collections } from '@kit.ArkTS'

// @Sendable
export class RtcDemoCallback extends NERtcCallbackEx {
  protected tag: string = "RtcDemoCallback";

  constructor(tag: string) {
    super();
    this.tag = this.tag + "_" + tag;
  }

  onJoinChannel(result: number, channelId: bigint, elapsed: bigint, uid: bigint): void {
    console.info(this.tag, "onJoinChannel, result:" + result + ", channelId:" + channelId + ", elapsed:" + elapsed + ", uid:" + uid);
    RtcDemoLogic.sharedInstance().notifyOnJoinChannel(result, channelId, elapsed, uid);
  }

  onLeaveChannel(result: number): void {
    console.info(this.tag, "onLeaveChannel, result:" + result);
    RtcDemoLogic.sharedInstance().notifyOnLeaveChannel(result);
  }

  onUserJoined(uid: bigint, extraInfo?: NERtcConstants.NERtcUserJoinExtraInfo | undefined): void {
    console.info(this.tag, "onUserJoined, uid:" + uid);
    RtcDemoLogic.sharedInstance().notifyOnUserJoined(uid, extraInfo?.customInfo);
  }

  onUserLeave(uid: bigint, reason: number, extraInfo?: NERtcConstants.NERtcUserLeaveExtraInfo | undefined): void {
    console.info(this.tag, "onUserLeave, uid:" + uid);
    RtcDemoLogic.sharedInstance().notifyOnUserLeave(uid, reason, extraInfo?.customInfo);
  }

  onUserAudioStart(uid: bigint): void {
    console.info(this.tag, "onUserAudioStart, uid:" + uid);
  }

  onUserAudioStop(uid: bigint): void {
    console.info(this.tag, "onUserAudioStop, uid:" + uid);
  }

  onUserVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {
    console.info(this.tag, "onUserVideoStart, uid:" + uid, ", profile:" + maxProfile);
    RtcDemoLogic.sharedInstance().notifyOnUserVideoStart(uid, maxProfile);
  }

  onUserVideoStop(uid: bigint): void {
    console.info(this.tag, "onUserVideoStop, uid:" + uid);
    RtcDemoLogic.sharedInstance().notifyOnUserVideoStop(uid);
  }

  onDisconnect(reason: number): void {
    console.info(this.tag, "onDisconnect, reason:" + reason);
  }

  onClientRoleChange(oldRole: number, newRole: number): void {
    console.info(this.tag, "onClientRoleChange, oldRole:" + oldRole + ", newRole:" + newRole);
  }

  onRecvSEIMsg(userId: bigint, data: Uint8Array, dataSize: number): void {
    console.info(this.tag, `onRecvSEIMsg, uid:${userId}, data:${data.toString()}, dataSize:${dataSize}`);
  }

  onAudioMixingTimestampUpdate(timestampMs: bigint): void {
    RtcDemoLogic.sharedInstance().notifyOnAudioMixingTimestampUpdate(timestampMs);
  }

  onAudioEffectTimestampUpdate(id: number, timestampMs: bigint): void {
    RtcDemoLogic.sharedInstance().notifyOnAudioEffectTimestampUpdate(id, timestampMs);
  }

  onApiCallExecuted(apiName: string, result: number, message: string): void {
    RtcDemoLogic.sharedInstance().notifyOnApiCallExecuted(apiName, result, message);
  }

  onFirstAudioFrameDecoded(uid: bigint): void {
    RtcDemoLogic.sharedInstance().notifyOnFirstAudioFrameDecoded(uid)
  }

  onFirstVideoFrameDecoded(streamType: NERtcConstants.NERtcVideoStreamType, userId: bigint, width: number, height: number): void {
    RtcDemoLogic.sharedInstance().notifyOnFirstVideoFrameDecoded(streamType, userId, width, height)
  }

  onUserSubStreamVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType): void {
    RtcDemoLogic.sharedInstance().notifyOnUserSubStreamVideoStart(uid, maxProfile)
  }

  onUserSubStreamVideoStop(uid: bigint): void {
    RtcDemoLogic.sharedInstance().notifyOnUserSubStreamVideoStop(uid)
  }

  onLocalAudioVolumeIndication(volume: number, vadFlag: boolean): void {
    RtcDemoLogic.sharedInstance().notifyOnLocalAudioVolumeIndication(volume, vadFlag)
  }

  onRemoteAudioVolumeIndication(volumeInfo: NERtcConstants.NERtcAudioVolumeInfo[], totalVolume: number): void {
    RtcDemoLogic.sharedInstance().notifyOnRemoteAudioVolumeIndication(volumeInfo, totalVolume)
  }

  onLastmileQuality(quality: number): void {
    console.log(this.tag, `quality:${quality}`);
    RtcDemoLogic.sharedInstance().notifyOnLastmileQuality(quality)
  }

  onLastmileProbeResult(result: NERtcConstants.NERtcProbeResult): void {
    console.log(this.tag, `rtt:${result.rtt}, state:${result.type},
    up_jitter:${result.upLinkResult?.jitter},
    up_packet_loss_rate:${result.upLinkResult?.packetLossRate},
    up_available_band_width:${result.upLinkResult?.availableBandWidth},
    down_jitter:${result.downLinkResult?.jitter},
    down_packet_loss_rate:${result.downLinkResult?.packetLossRate},
    down_available_band_width:${result.downLinkResult?.availableBandWidth}`);
    RtcDemoLogic.sharedInstance().notifyOnLastmileProbeResult(result)
  }
}

@Sendable
export class RtcDemoAudioFrameObserver implements NERtcAudioFrameObserver {
  protected tag: string = "RtcDemoAudioFrameObserver";
  private file_info_local_record: RtcDemoFileInfo|null = null;
  private file_info_local_playback: RtcDemoFileInfo|null = null;
  private file_info_local_remote_mixed: RtcDemoFileInfo|null = null;
  private file_info_map_remote_user_before_mixing: collections.Map<string, RtcDemoFileInfo>|null = null;
  private file_info_local_record_sub: RtcDemoFileInfo|null = null;
  private file_info_map_remote_user_before_mixing_sub: collections.Map<string, RtcDemoFileInfo>|null = null;
  private file_dir: string = "";

  constructor(tag: string) {
    this.tag = this.tag + "_" + tag;
  }

  public clearUp(): void {
    this.file_dir = "";

    if (this.file_info_map_remote_user_before_mixing) {
      this.file_info_map_remote_user_before_mixing.forEach((value: RtcDemoFileInfo, key: string, map: collections.Map<string, RtcDemoFileInfo>) => {
        RtcDemoFileManager.sharedInstance().closeFile(value.fd);
      });
      this.file_info_map_remote_user_before_mixing.clear();
      this.file_info_map_remote_user_before_mixing = null;
    }
    if (this.file_info_map_remote_user_before_mixing_sub) {
      this.file_info_map_remote_user_before_mixing_sub.forEach((value: RtcDemoFileInfo, key: string, map: collections.Map<string, RtcDemoFileInfo>) => {
        RtcDemoFileManager.sharedInstance().closeFile(value.fd);
      });
      this.file_info_map_remote_user_before_mixing_sub.clear();
      this.file_info_map_remote_user_before_mixing_sub = null;
    }
    if (this.file_info_local_record) {
      RtcDemoFileManager.sharedInstance().closeFile(this.file_info_local_record.fd);
      this.file_info_local_record = null;
    }
    if (this.file_info_local_playback) {
      RtcDemoFileManager.sharedInstance().closeFile(this.file_info_local_playback.fd);
      this.file_info_local_playback = null;
    }
    if (this.file_info_local_remote_mixed) {
      RtcDemoFileManager.sharedInstance().closeFile(this.file_info_local_remote_mixed.fd);
      this.file_info_local_remote_mixed = null;
    }
    if (this.file_info_local_record_sub) {
      RtcDemoFileManager.sharedInstance().closeFile(this.file_info_local_record_sub.fd);
      this.file_info_local_record_sub = null;
    }
  }

  public setFileDir(fileDir: string): void {
    this.file_dir = fileDir + "/AudioFrameObserver";
  }

  private generateFileName(type: string, frame: NERtcConstants.NERtcAudioFrame): string {
    if (frame.format == null) {
      return "";
    }
    let timestamp: string = RtcDemoTimeUtil.getFormattedTimestamp();
    let params: string = String(frame.format.sampleRate) + "_" + String(frame.format.numberOfChannel);
    return type + "_" + params + "_" + timestamp + ".pcm";
  }

  private generateFileNameWithUserInfo(type: string, frame: NERtcConstants.NERtcAudioFrame, channelId: bigint, uid: bigint): string {
    if (frame.format == null) {
      return "";
    }
    let timestamp: string = RtcDemoTimeUtil.getFormattedTimestamp();
    let params: string = String(frame.format.sampleRate) + "_" + String(frame.format.numberOfChannel);
    return type + "_" + String(channelId) + "_" + String(uid) + "_" + params + "_" + timestamp + ".pcm";
  }

  onRecordedFrame(frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_local_record == null) {
      let type: string = "audio_local_record";
      let file_name: string = this.generateFileName(type, frame);
      this.file_info_local_record = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
    }

    if (this.file_info_local_record) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(this.file_info_local_record.fd, frame.data);
    }
  }

  onPlaybackFrame(frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_local_playback == null) {
      let type: string = "audio_local_playback";
      let file_name: string = this.generateFileName(type, frame);
      this.file_info_local_playback = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
    }

    if (this.file_info_local_playback) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(this.file_info_local_playback.fd, frame.data);
    }
  }

  onMixedFrame(frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_local_remote_mixed == null) {
      let type: string = "audio_local_remote_mixed";
      let file_name: string = this.generateFileName(type, frame);
      this.file_info_local_remote_mixed = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
    }

    if (this.file_info_local_remote_mixed) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(this.file_info_local_remote_mixed.fd, frame.data);
    }
  }

  onUserPlaybackFrameBeforeMixing(channelId: bigint, uid: bigint, frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_map_remote_user_before_mixing == null) {
      this.file_info_map_remote_user_before_mixing = new collections.Map<string, RtcDemoFileInfo>();
    }

    let tag = String(channelId) + "_" + String(uid);
    let file_info: RtcDemoFileInfo|null = null;
    if (!this.file_info_map_remote_user_before_mixing.has(tag)) {
      let type: string = "audio_remote_user_before_mixing";
      let file_name: string = this.generateFileNameWithUserInfo(type, frame, channelId, uid);
      file_info = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
      if (file_info != null) {
        this.file_info_map_remote_user_before_mixing.set(tag, file_info);
      }
    } else {
      file_info = this.file_info_map_remote_user_before_mixing.get(tag)!;
    }

    if (file_info) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(file_info.fd, frame.data);
    }
  }

  onRecordedSubStreamFrame(frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_local_record_sub == null) {
      let type: string = "audio_local_record_sub";
      let file_name: string = this.generateFileName(type, frame);
      this.file_info_local_record_sub = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
    }

    if (this.file_info_local_record_sub) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(this.file_info_local_record_sub.fd, frame.data);
    }
  }

  onUserPlaybackSubStreamFrameBeforeMixing(channelId: bigint, uid: bigint, frame: NERtcConstants.NERtcAudioFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    if (this.file_info_map_remote_user_before_mixing_sub == null) {
      this.file_info_map_remote_user_before_mixing_sub = new collections.Map<string, RtcDemoFileInfo>();
    }

    let tag = String(channelId) + "_" + String(uid);
    let file_info: RtcDemoFileInfo|null = null;
    if (!this.file_info_map_remote_user_before_mixing_sub.has(tag)) {
      let type: string = "audio_remote_user_before_mixing_sub";
      let file_name: string = this.generateFileNameWithUserInfo(type, frame, channelId, uid);
      file_info = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
      if (file_info != null) {
        this.file_info_map_remote_user_before_mixing_sub.set(tag, file_info);
      }
    } else {
      file_info = this.file_info_map_remote_user_before_mixing_sub.get(tag)!;
    }

    if (file_info) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(file_info.fd, frame.data);
    }
  }
}

@Sendable
export class RtcDemoVideoFrameObserver implements NERtcVideoFrameObserver {
  protected tag: string = "RtcDemoVideoFrameObserver";
  private file_info_local_capture: RtcDemoFileInfo|null = null;
  private file_dir: string = "";
  private file_tag: string = "";
  private limit_count: number = 150;// yuv太大了，每次打开 videoFrameObserver 之后，仅保存 5 秒的数据

  constructor(tag: string) {
    this.tag = this.tag + "_" + tag;
  }

  public clearUp(): void {
    this.file_info_local_capture = null;
    this.file_dir = "";
    this.limit_count = 150;
  }

  public setFileDir(fileDir: string): void {
    this.file_dir = fileDir + "/VideoFrameObserver";
  }

  private generateFileName(file_tag: string): string {
    let type: string = "video_local_capture";
    let timestamp: string = RtcDemoTimeUtil.getFormattedTimestamp();
    let file_name = type + "_" + file_tag + "_" + timestamp + ".yuv";
    return file_name;
  }

  onVideoFrameCaptured(frame: NERtcConstants.NERtcVideoFrame): void {
    if (frame.format == null || frame.data == null) {
      return;
    }

    let file_tag: string = String(frame.format) + "_" + String(frame.width) + "_" + String(frame.height);

    if (this.file_info_local_capture == null) {
      let file_name = this.generateFileName(file_tag);
      this.file_info_local_capture = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
      this.file_tag = file_tag;
    }

    if (this.file_tag != file_tag) {
      let file_name = this.generateFileName(file_tag);
      if (this.file_info_local_capture) {
        RtcDemoFileManager.sharedInstance().closeFile(this.file_info_local_capture.fd);
      }
      this.file_info_local_capture = RtcDemoFileManager.sharedInstance().createFile(this.file_dir, file_name);
      if (this.file_info_local_capture) {
        this.file_tag = file_tag;
      }
    }

    // if (this.limit_count == 0) {
    //   // console.error(this.tag, `reach max limit_count 90`);
    //   return;
    // }
    // this.limit_count--;

    if (this.file_info_local_capture) {
      RtcDemoFileManager.sharedInstance().writeDataToFile(this.file_info_local_capture.fd, frame.data);
    }
  }

}