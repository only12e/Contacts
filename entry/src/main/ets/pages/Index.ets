import router from '@ohos.router';             // 路由管理模块
import { Contact } from '../model/Contact';    // 联系人数据模型
import { relationalStore } from '@kit.ArkData'; // 关系型数据库模块
import { BusinessError } from '@kit.BasicServicesKit'; // 错误处理
import { storeDb } from '../entryability/EntryAbility'; // 数据库实例
import { promptAction } from '@kit.ArkUI';      // 用户提示组件

// 路由结果参数接口
interface ResultParams {
  result_code: number
}

@Entry
@Component
struct Index {
  // 状态变量
  @State contactsList: Array<Contact> = []      // 当前显示的联系人列表（含搜索过滤）
  @State resultParams: ResultParams | null = null // 路由传递的参数
  @State showDeleteDialog: boolean = false      // 删除对话框显示状态
  @State deleteTarget: Contact | null = null    // 待删除的联系人对象
  @State isLongPressActive: boolean = false     // 长按激活状态标志
  @State searchText: string = ''                // 搜索框文本内容
  @State isSearching: boolean = false           // 搜索模式状态标志

  // 私有变量
  private longPressTimer: number | null = null  // 长按计时器ID
  private originalContactsList: Array<Contact> = [] // 原始联系人列表（未过滤）

  // 清除长按计时器
  private clearLongPressTimer() {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
  }

  // 删除联系人方法
  private deleteContact() {
    if (!this.deleteTarget || !this.deleteTarget.id)
      return;

    // 构建数据库删除条件
    const predicates = new relationalStore.RdbPredicates('contact');
    predicates.equalTo('id', this.deleteTarget.id);

    // 执行数据库删除操作
    storeDb?.delete(predicates, (err: BusinessError) => {
      if (err) {
        console.error(`删除失败: ${err.code}, ${err.message}`);
        promptAction.showToast({ message: '删除失败' });
        return;
      }

      promptAction.showToast({ message: '已删除' });
      this.queryContactsListData();         // 刷新联系人列表
      this.showDeleteDialog = false;        // 关闭对话框
      this.deleteTarget = null;             // 清空删除目标
      this.isLongPressActive = false;       // 重置长按状态
    });
  }

  // 页面显示生命周期
  onPageShow(): void {
    this.resultParams = router.getParams() as ResultParams
    if (this.resultParams != null && this.resultParams.result_code == 200) {
      this.queryContactsListData()  // 结果码200时刷新数据
    }
  }

  // 组件即将显示生命周期
  aboutToAppear() {
    // 延迟加载数据（避免UI阻塞）
    setTimeout(() => {
      this.queryContactsListData()
    }, 800)
  }

  // 查询联系人数据
  queryContactsListData() {
    this.contactsList = []
    let predicates = new relationalStore.RdbPredicates('contact');
    // 执行数据库查询
    storeDb?.query(predicates, ['id', 'name', 'phone', 'gender', 'remark'],
      (err: BusinessError, resultSet) => {
        if (err) {
          console.error('Failed to query data. Code:', err.code);
          return;
        }
        // 遍历查询结果
        while (resultSet.goToNextRow()) {
          const id = resultSet.getLong(resultSet.getColumnIndex('id'));
          const name = resultSet.getString(resultSet.getColumnIndex('name'));
          const phone = resultSet.getString(resultSet.getColumnIndex('phone'));
          const gender = resultSet.getString(resultSet.getColumnIndex('gender'));
          const remark = resultSet.getString(resultSet.getColumnIndex('remark'));
          // 添加到联系人列表
          this.contactsList.push(new Contact(id, name, phone, gender, remark))
        }
        // 保存原始数据副本（用于搜索过滤）
        this.originalContactsList = [...this.contactsList];
        resultSet.close()
      });
    return this.contactsList
  }

  // 联系人搜索过滤
  private filterContacts() {
    if (this.searchText.trim() === '') {
      // 搜索文本为空时恢复完整列表
      this.contactsList = [...this.originalContactsList];
      return;
    }

    // 执行不区分大小写的搜索
    const searchTerm = this.searchText.toLowerCase();
    this.contactsList = this.originalContactsList.filter(contact =>
    contact.name.toLowerCase().includes(searchTerm));
  }

  // 切换搜索模式
  private handleSearchEnter() {
    this.filterContacts();
  }

  // 新增：切换搜索状态
  private toggleSearch() {
    if (this.isSearching) {
      // 退出搜索模式时重置状态
      this.searchText = '';
      this.contactsList = [...this.originalContactsList];
    }
    this.isSearching = !this.isSearching;
  }

