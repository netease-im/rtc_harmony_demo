import { NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk';
import { RTCDemoView } from './chat/dialog/RTCDemoView';
import { preferences } from '@kit.ArkData';
import { OtherModel } from './settings/model/common';
import Prompt from '@system.prompt';
import router from '@ohos.router';

/**
 * 演示低延迟直播拉流
 */
@Entry
@Component
struct LowLatency {

  private TAG:string = 'LowLatency'
  private lowLatencyId: string = '123456'
  private otherModel: OtherModel|null = null

  onPageShow(): void {
    let options: preferences.Options = { name: 'netease_settings' }
    let data = preferences.getPreferencesSync(getContext(this), options)
    let localOtherData = data.getSync('otherData', '') as string
    try {
      this.otherModel = JSON.parse(localOtherData)
    } catch (e) {
      Prompt.showToast({ message: '加载失败' })
    }
  }

  onBackPress(): boolean | void {
    let ret = NERtcSDK.getInstance().leaveChannel()
    console.info(this.TAG, `leaveChannel ret:${ret}`)
  }

  build() {
    RelativeContainer() {
        RTCDemoView({
          rtcViewId: this.lowLatencyId,
          local: true,
          attach: () => {

            if (this.otherModel == null) {
              router.back()
              return
            }

            if (!this.otherModel.lowLatencyEnable) {
              Prompt.showToast({ message: '请开启低延迟直播' })
              router.back()
              return
            }

            let fetchUrl = this.otherModel!!.fetchStreamUrl
            if (!fetchUrl || fetchUrl == '') {
              Prompt.showToast({ message: '请输入拉流url'})
              router.back()
              return
            }

            let options = new NERtcConstants.NERtcJoinChannelOptions()
            let canvas: NERtcConstants.NERtcVideoCanvas = {
              canvasId: this.lowLatencyId
            }
            let lowLatencyOptions: NERtcConstants.NERtcLowLatencyOptions = {
              enableLowLatency: this.otherModel?.lowLatencyEnable ?? false,
              playTimeOut: this.otherModel?.fetchStreamTimeOut ?? 60,
              canvas: canvas
            }
            options.lowLatencyOptions = lowLatencyOptions
            let ret = NERtcSDK.getInstance().joinChannel('', this.otherModel!!.fetchStreamUrl, BigInt(this.lowLatencyId), options)
            console.info(this.TAG, `Join lowLatency channel: ret:${ret}`)
          },
          detach: () => {
            let ret = NERtcSDK.getInstance().leaveChannel()
            console.info(this.TAG, `Leave channel: ret:${ret}`)
          },
        }).width('100%').height('100%')
    }
    .height('100%')
    .width('100%')
  }
}