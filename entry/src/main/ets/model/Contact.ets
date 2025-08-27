export class Contact {
  id?: number;
  name: string = '';
  phone: string = '';
  gender: string = '';
  remark: string = '';

  constructor(id: number, name: string, phone: string, gender: string, remark: string) {
    this.id = id;
    this.name = name;
    this.phone = phone;
    this.gender = gender;
    this.remark = remark;
  }
}