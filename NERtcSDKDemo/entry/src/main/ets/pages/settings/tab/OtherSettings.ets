import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { Prompt } from '@kit.ArkUI'
import { OtherModel } from '../model/common'
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog'
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog'
import Config from '../../../common/Config'

@Component
export struct OtherSetting {

  @Link otherModel: OtherModel
  private serverRecordModeArray: string[] = ['混合与单人同时录制', '混合录制', '单人录制']
  private upFallbackOptionArray: string[] = ['DISABLED', 'AUDIO_ONLY']
  private downFallbackOptionArray: string[] = ['VIDEO_STREAM_LOW', 'AUDIO_ONLY']
  private channelProfileArray: string[] = ['Communication', 'LiveBroadcasting', 'StandardVideoCall', 'HighQualityVideoCall', 'StandardChatRoom', 'HighQualityChatRoom', 'Meeting', 'Karaoke']
  private pushAddressArray: string[] = ['直推阿里(pd3a)', '直推腾讯(p210)', '云信转阿里(pb6a)', '云信转腾讯(p13b)', '云信转阿里(线上pf73)']
  private mediaPriorityArray: string[] = ['HIGH', 'NORMAL']
  private cloudProxyArray: string[] = ['NONE_PROXY', 'UDP_PROXY']
  private mediaEncryptionOption: string[] = ['Disable(-1)', 'SM4ECB(0)', 'CustomEncryption']
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
              primaryText: '测试环境'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.debug,
                onChange: value => {
                  this.otherModel.debug = value
                  Prompt.showToast({ message: `切换至 ${ value ? 'debug':'release'} 环境`})
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'AppKey',
            content: String(this.otherModel.appKey != '' ? this.otherModel.appKey : Config.APP_KEY_DEBUG),
            onInputValue: value => {
              this.otherModel.appKey = value
            }
          })

          NetEaseListLogicDialog({
            array: this.channelProfileArray,
            title: '房间场景',
            index: this.otherModel.channelProfile,
            choose: index => {
              this.otherModel.channelProfile = index
            }
          }).visibility(this.isHiddenInMeeting())

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

          NetEaseInputLogicDialog({
            title: '画布圆角',
            content: String(this.otherModel.canvasBorderRadius ?? '0'),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.otherModel.canvasBorderRadius = Number.parseInt(value)
              }
            }
          }).visibility(this.isHiddenInMeeting())

          NetEaseListLogicDialog({
            array: this.cloudProxyArray,
            title: '云代理设置',
            index: this.otherModel.cloudProxyOption,
            choose: index => {
              this.otherModel.cloudProxyOption = index
            }
          }).visibility(this.isHiddenInMeeting())

          ComposeListItem({
            contentItem: {
              primaryText: '开启外部渲染'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.useExternalRender,
                onChange: value => {
                  this.otherModel.useExternalRender = value
                  Prompt.showToast({ message: `开启外部渲染: ${value}`})
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '登陆最大超时时间(s)',
            content: String(this.otherModel.loginTimeOutTime),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.otherModel.loginTimeOutTime = Number.parseInt(value)
              }
            }
          }).visibility(this.isHiddenInMeeting())

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('媒体优先级') }) {

          NetEaseListLogicDialog({
            array: this.mediaPriorityArray,
            title: '本地媒体优先级',
            index: this.otherModel.mediaPriority,
            choose: index => {
              this.otherModel.mediaPriority = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '开启抢占'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.isPreemptiveMode,
                onChange: value => {
                  this.otherModel.isPreemptiveMode = value
                }
              }
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        }).visibility(this.isHiddenInMeeting())


        ListItemGroup({ header: this.itemHead('语音字幕')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '开启字幕'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.captionMode,
                onChange: value => {
                  this.otherModel.captionMode = value
                  Prompt.showToast({ message: `字幕状态: ${value}`})
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '字幕源语言',
            content: String(this.otherModel.captionSource ?? ''),
            onInputValue: value => {
              this.otherModel.captionSource = value
            }
          }).visibility(this.isHiddenInMeeting())

          NetEaseInputLogicDialog({
            title: '字幕目标语言',
            content: String(this.otherModel.captionDest ?? ''),
            onInputValue: value => {
              this.otherModel.captionDest = value
            }
          }).visibility(this.isHiddenInMeeting())
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('融合推流')}) {
          NetEaseInputLogicDialog({
            title: '融合推流地址(优先)',
            content: String(this.otherModel.pushAddress),
            onInputValue: value => {
              this.otherModel.pushAddress = value
            }
          })

          NetEaseListLogicDialog({
            array: this.pushAddressArray,
            title: '预设推流地址(默认)',
            index: this.otherModel.pushAddressIndex,
            choose: index => {
              this.otherModel.pushAddressIndex = index
            }
          }).visibility(this.isHiddenInMeeting())

          NetEaseInputLogicDialog({
            title: 'Gop',
            content: String(this.otherModel.gop),
            onInputValue: value => {
              this.otherModel.gop = value
            }
          }).visibility(this.isHiddenInMeeting())

          ComposeListItem({
            contentItem: {
              primaryText: '服务器录制'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.serverRecord,
                onChange: value => {
                  this.otherModel.serverRecord = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '单路视频透传'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.cdnPass,
                onChange: value => {
                  this.otherModel.cdnPass = value
                }
              }
            }
          })
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
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

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

        ListItemGroup({ header: this.itemHead('媒体加密')}){

          NetEaseListLogicDialog({
            array: this.mediaEncryptionOption,
            title: '媒体加密选项',
            index: this.otherModel.mediaEncryption,
            choose: index => {
              this.otherModel.mediaEncryption = index
            }
          })

          NetEaseInputLogicDialog({
            title: '密钥',
            content: String(this.otherModel.mediaEncryptionKey),
            onInputValue: value => {
              this.otherModel.mediaEncryptionKey = value
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        }).visibility(this.isHiddenInMeeting())

        ListItemGroup({ header: this.itemHead('低延迟直播')}){

          ComposeListItem({
            contentItem: {
              primaryText: '开启低延迟直播'
            },
            operateItem: {
              switch: {
                isCheck: this.otherModel.lowLatencyEnable,
                onChange: value => {
                  this.otherModel.lowLatencyEnable = value
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '拉流超时时间(单位:s)',
            content: String(this.otherModel.fetchStreamTimeOut),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.otherModel.fetchStreamTimeOut = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: '请输入数字!' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '拉流URL',
            content: String(this.otherModel.fetchStreamUrl),
            onInputValue: value => {
              this.otherModel.fetchStreamUrl = value
              console.info('user setting fetch stream url: ' + this.otherModel.fetchStreamUrl)
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        }).visibility(this.isHiddenInMeeting())

        ListItemGroup({ header: this.itemHead('私有化设置')}){

          NetEaseInputLogicDialog({
            title: '私有参数配置',
            content: String(this.otherModel.privateParamSetting),
            onInputValue: value => {
              this.otherModel.privateParamSetting = value
              console.info('user setting private params: ' + this.otherModel.privateParamSetting)
            }
          })

          NetEaseInputLogicDialog({
            title: '私有化地址',
            content: String(this.otherModel.privateAddress),
            onInputValue: value => {
              this.otherModel.privateAddress = value
              console.info('user setting private address: ' + this.otherModel.privateAddress)
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        }).visibility(this.isHiddenInMeeting())

      }.width('100%').height('100%')
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }
  }

}