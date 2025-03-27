import DemoUser from '../../model/DemoUser';
import { DemoLogicMap, LocalVolumeInfo, RemoteVolumeInfo } from './ChatModel';
import { NERtcConstants } from '@nertc/nertc_sdk'

export enum OPERATOR {
  ADD = 0,
  DEL = 1,
  UPD = 2
}

export default interface UIDelegate {
  update:(operator: OPERATOR, user: DemoLogicMap|DemoUser)=> void;
  error:(errMsg: string)=> void;

  //质量透明相关
  localVideoStats?:(stats: Map<number, string>) => void;
  localAudioStats?:(stat: string) => void;
  localRtcStats?:(stat: string) => void;
  roomNetWorkQuality?:(infos: Map<bigint, string>) => void;
  remoteVideoStats?:(stats: Map<bigint, Map<number, string>>) => void;
  remoteAudioStats?:(stats: Map<bigint, string>) => void;

  //音量相关
  localVolume?: (volumeInfo: LocalVolumeInfo)=> void;
  remoteVolume?: (volumeArray: RemoteVolumeInfo[], totalVolume: number)=> void;

  //测速网络质量
  networkQuality?: (quality: number|null, result: NERtcConstants.NERtcProbeResult|null) => void;
  changeTitle?:(title: string) => void;
  aiHowling?: (flag: number) => void;
}