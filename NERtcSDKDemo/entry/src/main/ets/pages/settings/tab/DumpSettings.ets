import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import Prompt from '@system.prompt';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DumpModel } from '../model/common';
import { NetEaseListLogicDialog } from '../view/NetEaseListLogicDialog';
import { NetEaseInputLogicDialog } from '../view/NetEaseInputLogicDialog';

@Component
export struct DumpSetting {
  @Link dumpModel: DumpModel

  private dumpCaptureYuvMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpCaptureYuvMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']
  private dumpCaptureYuvInterval: string[] = ['每帧', '每半秒', '每秒', '每2秒']

  private dumpEncodeYuvMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpEncodeYuvMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']
  private dumpEncodeYuvInterval: string[] = ['每帧', '每半秒', '每秒', '每2秒']

  private dumpEncodedYuvMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpEncodedYuvMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']

  private dumpDecodeVideoMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpDecodeVideoMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']

  private dumpDecodedYuvMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpDecodedYuvMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']
  private dumpDecodedYuvInterval: string[] = ['每帧', '每半秒', '每秒', '每2秒']

  private dumpPostProcessedYuvMode: string[] = ['0 正常模式', '1 Dump数据', '2 替换数据（打开重进房间生效）']
  private dumpPostProcessedYuvMaxMB: string[] = ['256MB', '512MB', '1GB', '2GB', '4GB']
  private dumpPostProcessedYuvInterval: string[] = ['每帧', '每半秒', '每秒', '每2秒']

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
        ListItemGroup({ header: this.itemHead('视频 Dump')}) {
            ComposeListItem({
              contentItem: {
                primaryText: '开启视频Dump',
                secondaryText: ''
              },
              operateItem: {
                switch: {
                  isCheck: this.dumpModel.enableVideoDump,
                  onChange: value => {
                    this.dumpModel.enableVideoDump = value
                  }
                }
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpCaptureYuvMode,
              title: 'Dump 采集Yuv',
              index: this.dumpModel.enableDumpCapturedYUV,
              choose: index => {
                this.dumpModel.enableDumpCapturedYUV = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpCaptureYuvMaxMB,
              title: 'Dump 采集Yuv 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpCapturedYUVMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpCapturedYUVMB = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpCaptureYuvInterval,
              title: 'Dump 采集Yuv 间隔',
              index: this.dumpModel.dumpCapturedYUVInterval,
              choose: index => {
                this.dumpModel.dumpCapturedYUVInterval = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpEncodeYuvMode,
              title: 'Dump 编码前YUV',
              index: this.dumpModel.enableDumpEncodeYUV,
              choose: index => {
                this.dumpModel.enableDumpEncodeYUV = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpEncodeYuvMaxMB,
              title: 'Dump 编码前YUV 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpEncodeYUVMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpEncodeYUVMB = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpEncodeYuvInterval,
              title: 'Dump 编码前YUV 间隔',
              index: this.dumpModel.dumpEncodeYUVInterval,
              choose: index => {
                this.dumpModel.dumpEncodeYUVInterval = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpEncodedYuvMode,
              title: 'Dump 编码后YUV',
              index: this.dumpModel.enableDumpEncodedVideo,
              choose: index => {
                this.dumpModel.enableDumpEncodedVideo = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpEncodedYuvMaxMB,
              title: 'Dump 编码后YUV 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpEncodedVideoMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpEncodedVideoMB = index
              }
            })


            NetEaseListLogicDialog({
              array: this.dumpDecodeVideoMode,
              title: 'Dump 接受到的视频',
              index: this.dumpModel.enableDumpDecodeVideo,
              choose: index => {
                this.dumpModel.enableDumpDecodeVideo = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpDecodeVideoMaxMB,
              title: 'Dump 编码前YUV 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpDecodeVideoMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpDecodeVideoMB = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpDecodeVideoMode,
              title: 'Dump 接收的视频',
              index: this.dumpModel.enableDumpDecodeVideo,
              choose: index => {
                this.dumpModel.enableDumpDecodeVideo = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpDecodeVideoMaxMB,
              title: 'Dump 接收的视频 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpDecodeVideoMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpDecodeVideoMB = index
              }
            })

            //解码后
            NetEaseListLogicDialog({
              array: this.dumpDecodedYuvMode,
              title: 'Dump 解码后YUV',
              index: this.dumpModel.enableDumpDecodedYUV,
              choose: index => {
                this.dumpModel.enableDumpDecodedYUV = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpDecodedYuvMaxMB,
              title: 'Dump 解码后YUV 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpDecodedYUVMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpDecodedYUVMB = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpDecodedYuvInterval,
              title: 'Dump 解码后YUV 间隔',
              index: this.dumpModel.dumpDecodedYUVInterval,
              choose: index => {
                this.dumpModel.dumpDecodedYUVInterval = index
              }
            })

            //后处理
            NetEaseListLogicDialog({
              array: this.dumpPostProcessedYuvMode,
              title: 'Dump 后处理后YUV',
              index: this.dumpModel.enableDumpPostProcessedYUV,
              choose: index => {
                this.dumpModel.enableDumpPostProcessedYUV = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpPostProcessedYuvMaxMB,
              title: 'Dump 后处理后YUV 最大使用空间',
              index: this.dumpModel.maxSpaceForDumpPostProcessedYUVMB,
              choose: index => {
                this.dumpModel.maxSpaceForDumpPostProcessedYUVMB = index
              }
            })

            NetEaseListLogicDialog({
              array: this.dumpPostProcessedYuvInterval,
              title: 'Dump 后处理后YUV 间隔',
              index: this.dumpModel.dumpPostProcessedYUVInterval,
              choose: index => {
                this.dumpModel.dumpPostProcessedYUVInterval = index
              }
            })
          }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })
      }
    }
  }
}
