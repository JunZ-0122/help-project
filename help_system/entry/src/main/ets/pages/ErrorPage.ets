import router from '@ohos.router';

@Entry
@Component
struct ErrorPage {
  @State errorMessage: string = '页面出现错误';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params.message) {
      this.errorMessage = params.message as string;
    }
  }

  goBack() {
    router.back();
  }

  goHome() {
    router.replaceUrl({
      url: 'pages/SplashPage'
    }).catch((err: Error) => {
      console.error('navigation failed:', err);
    });
  }

  build() {
    Column({ space: 24 }) {
      Text('ERROR')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)

      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#6b7280')
        .textAlign(TextAlign.Center)
        .width('100%')

      Button('返回上一页')
        .width(200)
        .height(48)
        .backgroundColor('#3b82f6')
        .borderRadius(24)
        .onClick(() => {
          this.goBack();
        })

      Button('回到首页')
        .width(200)
        .height(48)
        .backgroundColor('#f3f4f6')
        .fontColor('#374151')
        .borderRadius(24)
        .onClick(() => {
          this.goHome();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f9fafb')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(24)
  }
}
