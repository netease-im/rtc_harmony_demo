import { VideoSetting } from './settings/tab/VideoSetting'
import { VideoMultiSetting } from './settings/tab/VideoMultiSetting'
import { AudioSetting } from './settings/tab/AudioSettings'
import { preferences } from '@kit.ArkData'
import { LoadingDialog, Prompt } from '@kit.ArkUI'
import SDK from './chat/Presenter1'
import { OtherSetting } from './settings/tab/OtherSettings'
import * as parcelable from './settings/model/common'
import { FUNC } from './settings/model/common'
import router from '@ohos.router';
import * as model from './chat/ChatModel'
import { DumpSetting } from './settings/tab/DumpSettings'
import { AudioEffectSetting } from './settings/tab/AudioEffectSettings'

@Entry
@Component
struct Settings {

  private TAG: string = 'Settings'
  private controller: TabsController = new TabsController()
  private data: preferences.Preferences | null = null //Don't delete it.
  private reInit: boolean = true

  @State videoModel: parcelable.VideoModel = new parcelable.VideoModel
  @State videoModelMulti: parcelable.VideoModelMulti = new parcelable.VideoModelMulti
  @State audioModel: parcelable.AudioModel = new parcelable.AudioModel
  @State otherModel: parcelable.OtherModel = new parcelable.OtherModel
  @State dumpModel: parcelable.DumpModel = new parcelable.DumpModel
  @State audioEffectModel: parcelable.AudioEffectModel = new parcelable.AudioEffectModel

  private ReInitDialog: CustomDialogController = new CustomDialogController({
    builder: LoadingDialog({
      content: this.reInit ? "重置引擎中...":'数据持久化中...'
    }),
    autoCancel: false,
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  onPageShow(): void {
    let setting = router.getParams() as model.SettingInfo
    this.reInit = setting.reInit
    let options: preferences.Options = { name: 'netease_settings' }
    this.data = preferences.getPreferencesSync(getContext(), options)
    parcelable.Operate(this, FUNC.TAKE)
  }

  onBackPress(): boolean | void {
    this.ReInitDialog.open()
    setTimeout(() => {
      parcelable.Operate(this, FUNC.PUT, () => {

        console.info(this.TAG, 'Flush data success, re-init engine.')

        if(this.reInit) {
          SDK.getInstance().release()
          SDK.getInstance().init(getContext())
        }

        const baseDir = getContext(this).filesDir
        parcelable.Operate(this, FUNC.COPY, this.videoModel.virtualBackgroundSource, baseDir)

        parcelable.Operate(this, FUNC.COPY, this.audioModel.audioEffect1Url, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.audioModel.audioMixPath, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.audioModel.externalAudioInputUrl, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.audioModel.externalSubAudioInputUrl, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.videoModel.externalVideoPath, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.videoModelMulti.externalThirdVideoPath, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.videoModel.externalSubVideoPath, baseDir)
        parcelable.Operate(this, FUNC.COPY, this.videoModelMulti.externalFourthVideoPath, baseDir)

        Prompt.showToast({ message: '重置参数'})
        SDK.getInstance().resetParams(getContext())
        this.ReInitDialog.close()
      })
    }, 500)
  }

  build() {
    Row() {
      Column() {
        Tabs({ barPosition: BarPosition.End, controller: this.controller }) {

          TabContent() {
            VideoSetting({ videoModel: $videoModel, isInMeeting: !this.reInit }).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.video_common'), '视频'))

          TabContent() {
            VideoMultiSetting({ videoModel: $videoModelMulti, isInMeeting: !this.reInit }).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.video_multi'), '多流'))

          TabContent() {
            AudioSetting({ audioModel: $audioModel, isInMeeting: !this.reInit }).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.audio_common'), '音频'))

          TabContent() {
            DumpSetting({ dumpModel: $dumpModel}).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.video_dump'), '视频Dump'))

          TabContent() {
            AudioEffectSetting({ audioEffectModel: $audioEffectModel}).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.audio_effect'), '变声美声'))

          TabContent() {
            OtherSetting({ otherModel: $otherModel, isInMeeting: !this.reInit }).width('100%').height('100%')
          }.tabBar(BottomTabBarStyle.of($r('app.media.other'), '其他'))

        }.animationDuration(300).animationMode(AnimationMode.ACTION_FIRST).barMode(BarMode.Fixed)
      }
      .width('100%')
    }
    .height('100%')
  }
}