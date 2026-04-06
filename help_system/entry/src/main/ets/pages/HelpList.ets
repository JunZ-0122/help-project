
@Component
struct HelpList {
  build() {
    Column({ space: 16 }) {
      Text('求助列表')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Text('【医疗】独居老人身体不适')
      Text('【出行】视障人士外出协助')

      Button('返回')
        .width('60%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
