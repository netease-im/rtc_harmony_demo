/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { Constants } from './Constants';
import DisplayCalculator from './DisplayCalculator';
import display from '@ohos.display';
import {KComponentView} from "./KComponentView"
const TAG: string = 'UI indexPage';

@Entry
@Component
struct Index {
  @State xComponentWidth: number = 384;
  @State xComponentHeight: number = 450;
  private screenHeight: number = 0;
  private screenWidth: number = 0;


  @StorageLink('defaultAspectRatio') @Watch('initXComponentSize') defaultAspectRatio: number = Constants.MIN_ASPECT_RATIO;
  async aboutToAppear() {
    let mDisplay = display.getDefaultDisplaySync();
    this.screenWidth = px2vp(mDisplay.width);
    this.screenHeight = px2vp(mDisplay.height);
    this.initXComponentSize();
  }

  initXComponentSize(): void {
    let defaultSize = DisplayCalculator.calcSurfaceDisplaySize(this.screenWidth, this.screenHeight, this.defaultAspectRatio);
    this.xComponentWidth = defaultSize.width;
    this.xComponentHeight = defaultSize.height;
  }

  async aboutToDisAppear() {

  }

  async onPageShow() {
    console.info(TAG, `onPageShow App`);
  }

  onPageHide() {
    console.info(TAG, `onPageHide App`);
  }
  build() {
    Column() {
      Row() {
        KComponentView({xComponentWidth:this.xComponentWidth, xComponentHeight:this.xComponentHeight}).height("100%").width("100%")
      }
      .height('50%')
      .width("100%")
    }.height('100%')
    .width('100%')
  }
}