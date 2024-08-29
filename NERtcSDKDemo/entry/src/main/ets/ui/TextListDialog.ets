import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'

@CustomDialog
export struct NetEaseTextListDialog {

  title?: string
  controller?: CustomDialogController
  value?: string[]
  selected: number = 0 //default.
  userCheck?: (index: number) => void;

  private isCheck = (item: string): boolean => {
    if(!this.value) return false;
    return this.value[this.selected] === item
  }

  private findIndex = (item: string): number => {
    if(!this.value) return -1;
    for(let i = 0; i < this.value.length; i++) {
      if(this.value[i] === item) {
        return i;
      }
    }
    return -1;
  }

  build() {
    Column() {
      Text(this.title).fontSize(25).margin({ top: 20, left: 20, bottom: 10 })
      ForEach(this.value, (item: string) => {
        ComposeListItem({
          contentItem: {
            primaryText: item
          },
          operateItem: {
            radio: {
              isCheck: this.isCheck(item),
            }
          }
        })
          .margin({ left: 10, right: 10 })
          .onClick(() => {
            this.controller?.close()
            let index = this.findIndex(item)
            this.selected = index
            if(this.userCheck)
              this.userCheck(index)
          })
      })
    }.alignItems(HorizontalAlign.Start)
  }

}