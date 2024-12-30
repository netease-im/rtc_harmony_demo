import { LocalVolumeInfo, LoginInfo, RemoteVolumeInfo, UI } from './chat/ChatModel'
import router from '@ohos.router';
import  ChatPresenter from './chat/Presenter1';
import ChatLogicDelegate, { OPERATOR } from './chat/Delegate';
import DemoUser from '../model/DemoUser';
import { Prompt } from '@kit.ArkUI';
import { MoreFunction } from './chat/dialog/MoreFunction';
import { RTCDemoView } from './chat/dialog/RTCDemoView';
import * as model from '../pages/chat/ChatModel'
import LiveStreamingKit from './LiveStreamingKit';

@Entry
@Component
struct Chat {

  @State uiType: UI = UI.AUDIO
  @Builder
  SelectMenu() {
    Menu() {
      MenuItem({ content: '视频', startIcon: $r('app.media.video_common')})
        .onClick(() => {
           this.uiType = UI.VIDEO
           this.showMoreFunction = true
        })
      MenuItem({ content: '多流', startIcon: $r('app.media.video_multi')})
        .onClick(() => {
          this.uiType = UI.VIDEO_MULTI
          this.showMoreFunction = true
        })
      MenuItem({ content: '音频', startIcon: $r('app.media.audio_common')})
        .onClick(() => {
          this.uiType = UI.AUDIO
          this.showMoreFunction = true
        })
      MenuItem({ content: '其他', startIcon: $r('app.media.other')})
        .onClick(() => {
          this.uiType = UI.OTHER
          this.showMoreFunction = true
        })
    }
  }

  private TAG: string = "MultiChat"
  private preChannel: string = 'Channel-'
  @State users: Array<DemoUser> = [];
  @State title: string = this.preChannel
  @State showMoreFunction: boolean = false
  @State localVolumeInfo: LocalVolumeInfo|null = null
  @State remoteVolumeInfos: RemoteVolumeInfo[]|null = null
  @State localVideoStats: Map<number, string>|null = null
  @State localAudioStats: string = ''
  @State localRtcStats: string = ''
  @State roomNetworkQuality: Map<bigint, string>|null = null
  @State remoteVideoStats: Map<bigint, Map<number, string>>|null = null
  @State remoteAudioStats: Map<bigint, string>|null = null

  private getRemoteVolumeIndication(item: DemoUser): RemoteVolumeInfo|null {
    if(!this.remoteVolumeInfos)
      return null
    let info = this.remoteVolumeInfos.filter(info => {
      return item.uid === info.uid
    })
    return info.length == 0 ? null : info[0]
  }


  uiDelegate: ChatLogicDelegate = {

    update:(operator: OPERATOR, obj: model.DemoLogicMap|DemoUser): void => {

      if((obj instanceof Map) && !DemoUser.checkMapValid(obj)) {
        throw new Error('Map must set uid.')
      }

      // -1: user not found.
      let index = -1
      try {
        index = this.users.findIndex(user => {
          if(obj instanceof DemoUser) {
            return user.uid === obj['uid'] && user.multiStream == obj.multiStream;
          } else {
            return user.uid === obj.get('uid');
          }
        })
      } catch (e) {
        console.error(this.TAG, JSON.stringify(e))
      }

      switch (operator) {
        case OPERATOR.ADD: {
            if(obj instanceof DemoUser) {
              if(index == 0) {
                this.users[0] = obj
              } else if(index < 0) {
                this.users.push(obj)
              }
            }
          } break;
        case OPERATOR.DEL: {
            if(index >= 0) {
              this.users = this.users.filter(user => (user.uid !== obj['uid'] || user.multiStream !== obj['multiStream']))
            }
          } break;
        case OPERATOR.UPD: {

          if(index == -1) {
            console.error(this.TAG, `user not exists, update user failed.`)
            return
          }

          if(obj instanceof DemoUser) {
            if(obj.local) this.users[0] = obj
          } else {
            this.users[index].move(obj)
            this.users[index] = DemoUser.newInstance(this.users[index])
          }
        } break;
      }
    },

    error:(errMsg: string): void => {
      Prompt.showToast({ message: errMsg, duration: 2000 })
    },

    localVolume: (volumeInfo: LocalVolumeInfo): void => {
      this.localVolumeInfo = volumeInfo
    },

    remoteVolume: (volumeInfo: RemoteVolumeInfo[], totalVolume: number): void => {
      this.remoteVolumeInfos = volumeInfo
    },

    changeTitle: (cname: string): void => {
      this.title = this.preChannel + cname
    },

    localVideoStats: (stats: Map<number, string>): void => {
      this.localVideoStats = stats
    },

    localAudioStats :(stat: string): void => {
      this.localAudioStats = stat
    },

    localRtcStats :(stat: string): void => {
      this.localRtcStats = stat
    },

    roomNetWorkQuality :(infos: Map<bigint, string>): void => {
      this.roomNetworkQuality = infos
    },

    remoteVideoStats :(stats: Map<bigint, Map<number, string>>): void => {
      this.remoteVideoStats = stats
    },

    remoteAudioStats: (stats: Map<bigint, string>): void => {
      this.remoteAudioStats = stats
    }
  }

