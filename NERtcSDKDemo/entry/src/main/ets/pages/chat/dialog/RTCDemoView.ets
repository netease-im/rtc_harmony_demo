import { NERtcVideoView } from '@nertc/nertc_sdk'
import { SelectDialog } from '@kit.ArkUI';

@Component
export struct RTCDemoView {

  private TAG: string = "RTCDemoView"

  rtcViewId: string = ""
  local: boolean = false
  attach?: () => void;
  snapshot?: () => void;
  mirror?:() => void;
  scaleMode?:() => void;

  canvasLongPressDialog: CustomDialogController|null = new CustomDialogController({
    builder: SelectDialog({
      title: '操作',
      selectedIndex: 0,
      radioContent: [
        {
          title: '截图',
          action: () => {
            this.canvasLongPressDialog?.close()
            if(this.snapshot) {
              this.snapshot()
            }
          }
        },
        {
          title: '渲染镜像',
          action: () => {
            this.canvasLongPressDialog?.close()
            if(this.mirror) {
              this.mirror()
            }
          }
        },
        {
          title: '缩放模式',
          action: () => {
            this.canvasLongPressDialog?.close()
            if(this.scaleMode) this.scaleMode()
          }
        }
      ]
    }),
    width: '80%',
    cornerRadius: 10
  })

  onBackPress(): boolean | void {
    this.canvasLongPressDialog?.close()
    this.canvasLongPressDialog = null
  }

  build() {
    NERtcVideoView({
      canvasId: this.rtcViewId,
      onLoad: (() => {
        if(this.attach) {
          this.attach()
        }
      }),
      onDestroy: (() => {
        console.info(this.TAG, `id:${this.rtcViewId} surface release.`)
      })
    }).gesture(LongPressGesture({repeat: false})
      .onAction(() => {
        this.canvasLongPressDialog?.open()
      }))
  }
}