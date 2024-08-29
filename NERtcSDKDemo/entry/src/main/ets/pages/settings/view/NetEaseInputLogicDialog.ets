import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { NetEaseTextInputDialog } from '../../../ui/TextInputDialog'

@Component
export struct NetEaseInputLogicDialog {

  title: string = ''
  @State content: string = ''
  onInputValue?: (value: string) => void;

  private inputDialog: CustomDialogController = new CustomDialogController({
    builder: NetEaseTextInputDialog({
      confirm: value => {
        if(value !== undefined) {
          this.content = value
          if(this.onInputValue) {
            this.onInputValue(value)
          }
        }
      },
      title: this.title,
      hint: this.content
    }),
    alignment: DialogAlignment.Center,
    cornerRadius: 10
  })

  build() {

    ComposeListItem({
      contentItem: {
        primaryText: this.title,
        secondaryText: this.content
      }
    }).onClick(() => {
      this.inputDialog.open()
    })

  }


}