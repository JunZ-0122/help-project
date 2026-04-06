
@Component
struct PublishHelp {
  build() {
    Column({ space: 16 }) {
      Text('发布求助')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      TextInput({ placeholder: '求助类型（如：医疗 / 出行）' })
      TextInput({ placeholder: '求助说明' })

      Button('提交求助')
        .width('80%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
