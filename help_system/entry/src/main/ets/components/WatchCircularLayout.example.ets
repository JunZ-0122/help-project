/**
 * WatchCircularLayout 组件使用示例
 * 
 * 展示如何使用 WatchCircularLayout 组件创建适配圆形屏幕的布局
 */

import { WatchCircularLayout } from './WatchCircularLayout';

@Entry
@Component
struct WatchCircularLayoutExample {
  @State currentExample: number = 1;

  /**
   * 示例1：基础布局
   */
  @Builder
  basicLayoutExample() {
    Column({ space: 12 }) {
      Text('基础圆屏布局')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')

      Text('这是一个基础的圆屏适配布局示例')
        .fontSize(14)
        .textAlign(TextAlign.Center)
        .width('100%')

      Button('按钮示例')
        .width('80%')
        .height(44)
        .fontSize(14)
    }
  }

  /**
   * 示例2：多内容布局
   */
  @Builder
  multiContentExample() {
    Column({ space: 8 }) {
      Text('多内容布局')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')

      ForEach([1, 2, 3, 4], (item: number) => {
        Row() {
          Text(`项目 ${item}`)
            .fontSize(14)
            .layoutWeight(1)
          
          Button('操作')
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
        }
        .width('100%')
        .padding({ left: 8, right: 8 })
        .justifyContent(FlexAlign.SpaceBetween)
      })
    }
  }

  /**
   * 示例3：表单布局
   */
  @Builder
  formLayoutExample() {
    Column({ space: 12 }) {
      Text('表单布局')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width('100%')

      TextInput({ placeholder: '输入框1' })
        .width('100%')
        .height(40)
        .fontSize(14)

      TextInput({ placeholder: '输入框2' })
        .width('100%')
        .height(40)
        .fontSize(14)

      Row({ space: 8 }) {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#f1f5f9')
          .fontColor('#334155')

        Button('确认')
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor('#2563eb')
          .fontColor('#ffffff')
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      // 示例切换按钮
      Row({ space: 8 }) {
        Button('示例1')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.currentExample === 1 ? '#2563eb' : '#e5e7eb')
          .fontColor(this.currentExample === 1 ? '#ffffff' : '#64748b')
          .onClick(() => this.currentExample = 1)

        Button('示例2')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.currentExample === 2 ? '#2563eb' : '#e5e7eb')
          .fontColor(this.currentExample === 2 ? '#ffffff' : '#64748b')
          .onClick(() => this.currentExample = 2)

        Button('示例3')
          .fontSize(12)
          .height(32)
          .backgroundColor(this.currentExample === 3 ? '#2563eb' : '#e5e7eb')
          .fontColor(this.currentExample === 3 ? '#ffffff' : '#64748b')
          .onClick(() => this.currentExample = 3)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(8)

      // 使用 WatchCircularLayout 展示不同示例
      WatchCircularLayout({
        centerRadius: 120,
        edgePadding: 16
      }) {
        if (this.currentExample === 1) {
          this.basicLayoutExample();
        } else if (this.currentExample === 2) {
          this.multiContentExample();
        } else if (this.currentExample === 3) {
          this.formLayoutExample();
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
  }
}