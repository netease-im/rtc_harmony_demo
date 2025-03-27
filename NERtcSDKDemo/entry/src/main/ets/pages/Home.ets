import prompt from '@ohos.promptAction';
import router from '@ohos.router';
import * as model from './chat/ChatModel'
import AbilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { LoadingDialog } from '@ohos.arkui.advanced.Dialog'
import { NetEaseProbeLoginDialog } from '../pages/home/dialog/StartProbeDialog'
import SDK from './chat/Presenter1'
import UIDelegate, { OPERATOR } from './chat/Delegate';
import DemoUser from '../model/DemoUser';
import { NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk';
import ChatPresenter from './chat/Presenter1';
import fs from '@ohos.file.fs';
import { bundleManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Prompt from '@system.prompt';
import http from '@ohos.net.http'

@Entry
@Component
struct Home {

  @Builder
  MoreMenu() {
    Menu() {
      MenuItem({ content: "更多", startIcon: $r('app.media.more'), endIcon: $r('app.media.right_arrow')})
        .onClick(() => {
          let setting: model.SettingInfo = {
            reInit: true
          }
          router.pushUrl({ url: 'pages/Settings', params: setting }, err => {
            if(err) {
              prompt.showToast({ message: 'turn to settings failed.', duration: 2000 })
            }
            console.info(this.TAG, 'turn to settings success.')
          })
        })
      MenuItem({ content: "关于", startIcon: $r('app.media.about'), endIcon: $r('app.media.right_arrow') })
        .onClick(() => {
          router.pushUrl({ url: 'pages/About'}, err => {
            if(err) {
              prompt.showToast({ message: 'turn to about pages filed.', duration: 2000 })
            }
          })
        })
    }
  }

  TAG: string = "Home"
  @State cname: string = ""
  @State uid: string = ""
  chat?: ChatPresenter
  private randomUID: number = 475834
  @State customEncryptEnabled: boolean = false
  @State sm4EncryptEnabled: boolean = false
  @State networkQuality: number|null = null
  @State networkResult: NERtcConstants.NERtcProbeResult|null = null
  @State probeEnd: boolean = false
  @State safeMode: boolean = true
  private rtcEngineInitDone: boolean = false

  delegate: UIDelegate = {

    update:(operator: OPERATOR, user: model.DemoLogicMap|DemoUser): void => {

      let userId: string = ''
      if(user instanceof DemoUser) {
        userId = String(user.uid)
      } else {
        userId = String(user.get('uid'))
      }

      //fix issue for OMNRTCG2-58636
      if(this.uid == '0')
        this.uid = userId

      if(this.uid == userId && operator == OPERATOR.ADD) {
        this.joinRoomDialog.close()
        this.transToChat()
      }
    },

    error:(errMsg: string): void => {
      prompt.showToast({ message: errMsg, duration: 2000 })
      this.joinRoomDialog.close()
    },

    networkQuality:(quality: number|null, result: NERtcConstants.NERtcProbeResult|null): void => {
      if(quality) {
        this.networkQuality = quality
      }
      if(result) {
        this.networkResult = result
      }
      this.probeEnd = (this.networkQuality && this.networkResult) ? true: false
    }
  }

  joinRoomDialog: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: "正在加入房间"
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  InitEngineDialog: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: "正在初始化引擎"
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  networkQualityDialog: CustomDialogController = new CustomDialogController({
    builder: NetEaseProbeLoginDialog({
      networkQuality: this.networkQuality,
      networkResult: this.networkResult,
      probeEnd: this.probeEnd,
      probeReset: () => {
        this.networkQuality = null
        this.networkResult = null
        this.probeEnd = false
      }
    }),
    autoCancel: false,
    customStyle: false,
    alignment: DialogAlignment.Center,
    borderWidth: 5,
    cornerRadius: 10
  })

  aboutToAppear(): void {
    console.info(this.TAG, '=== aboutToAppear ===')
    this.randomUID = Math.floor(Math.random() * 90000) + 10000;
  }

  onPageShow() {
    console.info(this.TAG, '=== onPageShow === ')
    this.checkAccessToken()
    this.RequestPermission()

    try {
      let dir: string = getContext(this).filesDir + "/media"
      if(!fs.accessSync(dir)) {
        fs.mkdirSync(dir)
        console.info(this.TAG, ' === Dest dir mkdir === ')
      }

      this.copyAssets(dir, 'input_48k_ch2.opus')
      this.copyAssets(dir, 'test.h264')
      this.copyAssets(dir, 'output.h264')

      for (let i = 0; i < 6; i++) {
        let file_name = "image_vb_sample_" + i + ".jpg";
        this.copyVirtualBackgroundResources(dir, file_name);
      }

      //copy beauty.
      let beautyDir: string = getContext(this).filesDir + "/beauty"
      if (!fs.accessSync(beautyDir)) {
        fs.mkdirSync(beautyDir)
        console.info(this.TAG, '=== Beauty dir mkdir ===')
      }

      this.copyAssets(beautyDir, 'ai_face_processor.bundle')
      this.copyAssets(beautyDir, 'face_beautification.bundle')
      this.copyAssets(beautyDir, 'ai_human_processor.bundle')
      this.copyAssets(beautyDir, 'face_makeup.bundle')
    } catch (e) {
      console.info(this.TAG, 'copy asserts failed.')
    } finally {
      SDK.getInstance().setDir(getContext(this).filesDir);// must set filesDir before init
      SDK.getInstance().setDelegate(this.delegate)
    }
  }

  private InitRtcEngine() {
    if (!this.rtcEngineInitDone) {
      //load application safeMode.
      this.safeMode = SDK.getInstance().GetLogicDataModel().GetDemoSafeMode()
      console.info(this.TAG, `init engine start, demo use safeMode:${this.safeMode}`)

      SDK.getInstance().init(getContext(this))
      console.info(this.TAG, 'init engine end.')
      this.rtcEngineInitDone = true
    } else {
      console.info('rtc engine has init already.')
    }
  }

  private async copyAssets(file_path: string, file_name: string) {
    try {
      let file_ready = false
      let file: string = file_path + "/" + file_name
      if(fs.accessSync(file)) {
        console.info(this.TAG, 'file: ' + file + ", is already exists, path: " + file_path)
        file_ready = true
      }

      if(!file_ready) {
        getContext(this).resourceManager.getRawFileContent(file_name).then(data => {
          let writeLen = fs.createStreamSync(file, 'w').writeSync(data.buffer)
          console.info(this.TAG, 'write pcm file len: ' + writeLen)
        })
      }
    } catch (e) {
      console.error(this.TAG, 'copy assets file failed, message: ' + JSON.stringify(e))
    }
  }

  private copyVirtualBackgroundResources(folder_path: string, file_name: string): void {
    try {
      let file_ready = false;
      let file_path: string = folder_path + "/" + file_name;
      console.info(this.TAG, `will begin copy file, folder_path:${folder_path}, file_name:${file_name}`);
      if (fs.accessSync(file_path)) {
        console.info(this.TAG, 'file: ' + file_name + ", is already exists, path: " + file_path);
        file_ready = true;
      }

      if (!file_ready) {
        let vb_file_path: string = "vb/" + file_name;
        getContext(this).resourceManager.getRawFileContent(vb_file_path).then(data => {
          let writeLen = fs.createStreamSync(file_path, 'w').writeSync(data.buffer);
          console.info(this.TAG, `write file:${file_name}, len:${writeLen}`);
        }).catch((err: BusinessError) => {
          console.error(this.TAG, `write file failed, err:${err.message}, code:${err.code}`);
        });
      }
    } catch (e) {
      console.error(this.TAG, 'copy assets file failed, message: ' + JSON.stringify(e));
    }
  }

  onPageHide(): void {
    SDK.getInstance().removeDelegate(this.delegate)
  }

  aboutToDisappear(): void {
    SDK.getInstance().release()
  }

  build() {
    Row() {
      Column() {
        Flex({ direction: FlexDirection.Column }) {
          Flex( { direction: FlexDirection.Row, alignContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
            Text('NERtcDemo')
              .fontSize(50)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Start)
              .padding(20)

            Image($r('app.media.setting'))
              .width(30)
              .height(30)
              .bindMenu(this.MoreMenu)
              .clickEffect({level: ClickEffectLevel.HEAVY, scale: 0.5})
          }
          .width('100%')
          .margin({ top: 22 })

          TextInput({ text: String(this.randomUID) })
            .showUnderline(true)
            .onChange((value: string) => {
              this.uid = value
            })
            .margin({top: 30, left: 10, right: 10 })
            .copyOption(CopyOptions.LocalDevice)

          TextInput({placeholder: "Please input channel name."})
            .showUnderline(true)
            .onChange((value: string) => {
              this.cname = value;
            })
            .margin({ top: 20, left: 10, right: 10 })
            .copyOption(CopyOptions.LocalDevice)

          Toggle({ type: ToggleType.Button , isOn: this.safeMode }) {
            Text('安全模式').fontColor(Color.White).fontSize(16)
          }.width(106) .selectedColor('#336600').onChange((isOn: boolean) => {
            Prompt.showToast({ message: `安全模式已${isOn ? '打开':'关闭'}`})
            this.safeMode = isOn
            SDK.getInstance().GetLogicDataModel().SaveDemoSaveMode(this.safeMode)
          }).margin({ top: 20, left: 10 }).padding(5)

          Row({ space: 35}) {
              Button("入会", { type: ButtonType.Normal, stateEffect: true})
                .onClick(() => {
                  this.joinRoomDialog.open()
                  setTimeout(() => {
                    this.JoinRoom()
                  }, 500)
                })
                .width('35%')
                .height(60)
                .fontSize(18)
                .borderRadius(10)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.5 })

              Button("预览", { type: ButtonType.Normal, stateEffect: true})
                .onClick(() => {
                  this.InitEngineBeforeExecuteTask(this.EnterPreviewTask)
                })
                .width('35%')
                .height(60)
                .fontSize(18)
                .borderRadius(10)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.5 })

            }.justifyContent(FlexAlign.Center).width('100%').margin({ top: 30 }).height(80)


          Row({ space: 35}) {
            Button("融合推流", { type: ButtonType.Normal, stateEffect: true})
              .onClick(() => {
                this.joinRoomDialog.open()
                setTimeout(() => {
                  this.StartPushStream()
                }, 500)
              })
              .width('35%')
              .height(60)
              .fontSize(18)
              .borderRadius(10)
              .clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.5 })

          }.justifyContent(FlexAlign.Center).width('100%').margin({ top: 10 }).height(80)

          Row( { space: 5} ) {
            Button('低延迟拉流', { type: ButtonType.Normal,  stateEffect: true  })
              .fontSize(18)
              .width('35%')
              .height(60)
              .borderRadius(10)
              .clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
                this.InitEngineBeforeExecuteTask(this.StartPullStream)
            })
          }.justifyContent(FlexAlign.Center).width('100%').margin({top: 10}).height(80)


          Row({ space: 5 }) {
            Button('检查权限', { type: ButtonType.Normal, controlSize: ControlSize.SMALL, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL }).fontSize(18).clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
              ChatPresenter.getInstance().checkPermission()
            })
            Button('清除缓存', { type: ButtonType.Normal, controlSize: ControlSize.SMALL, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL }).fontSize(18).clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
              ChatPresenter.getInstance().clearCache(getContext(this))
            }).fontColor(Color.Red)

            Button('模拟崩溃', { type: ButtonType.Normal, controlSize: ControlSize.SMALL, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL }).fontSize(18).clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
              throw new Error("Division by zero is not allowed.");
            }).fontColor(Color.Red)
          }.width('100%').justifyContent(FlexAlign.Start).margin({ top: 50, left: 10, right: 10})

          Row({ space: 5 }) {
            Button('会前测速', { type: ButtonType.Normal, controlSize: ControlSize.SMALL, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL }).fontSize(18).clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
              this.InitEngineBeforeExecuteTask(this.EnterNetWorkProbeTest)
            })
            Button('设备支持虚拟背景?', { type: ButtonType.Normal, controlSize: ControlSize.SMALL, stateEffect: true, buttonStyle: ButtonStyleMode.NORMAL}).fontSize(18).clickEffect({ level: ClickEffectLevel.HEAVY, scale: 0.8 }).onClick(() => {
              this.InitEngineBeforeExecuteTask(() => {
                ChatPresenter.getInstance().queryVirtualBackgroundSupport()
              })
            })
          }.justifyContent(FlexAlign.Start).margin({ top: 10, left: 10, right: 10})
        }
      }
      .width('100%')
    }
    .height('100%')
  }

  private loadChannelToken() {
    Prompt.showToast({ message: '开启请求token.'})
    const url = SDK.getInstance().GetLogicDataModel().GetDemoTokenUrl()
    const appKey = SDK.getInstance().GetLogicDataModel().GetDemoAppKey()
    console.info(this.TAG, `start loadChannelToken, url:${url}, appKey:${appKey}`)

    let queryString = url + '?uid=' + this.uid + "&appkey=" + appKey
    let httpRequest = http.createHttp()
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      readTimeout: 5000,
      connectTimeout: 5000,
      expectDataType: http.HttpDataType.STRING,
      usingCache: false
    }

    try {
      httpRequest.request(queryString, options).then(response => {
        console.info(this.TAG, 'result:' + response.result as string)
        interface Response {
          code: number;
          checksum: string;
        }
        const result: Response = JSON.parse(response.result as string)
        if (result.code != 200) {
          Prompt.showToast({ message: '请求token失败'})
          this.joinRoomDialog.close()
        } else {
          Prompt.showToast({ message: '请求token成功，开始请求加入房间'})
          let ret = SDK.getInstance().join({ cname: this.cname, uid: this.uid, token: result.checksum})
          if (ret != NERtcConstants.ErrorCode.NO_ERROR) {
            Prompt.showToast({ message: '请求房间失败, error:' + ret})
            this.joinRoomDialog.close()
          }
        }
      }).catch((err: Error) => {
        console.info(this.TAG, `err:${JSON.stringify(err)}`)
        Prompt.showToast({ message: `err:${JSON.stringify(err)}`})
        this.joinRoomDialog.close();
      })
    } catch (e) {
      Prompt.showToast({ message: `请求token失败，${JSON.stringify(e)}`})
      this.joinRoomDialog.close()
    }
  }

  private InitEngineBeforeExecuteTask(task:() => void) {
    if (!this.rtcEngineInitDone) {
      this.InitEngineDialog.open()
      setTimeout(() => {
        this.InitRtcEngine()
        this.InitEngineDialog.close()
        task()
      }, 500)
    } else {
      task()
    }
  }

  private EnterNetWorkProbeTest = (): void => {
    let ret = ChatPresenter.getInstance().enableLastMileProbe(true)
    if(ret == NERtcConstants.ErrorCode.NO_ERROR)
      this.networkQualityDialog.open()
  }

  private EnterPreviewTask = (): void => {
    let param: model.LoginInfo = {
      cname: this.cname,
      uid: this.uid
    }
    router.pushUrl({ url: 'pages/Preview', params: param }, err => {
      if(err) {
        prompt.showToast({ message: 'turn to settings failed.', duration: 2000 })
      }
      console.info(this.TAG, 'turn to settings success.')
    })
  }

  async JoinRoom() {

    if(this.cname === "") {
      prompt.showToast({ duration: 2000, message: "Please input channel name."})
      return
    }
    if(this.uid === "") {
      prompt.showToast({ duration: 2000, message: "Please input user id."})
      return
    }

    //*** 考虑到私有化设置，在进房间之前初始化引擎
    this.InitRtcEngine()

    //check is safe-mode.
    if (this.safeMode) {
      this.loadChannelToken()
    } else {
      let ret = SDK.getInstance().join({ cname: this.cname, uid: this.uid })
      if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
        prompt.showToast({ message: 'Join channel failed, result: ' + ret, duration: 2000 })
        this.joinRoomDialog.close()
      }
    }
  }

  StartPushStream(){

    if(this.cname === "") {
      prompt.showToast({ duration: 2000, message: "Please input channel name."})
      return
    }
    if(this.uid === "") {
      prompt.showToast({ duration: 2000, message: "Please input user id."})
      return
    }

    this.InitRtcEngine()
    let ret = SDK.getInstance().startPushStreaming({ cname: this.cname, uid: this.uid })
    SDK.getInstance().onStartPushStreaming(BigInt(0))
    if(ret != NERtcConstants.ErrorCode.NO_ERROR) {
      this.joinRoomDialog.close()
      prompt.showToast({ message: '融合推流失败, result: ' + ret, duration: 2000 })
    }
  }

  private StartPullStream = (): void => {
    router.pushUrl({ url: 'pages/LowLatency' }, err => {
      if(err) {
        prompt.showToast({ message: 'turn to settings failed.', duration: 2000 })
      }
      console.info(this.TAG, 'turn to settings success.')
    })
  }

  transToChat(): void {
    let param: model.LoginInfo = {
      fromTA: false,
      cname: this.cname,
      uid: this.uid
    }
    router.pushUrl({ url: 'pages/Chat',  params: param }, (err)=> {
      if(err) {
        console.error(`Invoke pushUrl failed, code is ${err.code}, message is ${err.message}`)
        return
      }
      console.info("Invoke pushUrl success.")
    })
  }

  async checkAccessToken() {

    let atManager = AbilityAccessCtrl.createAtManager();
    let grantStatus = AbilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = -1;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (err) {
      console.error(`getBundleInfoForSelf failed, code is ${err.code}, message is ${err.message}`);
    }

    if(tokenId == -1) return
    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, "ohos.permission.INTERNET");
    } catch (err) {
      console.error(`checkAccessToken failed, code is ${err.code}, message is ${err.message}`);
    }

    if(grantStatus === AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      console.info(this.TAG, 'PERMISSION_GRANTED')
    } else {
      console.info(this.TAG, 'PERMISSION_DENIED')
    }
  }

  async RequestPermission() {
    let atManager = AbilityAccessCtrl.createAtManager();
    let context = getContext(this);

    try {
      atManager.requestPermissionsFromUser(context, ["ohos.permission.MICROPHONE", "ohos.permission.CAMERA"], (err, data) => {
        if(err) {
          prompt.showToast({message: `请求权限失败: ${err}`})
          return
        }
        let micGrant: boolean = data.authResults[0] === AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
        let cameraGrant: boolean = data.authResults[1] === AbilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

        if(!micGrant) {
          prompt.showToast({ message: `麦克风权限未授予` })
        }
        if(!cameraGrant) {
          prompt.showToast( {message: `摄像头权限未授予` })
        }
      })
    } catch(err) {
      prompt.showToast({ message: `请求权限失败: ${JSON.stringify(err)}`})
    }
  }

}