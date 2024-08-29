import DemoUser from '../../model/DemoUser';
import { DemoLogicMap, LocalVolumeInfo, RemoteVolumeInfo } from './ChatModel';
import { NERtcConstants } from 'sdk'

export enum OPERATOR {
  ADD = 0,
  DEL = 1,
  UPD = 2
}

export default interface UIDelegate {
  update:(operator: OPERATOR, user: DemoLogicMap|DemoUser)=> void;
  error:(errMsg: string)=> void;
  detail?: (msg: string) => void;
  localVolume?: (volumeInfo: LocalVolumeInfo)=> void;
  remoteVolume?: (volumeArray: RemoteVolumeInfo[], totalVolume: number)=> void;
  networkQuality?: (quality: number|null, result: NERtcConstants.NERtcProbeResult|null) => void;
}