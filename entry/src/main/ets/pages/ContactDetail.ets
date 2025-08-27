import router from '@ohos.router';
import { Contact } from '../model/Contact'

// 定义路由参数接口
interface RouteParams {
  contact: Contact;
}

@Entry
@Component
struct ContactDetail {
  @State item: Contact | null = null

  aboutToAppear() {
    // 使用定义好的接口类型
    const params = router.getParams() as RouteParams;
    if (params && params.contact) {
      this.item = params.contact;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.left'))
          .width(30)
          .height(30)
          .margin({ left: 16 })
          .onClick(() => {
            router.back();
          })

        Text('联系人详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 })

        Blank()
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .backgroundColor($r('app.color.background_secondary'))

      // 联系人头像和信息
      Column() {
        Image(this.item?.gender === '男' ?
        $r('app.media.man') :
        $r('app.media.lady'))
          .width(100)
          .height(100)
          .margin({ top: 30, bottom: 20 })
          .borderRadius(50)

        Text(this.item?.name || '')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        Text(this.item?.phone || '')
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 30 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 详细信息 - 使用优化的DetailItem组件
      Column() {
        DetailItem({ label: '姓名', value: this.item?.name || '' })
        DetailItem({ label: '电话', value: this.item?.phone || '' })
        DetailItem({ label: '性别', value: this.item?.gender || '' })
        DetailItem({ label: '备注', value: this.item?.remark || '无' })
      }
      .padding(16)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
      .width('90%')
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
    .padding({ top: 12 })
  }
}

@Component
struct DetailItem {
  @Prop label: string = '';
  @Prop value: string = '';

  build() {
    Row() {
      // 标签部分 - 固定宽度并右对齐
      Text(this.label)
        .fontSize(16)
        .fontColor($r('app.color.text_tertiary'))
        .width('30%')  // 使用百分比宽度确保一致性
        .textAlign(TextAlign.End)  // 文字右对齐
        .margin({ right: 12 })  // 添加右边距

      // 分隔冒号
      Text(':')
        .fontSize(16)
        .fontColor($r('app.color.text_tertiary'))

      // 值部分 - 左对齐
      Text(this.value)
        .fontSize(16)
        .margin({ left: 12 })
        .layoutWeight(1)  // 占据剩余空间
    }
    .height(50)
    .border({ width: 0.5, color: $r('app.color.border_light') })
    .alignItems(VerticalAlign.Center)  // 垂直居中
  }
}