
@CustomDialog
export struct MediaRelayDialog {

  @State private role: boolean = false
  private addText: string = ''
  private updateText: string = ''

  controller?: CustomDialogController
  addCB?: (input: string) => void;
  updateCB?: (input: string) => void;
  stopCB?:() => void;
  roleCB?:(role: boolean) => void;

  build() {
    RelativeContainer() {

      Text('跨房间推流').margin({ top: 20 }).fontSize(20).width('100%')
        .alignRules({
          top: { anchor: "__container__", align: VerticalAlign.Top },
        }).id('title').textAlign(TextAlign.Center)
      Flex() {
        TextInput({ placeholder: '多个房间名以#隔断' }).width('80%').showUnderline(true)
          .onChange(value => {
            this.addText = value
          })
        Button('添加', { type: ButtonType.Normal, stateEffect: true }).borderRadius(5)
          .onClick(() => {
            if (this.addCB) {
              this.addCB(this.addText)
            }
          })
      }.width('100%').alignRules({
        top: { anchor: "title", align: VerticalAlign.Bottom }
      }).id('add').margin({ top: 20, left: 10, right: 10 })

      Flex() {
        TextInput({ placeholder: '多个房间名以#隔断'}).width('80%').showUnderline(true)
          .onChange(value => {
            this.updateText = value
          })
        Button('更新', { type: ButtonType.Normal, stateEffect: true }).borderRadius(5)
          .onClick(() => {
            if (this.updateCB) {
              this.updateCB(this.updateText)
            }
          })
      }.width('100%').alignRules({
        top: { anchor: 'add', align: VerticalAlign.Bottom }
      }).id('update').margin({ top: 20, left: 10, right: 10 })

      Flex({ justifyContent: FlexAlign.SpaceEvenly}) {
        Button('停止Relay', { type: ButtonType.Normal, stateEffect: true }).borderRadius(5)
          .onClick(() => {
            if (this.stopCB) {
              this.stopCB()
            }
          })
        Button(this.role ? '切主播':'切观众', { type: ButtonType.Normal, stateEffect: true }).borderRadius(5)
          .onClick(() => {
            if (this.roleCB) {
              this.role = !this.role
              this.roleCB(this.role)
            }
          })
      }.width('100%').alignRules({
        top: { anchor: 'update', align: VerticalAlign.Bottom }
      }).margin({ top: 30 })
    }.width('100%')
  }

}