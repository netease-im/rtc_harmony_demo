
@CustomDialog
export struct EditTextBaseDialog {

  title: string = ''
  controller?: CustomDialogController
  callback?: (text: string) => void;
  private editText: string = ''

  build() {
    Column() {
      Text(this.title).margin({top: 20}).fontSize(20).width('100%').textAlign(TextAlign.Center)
      TextInput({placeholder: '请输入...'}).width('100%').margin({top: 10}).padding({left: 10, right: 10})
        .showUnderline(true).onChange(value => {
        this.editText = value
      })
      Row({space: 10}) {
        Button('取消', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
          this.editText = ''
          this.controller?.close()
        }).borderRadius(5).backgroundColor(Color.White).fontColor(Color.Red).fontSize(16)
        Button('确定', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
          if(this.callback && this.editText) {
            this.callback(this.editText)
          }
          this.controller?.close()
        }).borderRadius(5).backgroundColor(Color.White).margin({ right: 5}).fontColor(Color.Black).fontSize(16)
      }.margin({ bottom: 20, top: 20 }).width('100%').justifyContent(FlexAlign.End)
    }.align(Alignment.Start).backgroundColor(Color.White)
  }

}