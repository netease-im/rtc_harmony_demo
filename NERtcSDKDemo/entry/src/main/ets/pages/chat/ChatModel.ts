export enum ChatState {
  CHAT_IDLE = 0,
  CHAT_ING = 1,
  CHAT_ED = 2
}

export interface LoginInfo {
  cname: string;
  uid: string;
  logDir?: string;
  token?: string;
  context?: object;
  fromTA?: boolean;
}

export interface SettingInfo {
  reInit: boolean;
}

export interface ChatResult {
  result: ChatState;
  detail?: string;
}

export enum API {
  INIT = 'init',
  JOIN = 'join',
  SETUP = 'setup',
  ENABLE_VIDEO = 'enableVideo',
  LEAVE = 'leave',
  RELEASE = 'release',

  ON_JOIN = 'onJoin',
  ON_LEAVE = 'onLeave',
  ON_USER_JOIN = 'onUserJoin',
  ON_USER_LEAVE = 'onUserLeave'
}

export interface ChatResult {
  result: ChatState;
  detail?: string;
}

export interface RecvStats {
  upRtt: number,
  downRtt: number,
  txAudioPacketLossRate: number,
  txVideoPacketLossRate: number,
  rxAudioPacketLossRate: number,
  rxVideoPacketLossRate: number,

  rxAudioKBitRate: number,
  rxVideoKBitRate: number,
  txAudioKBitRate: number,
  txVideoKBitRate: number
}

export interface RemoteAudioStats {
  peerToPeerDelay: number
}

export interface NetworkQuality {
  upStatus: number,
  downStatus: number
}

export interface NERtcData {
  api: API
}

export interface Init extends  NERtcData {
  key: string
  level: number
  logDir?: string
}

export interface Join extends NERtcData {
  token: string
  cname: string
  uid: string
}

export interface SetUp extends NERtcData {
  uid: string
  xComponentId: string
  isMe: boolean
}

export interface EnableVideo extends NERtcData {
  enable: boolean
}


export interface Response extends NERtcData {
  ret: number
}

export interface SetUpResponse extends Response {
  uid: string
}

export interface CallbackResponse extends Response {
  object: any
}

export enum UI {
  AUDIO = 0,
  VIDEO = 1,
  OTHER = 2
}

export interface LocalVolumeInfo {
  volume: number
  vad: boolean
}

export interface RemoteVolumeInfo {
  uid: bigint;
  volume: number;
  subStreamVolume: number;
}

export type DemoLogicMap = Map<string,any>

