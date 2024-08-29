
@CustomDialog
export struct SubDetailDialog {

  title: string = ''
  input: boolean = true //是否显示input
  controller?: CustomDialogController
  callback?: (stream: number, type: number, dual: number, enabled: boolean, uid?: bigint) => void;

  private uid: bigint = BigInt(0)
  private stream: number = 0
  private type: number = 0
  private dual: number = 0

  build() {
    Column() {
      Text(this.title).margin({ top: 20 }).fontSize(20).width('100%').textAlign(TextAlign.Center)
      if(this.input) {
        TextInput({ placeholder: '请输入uid'}).width('100%').margin({top: 10 }).padding({ left: 10, right: 10 })
          .showUnderline(true).onChange(value => {
          try {
            this.uid = BigInt(value)
          } catch (e) {
            console.error(JSON.stringify(e))
          }
        })
      }
      Row({ space: 10 }) {
        Text('音视频:').margin({ right: 10})
        Column() {
          Radio({ value: 'audio', group: 'stream'}).checked(true).onChange(check => {
            if(check)
              this.stream = 0
          })
          Text('音频')
        }
        Column() {
          Radio({ value: 'video', group: 'stream'}).checked(false).onChange(check => {
            if(check)
              this.stream = 1
          })
          Text('视频')
        }
      }.width('100%').margin({ left: 10, top: 10 })

      Divider().strokeWidth(1).color('#F1F3F5').margin({ left: 10 , right: 10, top : 10 })

      Row({ space: 10 }) {
        Text('主辅流:').margin({ right: 10})
        Column() {
          Radio({ value: 'main', group: 'type'}).checked(true).onChange(check => {
            if(check)
              this.type = 0
          })
          Text('主流')
        }
        Column() {
          Radio({ value: 'sub', group: 'type'}).checked(false).onClick(check => {
            if(check)
              this.type = 1
          })
          Text('辅流')
        }
      }.width('100%').margin({ left: 10, top: 5 })

      Divider().strokeWidth(1).color('#F1F3F5').margin({ left: 10 , right: 10, top: 10 })

      Row({ space: 10 }) {
        Text('大小流(仅视频):').margin({ right: 10 })
        Column() {
          Radio({ value: 'high', group: 'dual'}).checked(true).onClick(check => {
            if(check) this.dual = 0
          })
          Text('大流')
        }
        Column() {
          Radio({ value: 'low', group: 'dual'}).checked(false).onClick(check => {
            if(check) this.dual = 1
          })
          Text('小流')
        }
      }.width('100%').margin({ left: 10, top: 5 })

      Row() {
        Button('取消订阅', { type: ButtonType.Normal, stateEffect: true }).onClick(() => {
          if(this.callback && this.input) {
            this.callback(this.stream, this.type, this.dual, false, this.uid)
          }
          if(this.callback && !this.input) {
            this.callback(this.stream, this.type, this.dual, false)
          }
          this.controller?.close()
        }).borderRadius(5).backgroundColor(Color.White).fontColor(Color.Red).fontSize(16)
        Button('订阅', { type: ButtonType.Normal, stateEffect: true}).onClick(() => {
          if(this.callback && this.input) {
            this.callback(this.stream, this.type, this.dual, true, this.uid)
          }
          if(this.callback && !this.input) {
            this.callback(this.stream, this.type, this.dual, true)
          }
          this.controller?.close()
        }).borderRadius(5).backgroundColor(Color.White).margin({ right: 5}).fontColor(Color.Black).fontSize(16)
      }.margin({ bottom: 20, top: 20 }).width('100%').justifyContent(FlexAlign.End)
    }.align(Alignment.Start).backgroundColor(Color.White)
  }

}