  aboutToAppear(): void {
    ChatPresenter.getInstance().setDelegate(this.uiDelegate)
    console.info(this.TAG, '=== aboutToAppear ===')
    let login = router.getParams() as LoginInfo
    this.title += login?.cname ?? ""
    console.info(this.TAG, `title: ${this.title}`)
    ChatPresenter.getInstance().setDir(getContext(this).filesDir)

    //Ensure local rtcVideoView load success.
    let local: DemoUser = new DemoUser(BigInt(login?.uid), true)
    this.users[0] = local
  }

  onBackPress(): boolean | void {

    if(this.showMoreFunction) {
      this.showMoreFunction = false
      return true
    }

    console.info(this.TAG, '==== Chat page backpress ===')
    ChatPresenter.getInstance().removeDelegate(this.uiDelegate)
    if(ChatPresenter.getInstance().getType() == 0)
      ChatPresenter.getInstance().leave()
    else if(ChatPresenter.getInstance().getType() == 1) {
      if(LiveStreamingKit.getInstance().getPKState() == LiveStreamingKit.kPKStateIdle && LiveStreamingKit.getInstance().getSeatState() == LiveStreamingKit.kSeatStateStateIdle)
        ChatPresenter.getInstance().stopPushStreaming()
      else
        LiveStreamingKit.getInstance().clearPKAndSeat()
      console.log("liveStreamKit stopPushStreaming")
    }
    ChatPresenter.getInstance().enableVideo(false)
  }

