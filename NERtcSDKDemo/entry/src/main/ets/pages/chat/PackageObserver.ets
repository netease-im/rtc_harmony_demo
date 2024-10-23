// 自定义加密实现类
import { NERtcConstants } from '@nertc/nertc_sdk'

import { NERtcPacketObserver } from '@nertc/nertc_sdk'

import ARC4 from '../../common/ARC4'
import { util } from '@kit.ArkTS'

@Sendable
export class DemoNERtcPackageObserver implements NERtcPacketObserver {

  private TAG: string = "MyNERtcPacketObserver"
  private key: string = "I_am_a_key"

  onSendAudioPacket(packet: NERtcConstants.NERtcPacket): bigint {

    if(!packet.data) return BigInt(0)

    let chiper: ARC4 = new ARC4()
    try {
      let keyIv = new util.TextEncoder().encode(this.key)
      chiper.setKey(keyIv)
    } catch (e) {
      console.error(this.TAG, 'onSendAudioPacket setKey Error: ' + JSON.stringify(e))
    }

    let encryptData: Uint8Array = new Uint8Array(Number(packet.size))
    try {
      chiper.encrypt(packet.data, encryptData, Number(packet.size))
      packet.data.set(encryptData)
    } catch (e) {
      console.info(this.TAG, "onSendAudioPacket encrypt Error: " + JSON.stringify(e))
    }
    return BigInt(packet.size)
  }

  onSendVideoPacket(packet: NERtcConstants.NERtcPacket): bigint {

    if(!packet.data) return BigInt(0)

    let chiper: ARC4 = new ARC4()
    try {
      let keyIv = new util.TextEncoder().encode(this.key)
      chiper.setKey(keyIv)
    } catch (e) {
      console.info(this.TAG, 'onSendVideoPacket set key Error: ' + JSON.stringify(e))
    }

    let encryptData: Uint8Array = new Uint8Array(Number(packet.size))
    try {
      chiper.encrypt(packet.data, encryptData, Number(packet.size))
      packet.data.set(encryptData)
    } catch (e) {
      console.info(this.TAG, 'onSendVideoPacket encrypt Error: ' + JSON.stringify(e))
    }
    return BigInt(packet.size)
  }

  onReceiveAudioPacket(packet: NERtcConstants.NERtcPacket): bigint {

    if(!packet.data) return BigInt(0)

    let chiper: ARC4 = new ARC4()
    try {
      let keyIv = new util.TextEncoder().encode(this.key)
      chiper.setKey(keyIv)
    } catch (e) {
      console.info(this.TAG, 'onSendVideoPacket set key Error: ' + JSON.stringify(e))
    }

    let decryptData: Uint8Array = new Uint8Array(Number(packet.size))
    try {
      chiper.encrypt(packet.data, decryptData, Number(packet.size))
      packet.data.set(decryptData)
    } catch (e) {
      console.info(this.TAG, 'onReceiveAudioPacket decrypt Error: ' + JSON.stringify(e))
    }
    return BigInt(packet.size)
  }

  onReceiveVideoPacket(packet: NERtcConstants.NERtcPacket): bigint {

    if(!packet.data) return BigInt(0)

    let chiper: ARC4 = new ARC4()
    try {
      let keyIv = new util.TextEncoder().encode(this.key)
      chiper.setKey(keyIv)
    } catch (e) {
      console.info(this.TAG, 'onReceiveVideoPacket set key Error: ' + JSON.stringify(e))
    }

    let decryptData: Uint8Array = new Uint8Array(Number(packet.size))
    try {
      chiper.encrypt(packet.data, decryptData, Number(packet.size))
      // update buffer.
      packet.data.set(decryptData)
    } catch (e) {
      console.info(this.TAG, 'onReceiveVideoPacket decrypt Error: ' + JSON.stringify(e))
    }
    return BigInt(packet.size)
  }

}