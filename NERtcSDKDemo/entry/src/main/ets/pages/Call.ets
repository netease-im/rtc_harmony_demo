import router from '@ohos.router';
import { ChatResult, LoginInfo } from './chat/ChatModel'
import * as model from './chat/ChatModel'
import { NERtcVideoView } from '@nertc/nertc_sdk';
import  ChatPresenter  from './chat/Presenter1';
import DemoUser from '../model/DemoUser';
import ChatNotify, { OPERATOR } from './chat/Delegate';
import Prompt from '@system.prompt';
import common from '@ohos.app.ability.common';

import { NERtcConstants, NERtcSDK} from '@nertc/nertc_sdk/Index';

class MyDataSource implements IDataSource {
  private list: number[] = []

  constructor(list: number[]) {
    this.list = list
  }

  totalCount(): number {
    return this.list.length
  }

  getData(index: number): number {
    return this.list[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
  }

  unregisterDataChangeListener() {
  }
}


@Entry
@Component
struct Call {

  TAG: string = "CallPage"
  @State
  login?: LoginInfo = undefined
  chat?: ChatPresenter
  @State
  users: Array<DemoUser> = []

  @State
  bigCanvas: Length = '100%'
  @State
  smallCanvas: Length = 200

  @State
  bigZIndex: number = 1
  @State
  smallZIndex: number = 2

  viewSwitched : boolean = false;

  private swiperController: SwiperController = new SwiperController()
  private data: MyDataSource = new MyDataSource([])


  aboutToAppear(): void {
    let list: number[] = []
    for (let i = 1; i <= 2; i++) {
      list.push(i);
    }
    this.data = new MyDataSource(list)
  }


  uiDelegate: ChatNotify = {

    update:(operator: OPERATOR, obj: model.DemoLogicMap|DemoUser): void => {
      // let user = this.users.find(user => user.uid === demoUser.uid)
      // if(operator == OPERATOR.ADD) {
      //   if(!user) {
      //     if(demoUser.uid == BigInt(this.login?.uid ?? "0")) this.users[0] = demoUser
      //     if(demoUser.uid != BigInt(this.login?.uid ?? "0")) this.users.push(demoUser)
      //   } else {
      //     console.warn(`${demoUser.uid} is exist, ignore.`)
      //   }
      // }
      // if(operator == OPERATOR.DEL) {
      //   if(user) {
      //     this.users = this.users.filter(user => user.uid !== demoUser.uid)
      //
      //       let randomNum : number = Math.round(Math.random());
      //
      //       let useSetNull : boolean = false;
      //       if (randomNum > 0) {
      //         useSetNull = true;
      //       }
      //
      //       if (useSetNull) {
      //         let canvasEmptyRemote: NERtcConstants.NERtcVideoCanvas = { canvasId: "" }
      //         let remote_user_id : BigInt =  user.uid
      //         NERtcSDK.getInstance().setupRemoteVideoCanvas(canvasEmptyRemote, remote_user_id)
      //       }
      //
      //     console.info(this.TAG, `userleave num:${randomNum} useSetNull:${useSetNull}`)
      //
      //     this.resetViewPostion();
      //   } else {
      //     console.warn(`${demoUser.uid} is not exist, ignore.`)
      //   }
      // }
    },

    error:(errMsg: string): void => {
      Prompt.showToast({ message: errMsg, duration: 2000 })
    }
  }

  onPageShow() {
    console.info(this.TAG, '=== CallPage show ===')
    this.login = router.getParams() as LoginInfo
    let context = getContext(this) as common.UIAbilityContext
    let filesDir = context.filesDir
    this.login.logDir = filesDir
    this.login.context = getContext(this)

    this.chat = ChatPresenter.getInstance()
    let local = new DemoUser(BigInt(this.login?.uid))
    this.users[0] = local

    this.chat?.setDelegate(this.uiDelegate)
  }


  onBackPress() {
    console.info(this.TAG, '==== CallPage backpress ===')
    this.chat?.removeDelegate(this.uiDelegate)
    this.chat?.leave()
    this.chat?.enableVideo(false)
  }


  resetViewPostion(){
    if (!this.viewSwitched) {
      return;
    }


    let randomNum : number = Math.round(Math.random());

    let useSetNull : boolean = false;
    if (randomNum > 0) {
      useSetNull = true;
    }

    console.info(this.TAG, `resetViewPostion num:${randomNum} useSetNull:${useSetNull}`)

    //set local empty
    if (useSetNull) {
      let canvasEmpty: NERtcConstants.NERtcVideoCanvas = { canvasId: "" }
      NERtcSDK.getInstance().setupLocalVideoCanvas(null)
    }

    //set remote empty
    if (this.login) {
      let canvasLocal: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[0].xComponentIdMain}
      NERtcSDK.getInstance().setupLocalVideoCanvas(canvasLocal)
    }