  build() {
    Row() {
      Column() {
        Flex({ direction: FlexDirection.Column }) {
          Text(this.title)
            .margin({ top: 22, left: 5 })
            .width('100%')
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Start)
            .bindMenu(this.SelectMenu)
            .clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.5 })

          Stack({ alignContent: Alignment.Bottom }) {
            Grid(){
              ForEach(this.users, (item: DemoUser) => {
                GridItem() {
                  Stack({ alignContent: Alignment.TopStart }) {
                    Stack({ alignContent: Alignment.BottomEnd }) {
                      RTCDemoView(
                        {
                          rtcViewId: item.multiStream == null ? item.xComponentIdMain : (item.multiStream == "third" ? item.xComponentIdThird : item.xComponentIdFourth ),
                          local: this.users[0].uid === item.uid,
                          attach: () => {
                            console.info(this.TAG, `View:${item.multiStream} surface create.`)
                            let user = this.users.find(user => user.uid == item.uid && user.multiStream == item.multiStream)
                            if(user) ChatPresenter.getInstance().attach(user, user.multiStream)
                          },
                          detach: () => {
                            let user = this.users.find(user => user.uid == item.uid && user.multiStream == item.multiStream)
                            if(user) ChatPresenter.getInstance().detach(user, user.multiStream)
                          },
                          snapshot: () => {
                            item.turnToMainStream()
                            //延迟1s，不然会截到弹框
                            setTimeout(() => {
                              ChatPresenter.getInstance().takeSnapShot(item)
                            }, 1000)
                          },
                          mirror: () => {
                            item.turnToMainStream().switchCanvasMirror()
                            ChatPresenter.getInstance().changeCanvasStyle(item)
                          },
                          scaleMode: () => {
                            item.turnToMainStream().changeScaleModeLoop()
                            ChatPresenter.getInstance().changeCanvasStyle(item)
                          }
                        }
                      ).width(item.widthMain).height(item.heightMain)

                      if(item.xComponentIdSub) {
                        RTCDemoView({
                          rtcViewId: item.xComponentIdSub,
                          local: this.users[0].uid === item.uid,
                          attach: () => {
                            let user = this.users.find(user => user.uid == item.uid)
                            console.info(this.TAG, 'user: ' + user?.xComponentIdSub)
                            if(user) ChatPresenter.getInstance().attachSub(user)
                          },
                          snapshot: () => {
                            item.turnToSubStream()
                            setTimeout(() => {
                              ChatPresenter.getInstance().takeSnapShot(item)
                            }, 1000)
                          },
                          mirror: () => {
                            item.turnToSubStream().switchCanvasMirror()
                            ChatPresenter.getInstance().changeCanvasStyle(item)
                          },
                          scaleMode: () => {
                            item.turnToSubStream().changeScaleModeLoop()
                            ChatPresenter.getInstance().changeCanvasStyle(item)
                          }
                        }).width(item.widthSub).height(item.heightSub)
                      }
                    }

                    Column() {
                      Text(`uid:${item.uid}`)
                        .width('100%')
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Start)
                        .fontSize(14)
                        .margin(5)

                      /**
                       * === local ===
                       */
                      if(item.local && this.localVolumeInfo) {
                        Text(`麦克风音量:${this.localVolumeInfo?.volume ?? '0'}, vadFlag:${this.localVolumeInfo?.vad ?? '0'}`)
                          .width('100%')
                          .fontSize(10)
                          .fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && !item.multiStream && this.localVideoStats) {
                        Text(this.localVideoStats.get(0)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && item.multiStream == 'third' && this.localVideoStats) {
                        Text(this.localVideoStats.get(1)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && item.multiStream == 'fourth' && this.localVideoStats) {
                        Text(this.localVideoStats.get(2)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && this.localAudioStats) {
                        Text(this.localAudioStats).width('100%').fontSize(10).fontColor(Color.Blue)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && this.localRtcStats) {
                        Text(this.localRtcStats).width('100%').fontSize(10).fontColor(Color.Green)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (item.local && this.roomNetworkQuality) {
                        Text(this.roomNetworkQuality.get(item.uid)).width('100%').fontSize(10).fontColor(Color.Yellow)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      /**
                       * === remote ===
                       */
                      // 这里偷下懒，可以默认将 this.localVolumeInfo 看作用户是否有开启音量回调
                      if(!item.local && this.localVolumeInfo) {
                        Text(`麦克风音量:${this.getRemoteVolumeIndication(item)?.volume ?? '0'}`)
                          .width('100%')
                          .fontSize(10)
                          .fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(5)
                      }

                      if (!item.local && item.multiStream == null && this.remoteVideoStats) {
                        Text(this.remoteVideoStats.get(item.uid)?.get(0)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (!item.local && item.multiStream == 'third' && this.remoteVideoStats) {
                        Text(this.remoteVideoStats.get(item.uid)?.get(1)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (!item.local && item.multiStream == 'fourth' && this.remoteVideoStats) {
                        Text(this.remoteVideoStats.get(item.uid)?.get(2)).width('100%').fontSize(10).fontColor(Color.Red)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (!item.local && this.remoteAudioStats) {
                        Text(this.remoteAudioStats.get(item.uid)).width('100%').fontSize(10).fontColor(Color.Blue)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                      if (!item.local && this.roomNetworkQuality) {
                        Text(this.roomNetworkQuality.get(item.uid)).width('100%').fontSize(10).fontColor(Color.Yellow)
                          .textAlign(TextAlign.Start)
                          .margin(2)
                      }

                    }
                  }
                }.width('50%').height(250).margin({top: 10})
              }, (item: DemoUser) => item.generatorId())
            }.width('100%').height('100%').cachedCount(4).columnsGap(15).columnsTemplate('1fr 1fr')
            if(this.showMoreFunction) {
              MoreFunction({ uiType: $uiType, turnToSetting: () => {
                let setting: model.SettingInfo = {
                  reInit: false
                }
                router.pushUrl({ url: 'pages/Settings', params: setting }, err => {
                  if(err) {
                    Prompt.showToast({ message: `turn to setting failed, err:${err.message}`})
                  }
                })
              }})
            }
          }.width('100%').height('100%')
        }
      }
      .width('100%')
    }
    .height('100%')
  }
}