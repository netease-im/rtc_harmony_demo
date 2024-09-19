import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import Prompt from '@system.prompt';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AudioEffectModel, DumpModel } from '../model/common';
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog';
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog';

@Component
export struct AudioEffectSetting {
  @Link audioEffectModel: AudioEffectModel

  //变声 预设值。
  private voiceChangerEffectsArray: string[] = ['0 无', '1 机器人', '2 巨人', '3 恐怖', '4 成熟', '5 男变女', '6 女变男', '7 男变萝莉', '8 女变萝莉']

  //美声 预设值。
  private voiceBeautifierEffectsArray: string[] = ['0 关闭', '1 低沉', '2 圆润', '3 清澈', '4 磁性', '5 录音棚', '6 天籁', '7 KTV', '8 悠远', '9 教堂', '10 卧室', '11 Live']

  //频谱子带索引 预设值。


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

        ListItemGroup({ header: this.itemHead('变声')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '变声预设值'
            },
            operateItem: {
              switch: {
                isCheck: this.audioEffectModel.voiceChangerEffectsEnable,
                onChange: value => {
                  this.audioEffectModel.voiceChangerEffectsEnable = value
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.voiceChangerEffectsArray,
            title: '变声预设',
            index: this.audioEffectModel.voiceChangerEffectsType,
            choose: index => {
              this.audioEffectModel.voiceChangerEffectsType = index
            }
          })
        }

        ListItemGroup({ header: this.itemHead('美声')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '预设的美声效果'
            },
            operateItem: {
              switch: {
                isCheck: this.audioEffectModel.voiceBeautifierEffectsEnable,
                onChange: value => {
                  this.audioEffectModel.voiceBeautifierEffectsEnable = value
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.voiceBeautifierEffectsArray,
            title: '美声预设',
            index: this.audioEffectModel.voiceBeautifierEffectsType,
            choose: index => {
              this.audioEffectModel.voiceBeautifierEffectsType = index
            }
          })
        }

        ListItemGroup({ header: this.itemHead('音调')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '音调'
            },
            operateItem: {
              switch: {
                isCheck: this.audioEffectModel.voicePitchEnable,
                onChange: value => {
                  this.audioEffectModel.voicePitchEnable = value
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '音调',
            content: String(this.audioEffectModel.voicePitch),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.voicePitch = Number.parseInt(value)
              }
            }
          })
        }

        ListItemGroup({ header: this.itemHead('设置本地语音混响效果')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '混响'
            },
            operateItem: {
              switch: {
                isCheck: this.audioEffectModel.voiceReverbEnable,
                onChange: value => {
                  this.audioEffectModel.voiceReverbEnable = value
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'wetGain',
            content: String(this.audioEffectModel.wetGain),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.wetGain = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'dryGain',
            content: String(this.audioEffectModel.dryGain),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.dryGain = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'damping',
            content: String(this.audioEffectModel.damping),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.damping = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'roomSize',
            content: String(this.audioEffectModel.roomSize),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.roomSize = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'decayTime',
            content: String(this.audioEffectModel.decayTime),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.decayTime = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: 'preDelay',
            content: String(this.audioEffectModel.preDelay),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.preDelay = Number.parseInt(value)
              }
            }
          })
        }

        ListItemGroup({ header: this.itemHead('设置本地语音音效均衡')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '音效均衡'
            },
            operateItem: {
              switch: {
                isCheck: this.audioEffectModel.voiceEqualizationEnable,
                onChange: value => {
                  this.audioEffectModel.voiceEqualizationEnable = value
                }
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '31',
            content: String(this.audioEffectModel.band31),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band31 = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '62',
            content: String(this.audioEffectModel.band62),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band62 = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '125',
            content: String(this.audioEffectModel.band125),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band125 = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '250',
            content: String(this.audioEffectModel.band250),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band250 = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '500',
            content: String(this.audioEffectModel.band500),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band500 = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '1K',
            content: String(this.audioEffectModel.band1K),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band1K = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '2K',
            content: String(this.audioEffectModel.band2K),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band2K = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '4K',
            content: String(this.audioEffectModel.band4K),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band4K = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '8K',
            content: String(this.audioEffectModel.band8K),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band8K = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '16K',
            content: String(this.audioEffectModel.band16K),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.audioEffectModel.band16K = Number.parseInt(value)
              }
            }
          })
        }

      }.width('100%').height('100%')
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)
    }
  }
}
