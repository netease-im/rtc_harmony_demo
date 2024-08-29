import { Prompt } from '@kit.ArkUI'

@CustomDialog
export struct NetEaseTextInputDialog {

  title?: string
  hint?: string
  confirm?: (value: string) => void;
  controller?: CustomDialogController
  value?: string

  build() {
    Column() {
      Text(this.title).fontSize(25).margin({ top: 20, left: 20 })
      TextInput({ placeholder: this.hint ? this.hint : '请输入数据'}).width('100%')
        .onChange(value => {
          this.value = value
        }).margin({ top: 10 }).padding({ left: 20, right: 20 }).showUnderline(true)
      Row({ space: 5 }) {
        Button('取消', { type: ButtonType.Normal, stateEffect: true} ).onClick(() => {
          this.controller?.close()
        }).backgroundColor(0xffffff).fontColor(Color.Red)
        Button('确定', { type: ButtonType.Normal, stateEffect: true} ).onClick(() => {
          if(this.confirm && this.value) {
            this.confirm(this.value)
          }
          if(!this.value) {
            Prompt.showToast({ message: 'input is empty!', duration: 2000 })
          }
          this.controller?.close()
        }).backgroundColor(0xffffff).fontColor(Color.Red)
      }.width('100%').justifyContent(FlexAlign.End).margin({ top: 20, bottom: 10 }).padding({ right: 15 })
    }.alignItems(HorizontalAlign.Start).backgroundColor(0xffffff)
  }
}
