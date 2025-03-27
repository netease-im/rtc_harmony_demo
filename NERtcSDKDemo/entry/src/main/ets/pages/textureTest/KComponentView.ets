// import XComponentContext from "../interface/XComponentContext"import XComponentContext from '@ohos/nativerender'
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

const TAG: string = 'Xcomponent indexPage';

@Component
export  struct KComponentView {

  private surfaceId: bigint = BigInt('0');
  mXComponentController: XComponentController = new XComponentController()
  @State permissionCamera:Boolean = false;
  @Prop xComponentWidth: number = 1920;
  @Prop xComponentHeight: number = 1080;
  private appContext: common.Context = getContext(this);
  atManager = abilityAccessCtrl.createAtManager();


  aboutToDisappear(): void {
    console.log("6666666666666zhao")
  }


  async requestPermissionsFn() {
    console.info(TAG, `requestPermissionsFn entry`);
    try {
      this.atManager.requestPermissionsFromUser(this.appContext, [
        'ohos.permission.CAMERA',
        'ohos.permission.MICROPHONE',
        'ohos.permission.READ_MEDIA',
        'ohos.permission.WRITE_MEDIA'
      ]).then(() => {
        console.info(TAG, `request Permissions success!`);
        this.permissionCamera = true;

      })
    } catch (err) {
      console.info(TAG, `requestPermissionsFromUser call Failed! error: ${err.code}`);
      this.permissionCamera = false;
    }
  }

    build() {
    Column() {
      Column() {
        XComponent({
          id: 'xcomponentId',
          type: XComponentType.SURFACE,
          libraryname: 'nertc_sdk',
          controller: this.mXComponentController
        })
          .width('1920px')
          .height('1080px')
          .onLoad(() => {
            this.mXComponentController.setXComponentSurfaceSize({ surfaceWidth: this.xComponentWidth, surfaceHeight: this.xComponentHeight });
           this.requestPermissionsFn();
              console.log("zhaohao6666666666"+this.surfaceId);

          })
          .onDestroy(() => {
            console.log('onDestroy');
          })
          .id("xcomponent")
          .margin(5)
          .layoutWeight(1)
      }
      .layoutWeight(1)
      .width('90%')
    }
    .width('100%')
    .height('100%')
  }
}
