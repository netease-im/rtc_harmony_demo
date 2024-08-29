import { NERtcConstants } from 'sdk'
import ChatPresenter from '../../chat/Presenter1'

@CustomDialog
export struct NetEaseProbeLoginDialog {

  @Link networkQuality: number|null
  @Link networkResult: NERtcConstants.NERtcProbeResult|null
  @Link probeEnd: boolean
  controller?: CustomDialogController

  private GetNetWorkQuality(): string {
    let quality: string = '质量未知'
    if(this.networkQuality) {
      switch (this.networkQuality) {
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityExcellent:
          quality = '质量极好'
          break;
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityGood:
          quality = '质量很好'
          break;
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityPoor:
          quality = '质量不佳'
          break;
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityBad:
          quality = '质量不好'
          break;
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityVeryBad:
          quality = '质量很差'
          break;
        case NERtcConstants.NERtcSDKNetworkQualityType.kLiteSDKNetworkQualityDown:
          quality = '完全无法使用'
          break;
      }
    }
    return quality
  }

  private GetNetWorkDescriptor(): string {
    let descriptor: string = ''
    switch (this.networkResult?.type) {
      case NERtcConstants.NERtcProbeResultType.kNERtcProbeResultComplete:
        descriptor = '本次质量探测是完整的'
        break;
      case NERtcConstants.NERtcProbeResultType.kNERtcProbeResultIncompleteNoBwe:
        descriptor = '本次质量探测不完整，未进行带宽预测，通常资源受限'
        break;
      case NERtcConstants.NERtcProbeResultType.kNERtcProbeResultUnavailable:
        descriptor = '未进行质量探测，通常网络连接中断'
        break;
    }
    return descriptor
  }

  build() {
    Column() {
      Row({ space: 20 }) {
        Text(this.probeEnd ? '探测结束' : '开始测速...').fontSize(20).textAlign(TextAlign.Start)
        if(!this.probeEnd) {
          Progress({ value: 0, type: ProgressType.Ring }).color(Color.Blue)
            .style({strokeWidth: 5, status: ProgressStatus.LOADING}).width(50).height(50)
        }
      }.padding({ left: 10, right: 10 }).width('100%').alignItems(VerticalAlign.Center).margin({ top: 20 })
      Row({ space: 5 }) {
        Text('探测结果:').fontSize(15)
        Text(this.GetNetWorkQuality()).fontSize(18).fontColor(Color.Red)
      }.width('100%').align(Alignment.Start).margin({ top: 20 }).padding({ left: 10, right: 10 })

      Divider().strokeWidth(1).color('#F1F3F5').margin({ left: 10 , right: 10, top : 10 })
      Column({ space: 5 }){
        Text('探测详情').fontSize(15).width('100%').textAlign(TextAlign.Start)
        Row({ space: 5 }) {
          Text('探测状态:').fontSize(12)
          Text(this.GetNetWorkDescriptor()).fontSize(12).textOverflow({ overflow: TextOverflow.Ellipsis })
        }.margin({ top: 5 }).width('100%').align(Alignment.Start)
        Row({ space: 5 }) {
          Text('往返时延(ms):').fontSize(12)
          Text(String(this.networkResult?.rtt ?? 'NAN')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
      }.width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 }).alignItems(HorizontalAlign.Start)

      Divider().strokeWidth(1).color('#F1F3F5').margin({ left: 10 , right: 10, top : 10 })
      Column({ space: 5 }){
        Text('上行质量报告').fontSize(15).width('100%').textAlign(TextAlign.Start)
        Row({ space: 5 }) {
          Text('网络抖动(ms):').fontSize(12)
          Text(String(this.networkResult?.upLinkResult?.packetLossRate ?? 'NAN')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
        Row({ space: 5 }){
          Text('丢包率(%):').fontSize(12)
          Text(String(this.networkResult?.upLinkResult?.jitter ?? 'NAN')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
        Row({ space: 5 }) {
          Text('预估可用带宽(kbps):').fontSize(12)
          Text(String(this.networkResult?.upLinkResult?.availableBandWidth ?? '0')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
      }.width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })

      Divider().strokeWidth(1).color('#F1F3F5').margin({ left: 10 , right: 10, top : 10 })
      Column({ space: 5 }){
        Text('下行质量报告').fontSize(15).width('100%').textAlign(TextAlign.Start)
        Row({ space: 5 }) {
          Text('网络抖动(ms):').fontSize(12)
          Text(String(this.networkResult?.downLinkResult?.packetLossRate ?? 'NAN')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
        Row({ space: 5 }){
          Text('丢包率(%):').fontSize(12)
          Text(String(this.networkResult?.downLinkResult?.jitter ?? 'NAN')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
        Row({ space: 5 }) {
          Text('预估可用带宽(kbps):').fontSize(12)
          Text(String(this.networkResult?.downLinkResult?.availableBandWidth ?? '0')).fontSize(15).fontColor(Color.Red)
        }.margin({ top: 5}).width('100%').align(Alignment.Start)
      }.width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })

      Button(this.probeEnd ? '退出':'停止测速', { type: ButtonType.Capsule, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL }).margin({ top: 20, bottom: 20 }).onClick(() => {
        if(this.probeEnd) {
          this.controller?.close()
        } else {
          ChatPresenter.getInstance().enableLastMileProbe(false)
          this.controller?.close()
        }
      })
    }.backgroundColor(Color.White)
  }


}