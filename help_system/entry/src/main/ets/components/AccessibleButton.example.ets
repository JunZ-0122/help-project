/**
 * AccessibleButton 组件使用示例
 * 
 * 本文件展示如何在页面中使用 AccessibleButton 组件
 */

import { AccessibleButton } from './AccessibleButton';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct AccessibleButtonExample {
  @State message: string = '点击按钮查看效果';

  build() {
    Column({ space: 20 }) {
      Text('AccessibleButton 使用示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      Text(this.message)
        .fontSize(16)
        .fontColor('#666666')

      // 示例 1: 基础用法
      AccessibleButton({
        text: '基础按钮',
        onClick: () => {
          this.message = '基础按钮被点击';
          promptAction.showToast({ message: '基础按钮被点击' });
        }
      })

      // 示例 2: 自定义字体大小
      AccessibleButton({
        text: '大字体按钮',
        fontSize: 18,
        onClick: () => {
          this.message = '大字体按钮被点击';
          promptAction.showToast({ message: '大字体按钮被点击' });
        }
      })

      // 示例 3: 自定义颜色
      AccessibleButton({
        text: '自定义颜色',
        backgroundColor: '#10b981',
        fontColor: '#ffffff',
        onClick: () => {
          this.message = '自定义颜色按钮被点击';
          promptAction.showToast({ message: '自定义颜色按钮被点击' });
        }
      })

      // 示例 4: 禁用状态
      AccessibleButton({
        text: '禁用按钮',
        enabled: false,
        onClick: () => {
          // 不会被执行
          this.message = '这不应该显示';
        }
      })

      // 示例 5: 自定义尺寸
      AccessibleButton({
        text: '自定义尺寸',
        width: '80%',
        height: 60,
        fontSize: 20,
        onClick: () => {
          this.message = '自定义尺寸按钮被点击';
          promptAction.showToast({ message: '自定义尺寸按钮被点击' });
        }
      })

      // 示例 6: Normal 类型按钮
      AccessibleButton({
        text: 'Normal 类型',
        type: ButtonType.Normal,
        onClick: () => {
          this.message = 'Normal 类型按钮被点击';
          promptAction.showToast({ message: 'Normal 类型按钮被点击' });
        }
      })

      Divider().margin({ top: 20, bottom: 20 })

      Text('无障碍功能说明')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Text('1. 大字体模式：按钮文字和高度自动增大 25%')
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')

      Text('2. 高对比度模式：黄色背景、黑色文字、3px 粗边框')
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')

      Text('3. 震动反馈：点击按钮时触发震动（如果启用）')
        .fontSize(14)
        .fontColor('#666666')
        .width('90%')

      Text('提示：在个人中心开启无障碍设置后，所有 AccessibleButton 会自动应用这些样式')
        .fontSize(12)
        .fontColor('#999999')
        .width('90%')
        .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}
