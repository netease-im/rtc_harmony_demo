/**
 * 演示一路视频在两个画布上显示
 */
import { NERtcCallbackEx, NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk'
import { VideoRenderProcessing } from 'libdataprocessing.so'
import Config from '../common/Config'

class MultiRenderCallback extends NERtcCallbackEx {

  onJoinChannel(result: number, channelId: bigint, elapsed: bigint, uid: bigint): void {
    throw new Error('Method not implemented.')
  }

  onLeaveChannel(result: number): void {
    throw new Error('Method not implemented.')
  }

  onUserJoined(uid: bigint, extraInfo?: NERtcConstants.NERtcUserJoinExtraInfo | undefined): void {
    throw new Error('Method not implemented.')
  }

  onUserLeave(uid: bigint, reason: number, extraInfo?: NERtcConstants.NERtcUserLeaveExtraInfo | undefined): void {
    throw new Error('Method not implemented.')
  }

  onUserAudioStart(uid: bigint): void {
    throw new Error('Method not implemented.')
  }

  onUserAudioStop(uid: bigint): void {
    throw new Error('Method not implemented.')
  }

  onUserVideoStart(uid: bigint, maxProfile: NERtcConstants.NERtcVideoProfileType,
    streamType?: NERtcConstants.NERtcVideoStreamType | undefined): void {
    throw new Error('Method not implemented.')
  }

  onUserVideoStop(uid: bigint, streamType?: NERtcConstants.NERtcVideoStreamType | undefined): void {
    throw new Error('Method not implemented.')
  }

  onDisconnect(reason: number): void {
    throw new Error('Method not implemented.')
  }

  onClientRoleChange(oldRole: number, newRole: number): void {
    throw new Error('Method not implemented.')
  }

  onRecvSEIMsg(userId: bigint, data: Uint8Array, dataSize: number): void {
    throw new Error('Method not implemented.')
  }
}

@Entry
@Component
struct MultiRender {

  private tag: string = 'MultiRender'
  private videoRender: VideoRenderProcessing|null = null
  private callback: MultiRenderCallback = new MultiRenderCallback()
  private preview_id: string = '147829'
  private dup_preview_id: string = 'dup_147829'

  onPageShow(): void {
    let option: NERtcConstants.NERtcOption = { logLevel: NERtcConstants.LogLevel.INFO }
    NERtcSDK.getInstance().init(getContext(this), Config.APP_KEY_DEBUG, this.callback, option);
    console.info(this.tag, 'Init NERtcSDK Engine done!')
    let ret = NERtcSDK.getInstance().startVideoPreview(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain)
    console.info(this.tag, `StartVideoPreview ret: ${ret}`)
    if (this.videoRender == null) {
      this.videoRender = new VideoRenderProcessing()
    }
  }

  build() {
    Flex() {
      XComponent({ id: this.preview_id, type: XComponentType.SURFACE, libraryname: 'dataprocessing'})
        .borderRadius(5)
        .onLoad(() => {
          console.info(this.tag, `${this.preview_id} surface create.`);
          let canvas: NERtcConstants.NERtcExternalVideoCanvas = {
            nativePlugin: this.videoRender!!.getRenderHandle(this.preview_id)
          }
          let ret = NERtcSDK.getInstance().setLocalExternalVideoRender(NERtcConstants.NERtcVideoStreamType.kNERtcVideoStreamTypeMain, canvas)
          console.info(this.tag, `setLocalExternalVideoRender ret: ${ret}`)
        })
        .onDestroy(() => {
          console.info(this.tag, `${this.preview_id} surface destroy.`);
        }).width('50%').height('100%')
      XComponent({ id: this.dup_preview_id, type: XComponentType.SURFACE, libraryname: 'dataprocessing'})
        .borderRadius(5)
        .onLoad(() => {
          console.info(this.tag, `${this.dup_preview_id} surface create.`);
        }).onDestroy(() => {
          console.info(this.tag, `${this.dup_preview_id} surface destroy.`);
      }).width('50%').height('100%')
    }.width('100%').height(250)
  }
}