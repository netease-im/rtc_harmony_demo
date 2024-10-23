import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { Prompt } from '@kit.ArkUI'
import picker from '@ohos.file.picker';
import { BusinessError } from '@kit.BasicServicesKit'
import { AudioModel } from '../model/common'
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog'
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog';

@Component
export struct AudioSetting {

  private TAG: string = 'AudioSetting'
  private audioProfileArrays: string[] = ['default', 'standard', 'standard_ext', 'middle', 'middle_stereo', 'high', 'high_stereo']
  private audioScenario: string[] = ['default', 'speech', 'music', 'chatroom']
  private audioDumpTypeArray: string[] = ['PCM', 'ALL', 'WAV']
  @Link audioModel: AudioModel
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


          NetEaseListLogicDialog({
            array: this.audioProfileArrays,
            title: '音频编码属性',
            index: this.audioModel.audioProfile,
            choose: index => {
              this.audioModel.audioProfile = index
            }
          })

          NetEaseListLogicDialog({
            array: this.audioScenario,
            title: '音频场景',
            index: this.audioModel.audioScenario,
            choose: index => {
              this.audioModel.audioScenario = index
            }
          })

          NetEaseInputLogicDialog({
            title: '采集音量',
            content: String(this.audioModel.recordVolume),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.recordVolume = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '播放音量',
            content: String(this.audioModel.playoutVolume),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.playoutVolume = Number.parseInt(value)
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '自动开启音频',
              secondaryText: '自动开启音频'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.autoOpenAudio,
                onChange: value => {
                  this.audioModel.autoOpenAudio = value
                  Prompt.showToast({ message: `是否自动开启音频: ${value}`})
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '自动订阅音频',
              secondaryText: '自动订阅音频'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.autoSubAudio,
                onChange: value => {
                  this.audioModel.autoSubAudio = value
                  Prompt.showToast({ message: `是否订阅音频: ${value}` })
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.audioDumpTypeArray,
            title: 'AudioDump类型',
            index: this.audioModel.audioDumpType,
            choose: index => {
              this.audioModel.audioDumpType = index
            }
          })
        }
        .divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('伴音')}) {

          NetEaseInputLogicDialog({
            title: 'URL(优先)',
            content: this.audioModel.audioMixUrl,
            onInputValue: value => {
              this.audioModel.audioMixUrl = value
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.audioModel.audioMixPath
            }
          }).onClick(() => {
            const selectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(selectOptions).then(result => {
                let URI = result[0]
                console.info(this.TAG, 'picker select to file URI: ' + URI)
                this.audioModel.audioMixPath = URI
            }).catch((err: BusinessError) => {
                console.error(this.TAG, `Invoke audioPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          ComposeListItem({
            contentItem: {
              primaryText: '是否发送',
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.audioMixIsSend,
                onChange: value => {
                  this.audioModel.audioMixIsSend = value
                  Prompt.showToast({ message: `是否发送伴音: ${value}`})
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '是否播放',
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.audioMixIsPlay,
                onChange: value => {
                  this.audioModel.audioMixIsPlay = value
                  Prompt.showToast({ message: `是否本地播放伴音: ${value}`})
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '循环次数',
            content: String(this.audioModel.audioMixLoopNum),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioMixLoopNum = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '音调',
            content: String(this.audioModel.audioMixPitch),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioMixPitch = Number.parseInt(value)
              }
            }
          })
        }
        .divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })


        ListItemGroup({ header: this.itemHead('音效')}){

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.audioModel.audioEffect1Url
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.audioModel.audioEffect1Url = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke audioPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          ComposeListItem({
            contentItem: {
              primaryText: '是否发送'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.audioEffect1IsSend,
                onChange: value => {
                  this.audioModel.audioEffect1IsSend = value
                  Prompt.showToast({ message: `是否发送音效: ${value}`})
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '是否播放'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.audioEffect1IsPlay,
                onChange: value => {
                  this.audioModel.audioEffect1IsPlay = value
                  Prompt.showToast({ message: `是否本地播放音效: ${value}`})
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '循环次数',
            content: String(this.audioModel.audioEffect1LoopNum),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioEffect1LoopNum = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '音调',
            content: String(this.audioModel.audioEffect1Pitch),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioEffect1Pitch = Number.parseInt(value)
              }
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('外部音频数据') }){
          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.audioModel.externalAudioInputUrl
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              this.audioModel.externalAudioInputUrl = URI
            })
          })

          NetEaseInputLogicDialog({
            title: '采样率',
            content: String(this.audioModel.externalAudioInputSampleRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.externalAudioInputSampleRate = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '声道数',
            content: String(this.audioModel.externalAudioInputChannelNum),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.externalAudioInputChannelNum = Number.parseInt(value)
              }
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })


        ListItemGroup({ header: this.itemHead('外部辅流音频数据')}) {

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.audioModel.externalSubAudioInputUrl
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              this.audioModel.externalSubAudioInputUrl = URI
            })
          })

          NetEaseInputLogicDialog({
            title: '采样率',
            content: String(this.audioModel.externalSubAudioInputSampleRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.externalSubAudioInputSampleRate = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '声道数',
            content: String(this.audioModel.externalSubAudioInputChannelNum),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.externalSubAudioInputChannelNum = Number.parseInt(value)
              }
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('采集音量回调设置') }){

          ComposeListItem({
            contentItem: {
              primaryText: '开启音量回调'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.captureVolumeEnable,
                onChange: value => {
                  this.audioModel.captureVolumeEnable = value
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '采集音量回调时间间隔(ms)',
            content: String(this.audioModel.captureVolumeIndicationDuration),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.captureVolumeIndicationDuration = Number.parseInt(value)
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'VAD'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.captureVolumeVAD,
                onChange: value => {
                  this.audioModel.captureVolumeVAD = value
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

        ListItemGroup({ header: this.itemHead('音频回调参数设置') }){

          NetEaseInputLogicDialog({
            title: '通道数',
            content: String(this.audioModel.audioCallbackChannel),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioCallbackChannel = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '采样率',
            content: String(this.audioModel.audioCallbackSampleRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioModel.audioCallbackSampleRate = Number.parseInt(value)
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '只读'
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.audioCallbackReadOnly,
                onChange: value => {
                  this.audioModel.audioCallbackReadOnly = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '开启音频数据回调',
            },
            operateItem: {
              switch: {
                isCheck: this.audioModel.enableFrameObserver,
                onChange: value => {
                  this.audioModel.enableFrameObserver = value
                  Prompt.showToast({ message: value ? "开启了音频数据回调" : "关闭了音频数据回调"})
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

      }.width('100%').height('100%')
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)
    }
  }

}