import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import Prompt from '@system.prompt';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { VideoModel } from '../model/common';
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog';
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog';
@Component
export struct VideoSetting {

  private TAG: string = 'VideoSetting'
  @Link videoModel: VideoModel;
  public isInMeeting: boolean = false;

  private encodeModeArray: string[] = ['默认', '软编', '硬编']
  private decodeModeArray: string[] = ['默认', '软解', '硬解']
  private previewVideoStreamType: string[] = ['主流', '辅流', '第三流', '第四流']
  private scaleModeArray: string[] = ['FIT', 'FILL', 'BALANCED']
  private sendResolutionArray: string[] = ['Lowest', 'Low', 'Standard', '720P', '1080P']
  private colorFormatArray: string[] = ['texture', 'I420']
  private multiStreamArray: string[] = ['单流', '双流', '三流']
  private encodeFrameMode: string[] = ['Default', 'MaintainFramerate', 'MaintainQuality', 'Balanced']
  private encodeFrameRate: string[] = ['7', '10', '15', '24', '30', 'Default']
  private screenResolutionArray: string[] = ['480P', '720P', '1080P']
  private screenModeArray: string[] = ['MOTION', 'DETAILS']
  private cropModeArray: string[] = ['默认', '16:9', '4:3', '1:1']
  private externalVideoTypeArray: string[] = ['YUV420文件', 'NV21文件', 'MP4文件']
  private videoSendMirrorArray: string[] = ['0 Default', '1 Mirror', '2 Disabled']
  private publishVideoStreamType: string[] = ['None', 'High', 'Low', 'ALL']
  private virtualBackgroundTypeArray: string[] = ['颜色', '图片', '雾化']
  private virtualBackgroundBlurDegreeArray: string[] = ['Low', 'Medium', 'High']
  private virtualBackgroundSourceArray: string[] = ['自选文件', '图片1', '图片2', '图片3', '图片4', '图片5', '图片6']
  private videoCallbackWays: string[] = ['Typescript', 'c++']

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
        ListItemGroup({ header: this.itemHead('通用')}) {
          ComposeListItem({
            contentItem: {
              primaryText: '前置摄像头',
              secondaryText: '选择摄像头'
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.fontCamera,
                onChange: value => {
                  this.videoModel.fontCamera = value
                  Prompt.showToast({ message: value ? "选择了前置摄像头" : "选择了后置摄像头"})
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.previewVideoStreamType,
            title: '预览流类型',
            index: this.videoModel.previewStreamType,
            choose: index => {
              this.videoModel.previewStreamType = index
            }
          })
          
          NetEaseListLogicDialog({
            array: this.multiStreamArray,
            title: '多流模式',
            index: this.videoModel.mainSendResolution,
            choose: index => {
              this.videoModel.enableDualStream = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeModeArray,
            title: '编码模式',
            index: this.videoModel.encodeMode,
            choose: index => {
              this.videoModel.encodeMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.decodeModeArray,
            title: '解码模式',
            index: this.videoModel.decodeMode,
            choose: index => {
              this.videoModel.decodeMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.scaleModeArray,
            title: '画布缩放模式',
            index: this.videoModel.scaleMode,
            choose: index => {
              this.videoModel.scaleMode = index
            }
          }).visibility(this.isHiddenInMeeting())

          NetEaseListLogicDialog({
            array: this.publishVideoStreamType,
            title: '发布流类型',
            index: this.videoModel.publishStreamType,
            choose: index => {
              this.videoModel.publishStreamType = index
            }
          })

          NetEaseListLogicDialog({
            array: this.videoCallbackWays,
            title: '视频回调处理方式',
            index: this.videoModel.openVideoFrameObserverWays,
            choose: index => {
              this.videoModel.openVideoFrameObserverWays = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '开启视频数据回调',
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.enableFrameObserver,
                onChange: value => {
                  this.videoModel.enableFrameObserver = value
                  Prompt.showToast({ message: value ? "开启了视频数据回调" : "关闭了视频数据回调"})
                }
              }
            }
          }).visibility(this.isHiddenInMeeting())
          ComposeListItem({
            contentItem: {
              primaryText: '自动开启视频'
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.autoEnableVideo,
                onChange: value => {
                  this.videoModel.autoEnableVideo = value
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '自动订阅视频'
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.autoSubVideo,
                onChange: value => {
                  this.videoModel.autoSubVideo = value
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

        ListItemGroup({ header: this.itemHead('视频主流')}) {

          NetEaseInputLogicDialog({
            title: '采集宽',
            content: String(this.videoModel.mainCaptureWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.mainCaptureWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: '请输入合法的整型'})
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '采集高',
            content: String(this.videoModel.mainCaptureHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.mainCaptureHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: '请输入合法的整型'})
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.sendResolutionArray,
            title: '发送分辨率',
            index: this.videoModel.mainSendResolution,
            choose: index => {
              this.videoModel.mainSendResolution = index
            }
          })
          NetEaseListLogicDialog({
            array: this.colorFormatArray,
            title: 'colorFormat',
            index: this.videoModel.mainStreamColorFormat,
            choose: index => {
              this.videoModel.mainStreamColorFormat = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameMode,
            title: '编码模式',
            index: this.videoModel.mainEncodeFrameMode,
            choose: index => {
              this.videoModel.mainEncodeFrameMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameRate,
            title: '编码帧率',
            index: this.videoModel.mainEncodeFrameRate,
            choose: index => {
              this.videoModel.mainEncodeFrameRate = index
            }
          })

          NetEaseListLogicDialog({
            array: this.cropModeArray,
            title: '裁剪模式',
            index: this.videoModel.mainCropMode,
            choose: index => {
              this.videoModel.mainCropMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.videoSendMirrorArray,
            title: '视频发送镜像',
            index: this.videoModel.mainMirrorMode,
            choose: index => {
              this.videoModel.mainMirrorMode = index
            }
          })
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('视频辅流') }) {

          NetEaseListLogicDialog({
            array: this.sendResolutionArray,
            title: '发送分辨率',
            index: this.videoModel.subSendResolution,
            choose: index => {
              this.videoModel.subSendResolution = index
            }
          })
          NetEaseListLogicDialog({
            array: this.colorFormatArray,
            title: 'colorFormat',
            index: this.videoModel.subStreamColorFormat,
            choose: index => {
              this.videoModel.subStreamColorFormat = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameMode,
            title: '编码模式',
            index: this.videoModel.subEncodeFrameMode,
            choose: index => {
              this.videoModel.subEncodeFrameMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameRate,
            title: '编码帧率',
            index: this.videoModel.subEncodeFrameRate,
            choose: index => {
              this.videoModel.subEncodeFrameRate = index
            }
          })

          NetEaseListLogicDialog({
            array: this.cropModeArray,
            title: '裁剪模式',
            index: this.videoModel.subCropMode,
            choose: index => {
              this.videoModel.subCropMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.videoSendMirrorArray,
            title: '视频发送镜像',
            index: this.videoModel.subMirrorMode,
            choose: index => {
              this.videoModel.subMirrorMode = index
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('屏幕共享') }) {

          NetEaseListLogicDialog({
            array: this.screenResolutionArray,
            title: '屏幕共享分辨率',
            index: this.videoModel.screenSendResolution,
            choose: index => {
              this.videoModel.screenSendResolution = index
            }
          })

          NetEaseListLogicDialog({
            array: this.screenModeArray,
            title: '录屏模式',
            index: this.videoModel.screenMode,
            choose: index => {
              this.videoModel.screenMode = index
            }
          })

          NetEaseListLogicDialog({
            array: this.encodeFrameRate,
            title: '录屏帧率',
            index: this.videoModel.screenFrameRate,
            choose: index => {
              this.videoModel.screenFrameRate = index
            }
          })

          NetEaseInputLogicDialog({
            title: '录屏最小帧率(0使用默认)',
            content: String(this.videoModel.screenMinFrameRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.screenMinFrameRate = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '录屏码率(0使用默认,kbps)',
            content: String(this.videoModel.screenBitRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.screenBitRate = Number.parseInt(value)
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '录屏最小码率(0使用默认)',
            content: String(this.videoModel.screenMinBitRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.screenMinBitRate = Number.parseInt(value)
              }
            }
          })

        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })

        ListItemGroup({ header: this.itemHead('外部主流视频数据')}){

          NetEaseListLogicDialog({
            array: this.externalVideoTypeArray,
            title: '文件类型',
            index: this.videoModel.externalVideoType,
            choose: index => {
              this.videoModel.externalVideoType = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.videoModel.externalVideoPath
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.videoModel.externalVideoPath = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke videoPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          NetEaseInputLogicDialog({
            title: '视频宽',
            content: String(this.videoModel.externalVideoWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalVideoWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '视频高',
            content: String(this.videoModel.externalVideoHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalVideoHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '帧率',
            content: String(this.videoModel.externalVideoFrameRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalVideoFrameRate = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '角度',
            content: String(this.videoModel.externalVideoRotation),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalVideoRotation = Number.parseInt(value)
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

        ListItemGroup({ header: this.itemHead('外部辅流视频数据')}) {

          NetEaseListLogicDialog({
            array: this.externalVideoTypeArray,
            title: '文件类型',
            index: this.videoModel.externalSubVideoType,
            choose: index => {
              this.videoModel.externalSubVideoType = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择文件',
              secondaryText: this.videoModel.externalSubVideoPath
            }
          }).onClick(() => {
            const audioSelectOptions = new picker.DocumentSelectOptions
            const audioPicker = new picker.DocumentViewPicker
            audioPicker.select(audioSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.videoModel.externalSubVideoPath = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke videoPicker select failed, code:${err.code}, message:${err.message}`)
            })
          })

          NetEaseInputLogicDialog({
            title: '视频宽',
            content: String(this.videoModel.externalSubVideoWidth),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalSubVideoWidth = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '视频高',
            content: String(this.videoModel.externalSubVideoHeight),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalSubVideoHeight = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '帧率',
            content: String(this.videoModel.externalSubVideoFrameRate),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalSubVideoFrameRate = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input number.' })
              }
            }
          })

          NetEaseInputLogicDialog({
            title: '角度',
            content: String(this.videoModel.externalSubVideoRotation),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.externalSubVideoRotation = Number.parseInt(value)
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

        ListItemGroup({ header: this.itemHead('虚拟背景')}) {

          ComposeListItem({
            contentItem: {
              primaryText: '虚拟背景',
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.virtualBackgroundEnable,
                onChange: value => {
                  this.videoModel.virtualBackgroundEnable = value
                  Prompt.showToast({ message: value ? '打开虚拟背景': '关闭虚拟背景'})
                }
              }
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '强制开启'
            },
            operateItem: {
              switch: {
                isCheck: this.videoModel.virtualBackgroundForce,
                onChange: value => {
                  this.videoModel.virtualBackgroundForce = value
                  Prompt.showToast({ message: value ? '强制开启':'关闭强制开启'})
                }
              }
            }
          })

          NetEaseListLogicDialog({
            array: this.virtualBackgroundTypeArray,
            title: '虚拟背景类型',
            index: this.videoModel.virtualBackgroundType-1,
            choose: index => {
              this.videoModel.virtualBackgroundType = index+1
            }
          })

          NetEaseListLogicDialog({
            array: this.virtualBackgroundBlurDegreeArray,
            title: '雾化级别',
            index: this.videoModel.virtualBackgroundBlurDegree-1,
            choose: index => {
              this.videoModel.virtualBackgroundBlurDegree = index+1
            }
          })

          NetEaseInputLogicDialog({
            title: 'Color',
            content: String(this.videoModel.virtualBackgroundColor),
            onInputValue: value => {
              if(Number.parseInt(value) != Number.NaN) {
                this.videoModel.virtualBackgroundColor = Number.parseInt(value)
              } else {
                Prompt.showToast({ message: 'please input color.' })
              }
            }
          })


          NetEaseListLogicDialog({
            array: this.virtualBackgroundSourceArray,
            title: '图片',
            index: this.videoModel.virtualBackgroundSourceIndex,
            choose: index => {
              this.videoModel.virtualBackgroundSourceIndex = index
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: '请选择自定义图片',
              secondaryText: this.videoModel.virtualBackgroundSource
            }
          }).onClick(() => {
            const sourceSelectOptions = new picker.DocumentSelectOptions
            const sourcePicker = new picker.DocumentViewPicker
            sourcePicker.select(sourceSelectOptions).then(result => {
              let URI = result[0]
              console.info(this.TAG, 'picker select to file URI: ' + URI)
              this.videoModel.virtualBackgroundSource = URI
            }).catch((err: BusinessError) => {
              console.error(this.TAG, `Invoke sourcePicker select failed, code:${err.code}, message:${err.message}`)
            })
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
