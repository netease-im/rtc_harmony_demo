
@CustomDialog
export struct StartPKDialog {

  private pkChannelName: string = ""
  private pkRemoteUid: string = ""

  controller?: CustomDialogController
  callback?: (channelName: string, remoteUid: string) => void;


  build() {

    Column() {
      Text('发起PK').margin({ top: 20 }).fontSize(20).width('100%').textAlign(TextAlign.Start).padding({ left: 10, right: 10 })
      TextInput({ placeholder: 'PK对方房间名' }).width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })
        .showUnderline(true).onChange(value => {
          this.pkChannelName = value
      })

      TextInput({ placeholder: 'PK对方用户ID'}).width('100%').margin({ top: 10 }).padding({ left: 10, right: 10 })
        .showUnderline(true).onChange(value => {
          this.pkRemoteUid = value
      })

      Row({ space: 10 }) {
        Button('取消', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          this.controller?.close()
        }).backgroundColor(Color.White).fontColor(Color.Black).margin({ top : 10 })
        Button('确定', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          if(this.callback) {
            this.callback(this.pkChannelName, this.pkRemoteUid)
          }
          this.controller?.close()
        }).backgroundColor(Color.White).fontColor(Color.Red).margin({ top : 10 })
      }.width('100%').justifyContent(FlexAlign.End)

    }.align(Alignment.Start).backgroundColor(Color.White)
  }

}