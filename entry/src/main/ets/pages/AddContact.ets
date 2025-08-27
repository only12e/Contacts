import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { storeDb } from '../entryability/EntryAbility';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义颜色常量
interface GeneratedObjectLiteralInterface_1 {
  Primary: string;
  Background: string;
  White: string;
  TextPrimary: string;
  TextSecondary: string;
  Error: string;
  Border: string;
  Shadow: string;
}

// 颜色常量对象
const Colors: GeneratedObjectLiteralInterface_1 = {
  Primary: '#0A59F7',      // 主色调（蓝色）
  Background: '#F5F7FA',   // 背景色
  White: '#FFFFFF',        // 白色
  TextPrimary: '#333333',  // 主要文本颜色
  TextSecondary: '#666666',// 次要文本颜色
  Error: '#FF3B30',        // 错误提示颜色
  Border: '#EEEEEE',       // 边框颜色
  Shadow: '#1A000000',     // 阴影颜色（带透明度）
};

@Entry
@Component
struct AddContact {
  // 表单状态变量
  @State name: string = '';          // 联系人姓名
  @State phone: string = '';         // 联系人电话
  @State gender: string = '男';      // 联系人性别（默认男性）
  @State remark: string = '';        // 联系人备注
  @State nameError: boolean = false; // 姓名错误状态
  @State phoneError: boolean = false;// 电话错误状态

  // 定义radio组名（解决group属性缺失问题）
  private radioGroup: string = 'genderGroup';

  // 验证表单输入
  private validateInput(): boolean {
    let isValid = true;
    // 重置错误状态
    this.nameError = false;
    this.phoneError = false;

    // 验证姓名（非空）
    if (!this.name.trim()) {
      this.nameError = true;
      isValid = false;
    }

    // 验证电话号码（非空且符合手机号格式）
    if (!this.phone.trim()) {
      this.phoneError = true;
      isValid = false;
    } else {
      const phoneRegex = /^1[3-9]\d{9}$/; // 手机号正则表达式
      if (!phoneRegex.test(this.phone)) {
        this.phoneError = true;
        isValid = false;
      }
    }

    return isValid;
  }

  // 保存联系人
  private saveContact() {
    // 先验证表单
    if (!this.validateInput()) return;

    // 确保数据库已初始化
    if (storeDb !== undefined) {
      const valuesBucket: relationalStore.ValuesBucket = {
        'name': this.name,
        'phone': this.phone,
        'gender': this.gender,
        'remark': this.remark
      }

      // 执行数据库插入操作
      storeDb.insert('contact', valuesBucket, (err: BusinessError, _: number) => {
        if (err) {
          console.error(`保存失败: ${err.code}, ${err.message}`);
          promptAction.showToast({ message: '保存失败，请重试' });
          return;
        }

        // 保存成功后提示并返回主页
        promptAction.showToast({ message: '联系人已保存' });
        router.back({
          url: 'pages/Index',
          params: { result_code: 200 }  // 传递成功状态码
        });
      });
    } else {
      console.error('数据库未初始化');
      promptAction.showToast({ message: '系统错误，请重试' });
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
          .onClick(() => router.back()) // 返回上一页
          .foregroundColor(Colors.Primary)

        Text('新建联系人')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20 })
          .fontColor(Colors.TextPrimary)

        // 中间空白占位
        Blank()

