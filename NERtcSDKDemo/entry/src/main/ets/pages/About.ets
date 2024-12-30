import { NERtcConstants, NERtcSDK } from '@nertc/nertc_sdk';
import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem';

@Entry
@Component
struct About {

  private version: NERtcConstants.NERtcVersion = NERtcSDK.version()

  @Builder itemHead(text: string) {
    Text(text)
      .fontSize(15)
      .backgroundColor($r('sys.color.container_modal_unfocus_background'))
      .width('100%')
      .padding(10)
  }

  build() {
    Column() {
      List({ space: 10 }) {
        ListItemGroup({ header: this.itemHead('SDK版本信息')}) {

          ComposeListItem({
            contentItem: {
              primaryText: 'SDK VERSION',
              secondaryText: this.version.version
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'BUILD TYPE',
              secondaryText: String(this.version.debug ? 'debug' : 'release')
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'BUILD HOST',
              secondaryText: this.version.buildHost
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'BUILD TIME',
              secondaryText: this.version.buildTime
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'BUILD BRANCH',
              secondaryText: this.version.buildBranch
            }
          })

          ComposeListItem({
            contentItem: {
              primaryText: 'BUILD COMMIT',
              secondaryText: this.version.buildCommit
            }
          })
        }.divider({
          strokeWidth: 1,
          startMargin: 10,
          endMargin: 10,
          color: '#F1F3F5'
        })
      }.width('100%').height('100%')
        .scrollBar(BarState.Auto)
        .sticky(StickyStyle.Header)
    }.width('100%').height('100%')
  }
}