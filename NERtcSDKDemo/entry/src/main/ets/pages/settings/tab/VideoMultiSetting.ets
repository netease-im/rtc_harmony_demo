import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import Prompt from '@system.prompt';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { VideoModelMulti } from '../model/common';
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog';
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog';
@Component
export struct VideoMultiSetting {

  private TAG: string = 'VideoMultiSetting'
  @Link videoModel: VideoModelMulti;
  public isInMeeting: boolean = false;

  private sendResolutionArray: string[] = ['Lowest', 'Low', 'Standard', '720P', '1080P']
  private colorFormatArray: string[] = ['texture', 'I420']
  private encodeFrameMode: string[] = ['Default', 'MaintainFramerate', 'MaintainQuality', 'Balanced']
  private encodeFrameRate: string[] = ['7', '10', '15', '24', '30', 'Default']
  private cropModeArray: string[] = ['默认', '16:9', '4:3', '1:1']
  private externalVideoTypeArray: string[] = ['YUV420文件', 'NV21文件', 'MP4文件']
  private videoSendMirrorArray: string[] = ['0 Default', '1 Mirror', '2 Disabled']

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
    Column(){
      List({ space: 10 }) {
        ListItemGroup({ header: this.itemHead('第三流')}) {

          NetEaseInputLogicDialog({
            title: '采集宽',
            content: String(this.videoModel.thirdCaptureWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.thirdCaptureWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: '请输入合法的整型'})
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '采集高',
            content: String(this.videoModel.thirdCaptureHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.thirdCaptureHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: '请输入合法的整型'})
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.sendResolutionArray,
            title: '发送分辨率',
            index: this.videoModel.thirdSendResolution,
            choose: index => {
              this.videoModel.thirdSendResolution = index
            }
          })

          NetEaseListLogicDialog({
            array: this.colorFormatArray,
            title: 'colorFormat',
            index: this.videoModel.thirdStreamColorFormat,
            choose: index => {
              this.videoModel.thirdStreamColorFormat = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameMode,
            title: '编码模式',
            index: this.videoModel.thirdEncodeFrameMode,
            choose: index => {
              this.videoModel.thirdEncodeFrameMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameRate,
            title: '编码帧率',
            index: this.videoModel.thirdEncodeFrameRate,
            choose: index => {
              this.videoModel.thirdEncodeFrameRate = index
            }
          })

          NetEaseListLogicDialog({
            array: this.cropModeArray,
            title: '裁剪模式',
            index: this.videoModel.thirdCropMode,
            choose: index => {
              this.videoModel.thirdCropMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.videoSendMirrorArray,
            title: '视频发送镜像',
            index: this.videoModel.thirdMirrorMode,
            choose: index => {
              this.videoModel.thirdMirrorMode = index
            }
          })
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('第四流') }) {

          NetEaseListLogicDialog({
            array: this.sendResolutionArray,
            title: '发送分辨率',
            index: this.videoModel.fourthSendResolution,
            choose: index => {
              this.videoModel.fourthSendResolution = index
            }
          })

          NetEaseListLogicDialog({
            array: this.colorFormatArray,
            title: 'colorFormat',
            index: this.videoModel.fourthStreamColorFormat,
            choose: index => {
              this.videoModel.fourthStreamColorFormat = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameMode,
            title: '编码模式',
            index: this.videoModel.fourthEncodeFrameMode,
            choose: index => {
              this.videoModel.fourthEncodeFrameMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameRate,
            title: '编码帧率',
            index: this.videoModel.fourthEncodeFrameRate,
            choose: index => {
              this.videoModel.fourthEncodeFrameRate = index
            }
          })

          NetEaseListLogicDialog({
            array: this.cropModeArray,
            title: '裁剪模式',
            index: this.videoModel.fourthCropMode,
            choose: index => {
              this.videoModel.fourthCropMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.videoSendMirrorArray,
            title: '视频发送镜像',
            index: this.videoModel.fourthMirrorMode,
            choose: index => {
              this.videoModel.fourthMirrorMode = index
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('外部第三流视频数据')}){

          NetEaseListLogicDialog({
            array: this.externalVideoTypeArray,
            title: '文件类型',
            index: this.videoModel.externalThirdVideoType,
            choose: index => {
              this.videoModel.externalThirdVideoType = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.videoModel.externalThirdVideoPath
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.videoModel.externalThirdVideoPath = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke videoPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          NetEaseInputLogicDialog({
            title: '视频宽',
            content: String(this.videoModel.externalThirdVideoWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalThirdVideoWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '视频高',
            content: String(this.videoModel.externalThirdVideoHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalThirdVideoHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '帧率',
            content: String(this.videoModel.externalThirdVideoFrameRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalThirdVideoFrameRate = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '角度',
            content: String(this.videoModel.externalThirdVideoRotation),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalThirdVideoRotation = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

        }.divider({
            strokeWidth: 1,
            startMargin: 10,
            endMargin: 10,
            color: '#F1F3F5'
          })

        ListItemGroup({ header: this.itemHead('外部第四流视频数据')}) {

          NetEaseListLogicDialog({
            array: this.externalVideoTypeArray,
            title: '文件类型',
            index: this.videoModel.externalFourthVideoType,
            choose: index => {
              this.videoModel.externalFourthVideoType = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.videoModel.externalFourthVideoPath
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.videoModel.externalFourthVideoPath = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke videoPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          NetEaseInputLogicDialog({
            title: '视频宽',
            content: String(this.videoModel.externalFourthVideoWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalFourthVideoWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '视频高',
            content: String(this.videoModel.externalFourthVideoHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalFourthVideoHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '帧率',
            content: String(this.videoModel.externalFourthVideoFrameRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalFourthVideoFrameRate = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '角度',
            content: String(this.videoModel.externalFourthVideoRotation),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalFourthVideoRotation = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

      }
      .width('100%').height('100%')
      .scrollBar(BarState.Auto)
      .sticky(StickyStyle.Header)

    }.width('100%').height('100%')
  }
}