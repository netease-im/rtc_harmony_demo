import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { Prompt } from '@kit.ArkUI'
import { OtherModel } from '../model/common'
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog'
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog'

@Component
export struct OtherSetting {

  @Link otherModel: OtherModel
  private serverRecordModeArray: string[] = ['混合与单人同时录制', '混合录制', '单人录制']
  private upFallbackOptionArray: string[] = ['DISABLED', 'AUDIO_ONLY']
  private downFallbackOptionArray: string[] = ['VIDEO_STREAM_LOW', 'AUDIO_ONLY']
  public isInMeeting: boolean = false;

  private isHiddenInMeeting(): Visibility {
    return this.isInMeeting ? Visibility.None : Visibility.Visible;
  }

  @Builder itemHead(text: string) {
    Text(text)
      .fontSize(20)
      .backgroundColor('#fff1f3f5')
      .width('100%')
      .padding(5)
  }

  build() {
    Column() {
      List({ space: 10 }) {

        ListItemGroup({ header: this.itemHead('通用')}) {


          ComposeListItem({
            contentItem: {
              primaryText: '质量透明'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.chatDetail,
                onChange: value => {
                  this.otherModel.chatDetail = value
                  Prompt.showToast({ message: `是否开启质量透明: ${value}`})
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.upFallbackOptionArray,
            title: '上行回退选项',
            index: this.otherModel.upFallbackOption,
            choose: index => {
              this.otherModel.upFallbackOption = index
            }
          }).visibility(this.isHiddenInMeeting())

          NetEaseListLogicDialog({
            array: this.downFallbackOptionArray,
            title: '下行回退选项',
            index: this.otherModel.downFallbackOption,
            choose: index => {
              this.otherModel.downFallbackOption = index
            }
          }).visibility(this.isHiddenInMeeting())

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('网络测速')}) {

          NetEaseInputLogicDialog({
            title: '期望最高上行码率',
            content: String(this.otherModel.upLinkBitRate ?? '5000000'),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.otherModel.upLinkBitRate = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '期望最高下行码率',
            content: String(this.otherModel.downLinkBitRate ?? '200000'),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.otherModel.downLinkBitRate = Number.parseInt(value)
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '上行网络检测',
              secondaryText: '上行网络检测'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.upLinkProbe,
                onChange: value => {
                  this.otherModel.upLinkProbe = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '下行网络检测',
              secondaryText: '下行网络检测'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.downLinkProbe,
                onChange: value => {
                  this.otherModel.downLinkProbe = value
                }
              }
            }
          })
        }

        ListItemGroup({ header: this.itemHead('服务器录制')}) {

          ComposeListItem({
            contentItem: {
              primaryText: '录制主讲人',
              secondaryText: '录制主讲人'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.recordSpeaker,
                onChange: value => {
                  this.otherModel.recordSpeaker = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '音频录制',
              secondaryText: '音频录制'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.audioRecord,
                onChange: value => {
                  this.otherModel.audioRecord = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '视频录制',
              secondaryText: '视频录制'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.videoRecord,
                onChange: value => {
                  this.otherModel.videoRecord = value
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.serverRecordModeArray,
            title: '录制模式',
            index: this.otherModel.recordMode,
            choose: index => {
              this.otherModel.recordMode = index
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

      }.width('100%').height('100%')
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }
  }

}