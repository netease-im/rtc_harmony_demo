import { BeautySkinViewModel } from '../viewModels/BeautySkinViewModel';
import { BeautyShapeViewModel } from '../viewModels/BeautyShapeViewModel'
import { BeautyFilterViewModel } from '../viewModels/BeautyFilterViewModel'

export class BeautyDataService {
  skinViewModel = new BeautySkinViewModel();
  shapeViewModel = new BeautyShapeViewModel();
  filterViewModel = new BeautyFilterViewModel();
  private static instance: BeautyDataService | undefined = undefined;

  private constructor() {
  }

  static sharedInstance(): BeautyDataService {
    if (!BeautyDataService.instance) {
      BeautyDataService.instance = new BeautyDataService();
    }
    return BeautyDataService.instance;
  }

  static destroy() {
    BeautyDataService.instance = undefined;
  }
}