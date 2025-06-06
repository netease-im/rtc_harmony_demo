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
    let multiStream: "third" | "fourth" | null = null
    let streamType: number = ChatPresenter.getInstance().getCurrentStreamType()
    if(streamType == 2){
      multiStream = "third"
    }else if(streamType == 3){
      multiStream = "fourth"
    }
    this.localUser = new DemoUser(BigInt(login.uid), true, multiStream)
    if(streamType == 1){
      this.localUser.xComponentIdSub = this.localUser.generatorSubCanvasId()
    }
  }

  onBackPress(): boolean | void {
    ChatPresenter.getInstance().stopPreview()
  }

  build() {
    RelativeContainer() {
      if(this.localUser) {
        RTCDemoView({
          rtcViewId: this.localUser.xComponentIdSub != null ? this.localUser.xComponentIdSub : this.localUser.multiStream == null ? this.localUser.xComponentIdMain : (this.localUser.multiStream == "third" ? this.localUser.xComponentIdThird : this.localUser.xComponentIdFourth ),
          local: true,
          attach: () => {
            if(this.localUser?.xComponentIdSub){
              ChatPresenter.getInstance().attachSub(this.localUser)
            }
            else if(this.localUser) {
              ChatPresenter.getInstance().attach(this.localUser, this.localUser.multiStream)
            }
          },
          detach: () => {
            if (this.localUser) {
              ChatPresenter.getInstance().detach(this.localUser, this.localUser.multiStream)
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