    if(this.users[1]){
      let remote_user_id : BigInt =  this.users[1].uid
      let canvasRemote: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[1].xComponentIdMain}
      NERtcSDK.getInstance().setupRemoteVideoCanvas(canvasRemote, remote_user_id)
    }

    this.viewSwitched = false;
  }


  // attach(user: DemoUser): void {
  //
  //   let canvas: NERtcConstants.NERtcVideoCanvas = { canvasId: user.xComponentId }
  //   let isMe = user.uid.toString() === login_?.uid
  //   let ret: number;
  //   if(isMe) {
  //     ret = NERtcSDK.getInstance().setupLocalVideoCanvas(canvas)
  //   } else {
  //     ret = NERtcSDK.getInstance().setupRemoteVideoCanvas(canvas, user.uid)
  //   }
  //   console.info(TAG, `uid:${user.uid} setup canvas ret:${ret}`)
  // }


  build() {
    Row() {
      Column() {
        Flex({ direction: FlexDirection.Column }) {
          Stack({ alignContent: Alignment.TopEnd }){

            Column() {
              if(this.users[0]) {
                Swiper(this.swiperController) {
                  LazyForEach(this.data, (item: string) => {
                    if(item == "1") {
                      NERtcVideoView({
                        canvasId: this.users[0].xComponentIdMain,
                        onLoad: (() => {
                          console.info(this.TAG, `item:${item}`)
                          console.info(this.TAG, `User:${this.login?.uid} surface create.`)
                          let user = this.users.find(user => user.uid == BigInt(this.login?.uid ?? "0"))
                          if(user) this.chat?.attach(user, user.multiStream)
                        }),
                        onDestroy: (() => {
                          console.info(this.TAG, `User:${this.login?.uid} surface release.`)
                          // this.resetViewPostion();
                        })
                      })
                    }
                  })
                }
              }
            }.width(this.bigCanvas).height(this.bigCanvas).zIndex(this.bigZIndex)

            Column() {
              if(this.users[1]) {
                NERtcVideoView({
                  canvasId: this.users[1].xComponentIdMain,
                  onLoad: (() => {
                    if(this.users[1]) {
                      console.info(this.TAG, `User:${this.users[1].uid} surface create.`)
                      this.chat?.attach(this.users[1], this.users[1].multiStream)
                    }
                  }),
                  onDestroy: (() => {
                    if(this.users[1]) {
                      console.info(this.TAG, `User:${this.users[1].uid} surface release.`)
                    }
                  })
                })
              }
            }.width(this.smallCanvas).height(this.smallCanvas).zIndex(this.smallZIndex)

            Column() {
              Button("switch", { type: ButtonType.Normal, stateEffect: true}).onClick(() => {

                if (!this.users[1] || !this.login) {
                  return;
                }

                this.viewSwitched = !this.viewSwitched;


                let randomNum : number = Math.round(Math.random());

                let useSetNull : boolean = false;
                if (randomNum > 0) {
                   useSetNull = true;
                }

                console.info(this.TAG, `num:${randomNum} useSetNull:${useSetNull}`)

                let remote_user_id : BigInt =  this.users[1].uid
                // //set local empty
                if (useSetNull) {
                  let canvasEmpty: NERtcConstants.NERtcVideoCanvas = { canvasId: "" }
                  NERtcSDK.getInstance().setupLocalVideoCanvas(null)

                  //set remote empty
                  let canvasEmptyRemote: NERtcConstants.NERtcVideoCanvas = { canvasId: "" }
                  NERtcSDK.getInstance().setupRemoteVideoCanvas(null, remote_user_id)
                }

                if (this.viewSwitched) {
                  let canvasLocal: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[1].xComponentIdMain }
                  NERtcSDK.getInstance().setupLocalVideoCanvas(canvasLocal)

                  let canvasRemote: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[0].xComponentIdMain}
                  NERtcSDK.getInstance().setupRemoteVideoCanvas(canvasRemote, remote_user_id)

                }else {
                  let canvasLocal: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[0].xComponentIdMain }
                  NERtcSDK.getInstance().setupLocalVideoCanvas(canvasLocal)

                  let canvasRemote: NERtcConstants.NERtcVideoCanvas = { canvasId: this.users[1].xComponentIdMain}
                  NERtcSDK.getInstance().setupRemoteVideoCanvas(canvasRemote, remote_user_id)
                }

              })
            }.width(100).height(100).zIndex(3)

          }
        }
      }
      .width('100%')
    }
    .height('100%')
  }

}