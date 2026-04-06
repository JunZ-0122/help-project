import router from '@ohos.router';
import { isWearableDevice } from '../utils/DeviceFormUtil';

@Entry
@Component
struct Index {
  aboutToAppear() {
    if (isWearableDevice()) {
      router.replaceUrl({
        url: 'pages/watch/WatchSplashPage'
      }).catch((err: Error) => {
        console.error('navigation failed:', err);
      });
      return;
    }
    router.replaceUrl({
      url: 'pages/SplashPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  build() {
    Column() {
      Text('Loading...')
        .fontSize(18)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f9fafb')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