  // UI构建函数
  build() {
    Stack() {
      Column() {
        // --- 顶部标题栏/搜索栏 ---
        if (this.isSearching) {
          // 搜索模式UI
          Row() {
            // 返回按钮
            Image($r('app.media.left'))
              .width(30)
              .height(30)
              .margin({ left: 16 })
              .onClick(() => this.toggleSearch()) // 退出搜索模式

            // 搜索输入框
            TextInput({ text: this.searchText, placeholder: '输入姓名搜索' })
              .height(40)
              .width('80%')
              .fontSize(16)
              .margin({ left: 12 })
              .backgroundColor(Color.White)
              .borderRadius(8)
              .padding(8)
              .onChange((value: string) => {
                this.searchText = value;
                this.filterContacts();  // 实时过滤
              })
              .onSubmit(() => this.handleSearchEnter()) // 回车提交
          }
          .width('100%')
          .height(60)
          .backgroundColor($r('app.color.background_secondary'))
          .alignItems(VerticalAlign.Center)
        } else {
          // 原标题栏
          Row() {
            Text('通讯录')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 16 })
            Blank() // 占位空间

            // 新增：搜索按钮
            Image($r('app.media.search')) // 进入搜索模式
              .width(40)
              .height(40)
              .margin({ right: 16 })
              .onClick(() => this.toggleSearch())

            // 添加联系人图标
            Image($r('app.media.add'))
              .width(30)
              .height(30)
              .margin({ right: 16 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/AddContact',  // 跳转添加页面
                });
              })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .backgroundColor($r('app.color.background_secondary'))
        }

        // --- 联系人列表 ---
        List() {
          ForEach(this.contactsList, (contact: Contact) => {
            ListItem() {
              // 列表项内容
              Row({ space: 10 }) {
                Image(contact.gender === '男' ?
                $r('app.media.man') :
                $r('app.media.lady'))
                  .width(44)
                  .height(44)
                  .objectFit(ImageFit.Contain)
                  .margin({ left: 12 })

                Column() {
                  Text(contact.name)
                    .fontSize(18)
                  Text(contact.phone)
                    .fontColor($r('app.color.text_tertiary'))
                    .fontSize(14)
                    .margin({ top: 6 })
                }
                .margin({ left: 10 })
                .alignItems(HorizontalAlign.Start)

                Blank()
              }
              .padding(10)
              .width('100%')
              .onClick(() => {
                // 确保不是长按触发点击
                if (!this.isLongPressActive && !this.showDeleteDialog) {
                  router.pushUrl({
                    url: 'pages/ContactDetail',
                    params: { contact: contact }  // 传递联系人数据
                  });
                }
              })
              // 添加触摸事件处理
              .onTouch((event) => {
                // 长按事件处理
                if (event.type === TouchType.Down) {
                  // 开始计时
                  this.isLongPressActive = false;
                  // 设置长按计时器(800ms)
                  this.longPressTimer = setTimeout(() => {
                    this.deleteTarget = contact;
                    this.showDeleteDialog = true;
                    this.isLongPressActive = true;
                    this.longPressTimer = null;
                  }, 800); // 800毫秒长按触发
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  // 释放触摸时清除计时器
                  this.clearLongPressTimer();
                }
              })
            }
          }, (contact: Contact) => contact.id?.toString() ?? '')  // 唯一键生成
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)  // 占据剩余空间
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_primary'))
      .padding({ top: 12 })

      // --- 删除确认对话框 ---
      if (this.showDeleteDialog) {
        // 半透明背景层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.showDeleteDialog = false;
            this.isLongPressActive = false; // 重置长按标志
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

        // 对话框内容
        Column() {
          Text('确定删除联系人？')
            .fontSize(20)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 24, bottom: 16 })

          Text(`将永久删除 ${this.deleteTarget?.name || ''}`)
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 24 })

          // 分隔线
          Divider()

          // 操作按钮行
          Row() {
            Button('取消')
              .layoutWeight(1)
              .height(48)
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.text_secondary'))
              .onClick(() => {
                this.showDeleteDialog = false;
                this.isLongPressActive = false; // 重置长按标志
                this.deleteTarget = null;
              })

            // 垂直分隔线
            Divider()
              .vertical(true)
              .height(24)
              .margin({ left: 8, right: 8 })

            Button('删除')
              .layoutWeight(1)
              .height(48)
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.error'))
              .onClick(() => this.deleteContact())
          }
          .width('100%')
          .height(56)
          .padding({ left: 24, right: 24 })
        }
        .width('80%')
        .backgroundColor($r('app.color.background_primary'))
        .borderRadius(16)
        .shadow({ radius: 24, color: 'rgba(0,0,0,0.1)' })
      }
    }
    .width('100%')
    .height('100%')
  }
}