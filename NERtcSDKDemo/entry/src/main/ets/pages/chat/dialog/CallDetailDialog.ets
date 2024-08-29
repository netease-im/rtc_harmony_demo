@CustomDialog
export struct CallDetailDialog {

  @Link content: string
  controller?: CustomDialogController

  build() {
    Column() {
      Text(this.content)
        .fontSize(12)
        .width('100%')
        .height('100%')
        .padding('5')
        .backgroundColor("#808080")
        .opacity(0.5)
        .align(Alignment.TopStart)
    }
  }
}