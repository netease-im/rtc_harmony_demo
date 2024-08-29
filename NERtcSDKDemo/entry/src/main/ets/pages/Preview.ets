import DemoUser from '../model/DemoUser';
import ChatPresenter from './chat/Presenter1';
import { RTCDemoView } from './chat/dialog/RTCDemoView';
import { router } from '@kit.ArkUI';
import { LoginInfo } from './chat/ChatModel';

@Entry
@Component
struct Preview {

  @State localUser: DemoUser|null = null

  onPageShow(): void {
    let login = router.getParams() as LoginInfo
    ChatPresenter.getInstance().startPreview(login)
    this.localUser = new DemoUser(BigInt(login.uid), true)
  }

  build() {
    RelativeContainer() {
      if(this.localUser) {
        RTCDemoView({
          rtcViewId: this.localUser?.xComponentIdMain,
          local: true,
          attach: () => {
            if(this.localUser) {
              ChatPresenter.getInstance().attach(this.localUser)
            }
          },
          snapshot: () => {
            setTimeout(() => {
              if(this.localUser) {
                ChatPresenter.getInstance().takeSnapShot(this.localUser)
              }
            }, 1000)
          },
          mirror: () => {
            if(this.localUser) {
              this.localUser.switchCanvasMirror()
              ChatPresenter.getInstance().changeCanvasStyle(this.localUser)
            }
          },
          scaleMode: () => {
            if(this.localUser) {
              this.localUser.changeScaleModeLoop()
              ChatPresenter.getInstance().changeCanvasStyle(this.localUser)
            }
          }
        }).width('100%').height('100%')
      }
    }
    .height('100%')
    .width('100%')
  }
}