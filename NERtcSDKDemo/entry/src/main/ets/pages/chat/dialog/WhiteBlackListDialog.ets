
@CustomDialog
export struct WhiteBlackListDialog {

  private blackList: string|null = null
  private pubWhiteList: string|null = null
  private subWhiteList: string|null = null

  controller?: CustomDialogController
  callback?: (blackList: string|null, whiteList: string|null, subWhiteList: string|null) => void;


  build() {

    Column() {
      Text('设置黑白名单').margin({ top: 20 }).fontSize(20).width('100%').textAlign(TextAlign.Start).padding({ left: 10, right: 10 })
      Text('注意: 多个uid用#隔开').width('100%').textAlign(TextAlign.Start).padding({ left: 10, right: 10 }).fontSize(10).fontColor(Color.Red)
      TextInput({ placeholder: '请输入音频黑名单' }).width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })
        .showUnderline(true).onChange(value => {
          this.blackList = value
      })

      TextInput({ placeholder: '请输入上行音频白名单'}).width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })
        .showUnderline(true).onChange(value => {
          this.pubWhiteList = value
      })

      TextInput({ placeholder: '请输入下行音频白名单'}).width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })
        .showUnderline(true).onChange(value => {
        this.subWhiteList = value
      })

      Row({ space: 10 }) {
        Button('取消', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          this.controller?.close()
        }).backgroundColor(Color.White).fontColor(Color.Black).margin({ top : 10 })
        Button('确定', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          if(this.callback) {
            this.callback(this.blackList, this.pubWhiteList, this.subWhiteList)
          }
          this.controller?.close()
        }).backgroundColor(Color.White).fontColor(Color.Red).margin({ top : 10 })
      }.width('100%').justifyContent(FlexAlign.End)

    }.align(Alignment.Start).backgroundColor(Color.White)
  }

}