import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { NetEaseTextListDialog } from '../../../ui/TextListDialog'

@Component
export struct NetEaseListLogicDialog {

  array: string[] = []
  title: string = ''
  @State index: number = 0
  choose?: (index: number) => void;

  private listDialog: CustomDialogController = new CustomDialogController({
    builder: NetEaseTextListDialog({
      userCheck: index => {
        if(index !== undefined) {
          this.index = index
          if(this.choose)
            this.choose(index)
        }
      },
      title: this.title,
      value: this.array,
      selected: this.index
    }),
    alignment: DialogAlignment.Center,
    cornerRadius: 10
  })

  build() {
    ComposeListItem({
      contentItem: {
        primaryText: this.title,
        secondaryText: this.array[this.index]
      }
    }).onClick(() => {
      this.listDialog.open()
    })
  }


}