        Button('保存')
          .type(ButtonType.Capsule)
          .width(80)
          .height(35)
          .fontSize(16)
          .fontColor(Colors.White)
          .backgroundColor(Colors.Primary)
          .margin({ right: 16 })
          .onClick(() => this.saveContact())
      }
      .width('100%')
      .height(60)
      .backgroundColor(Colors.White)
      .shadow({ radius: 4, color: Colors.Shadow, offsetX: 0, offsetY: 2 })

      // --- 表单区域（可滚动）---
      Scroll() {
        Column() {
          // 表单标题
          Text('基本信息')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ top: 20, bottom: 10, left: 16 })
            .fontColor(Colors.TextPrimary)

          // 姓名
          Row() {
            Text('姓名')
              .fontSize(16)
              .margin({ left: 16, right: 16 })
              .fontColor(Colors.TextSecondary)
              .width(80)
            Column() {
              TextInput({ text: this.name, placeholder: '请输入姓名' })
                .height(50)
                .width('100%')
                .fontSize(16)
                .padding(12)
                .backgroundColor(Colors.White)
                .borderRadius(8)
                .border({ width: this.nameError ? 1 : 0, color: this.nameError ? Colors.Error : Colors.Border })
                .onChange((value: string) => this.name = value)
              if (this.nameError) {
                Text('请输入姓名')
                  .fontSize(14)
                  .fontColor(Colors.Error)
                  .margin({ top: 4 })
                  .width('100%')
              }
            }
            .layoutWeight(1)
            .margin({ right: 16 })
          }
          .margin({ top: 8, bottom: 8 })
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 电话
          Row() {
            Text('电话')
              .fontSize(16)
              .margin({ left: 16, right: 16 })
              .fontColor(Colors.TextSecondary)
              .width(80)
            Column() {
              TextInput({ text: this.phone, placeholder: '请输入手机号码' })
                .type(InputType.Number)
                .height(50)
                .width('100%')
                .fontSize(16)
                .padding(12)
                .backgroundColor(Colors.White)
                .borderRadius(8)
                .border({ width: this.phoneError ? 1 : 0, color: this.phoneError ? Colors.Error : Colors.Border })
                .onChange((value: string) => this.phone = value)
              if (this.phoneError) {
                Text('请输入有效的手机号码')
                  .fontSize(14)
                  .fontColor(Colors.Error)
                  .margin({ top: 4 })
                  .width('100%')
              }
            }
            .layoutWeight(1)
            .margin({ right: 16 })
          }
          .margin({ top: 8, bottom: 8 })
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Divider()
            .strokeWidth(1)
            .color(Colors.Border)
            .margin({ top: 10, bottom: 10 })

          // 性别
          Row() {
            Text('性别')
              .fontSize(16)
              .margin({ left: 16, right: 16 })
              .fontColor(Colors.TextSecondary)
              .width(80)
            Row() {
              // 男性选项
              Row() {
                Radio({ value: '男', group: this.radioGroup })
                  .checked(this.gender === '男')
                  .size({ width: 24, height: 24 })
                  .onChange((checked: boolean) => {
                    if (checked) this.gender = '男';
                  })
                Text('男')
                  .fontSize(16)
                  .margin({ left: 8 })
              }
              .margin({ right: 30 })
              .onClick(() => this.gender = '男')

              // 女性选项
              Row() {
                Radio({ value: '女', group: this.radioGroup })
                  .checked(this.gender === '女')
                  .size({ width: 24, height: 24 })
                  .onChange((checked: boolean) => {
                    if (checked) this.gender = '女';
                  })
                Text('女')
                  .fontSize(16)
                  .margin({ left: 8 })
              }
              .onClick(() => this.gender = '女')
            }
            .layoutWeight(1)
            .margin({ right: 16 })
          }
          .margin({ top: 8, bottom: 20 })
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Divider()
            .strokeWidth(1)
            .color(Colors.Border)
            .margin({ top: 10, bottom: 10 })

          // 备注
          Column() {
            Text('备注')
              .fontSize(16)
              .margin({ left: 16, bottom: 8 })
              .fontColor(Colors.TextSecondary)
              .width('100%')
            TextArea({ text: this.remark, placeholder: '请输入备注信息' })
              .height(120)
              .width('100%')
              .fontSize(16)
              .padding(12)
              .backgroundColor(Colors.White)
              .borderRadius(8)
              .border({ width: 0, color: Colors.Border })
              .margin({ left: 16, right: 16 })
              .onChange((value: string) => this.remark = value)
          }
          .margin({ top: 8, bottom: 30 })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.Background)
  }
}
