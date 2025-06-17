# PDF Flipbook

แอปพลิเคชันสำหรับอ่าน PDF ในรูปแบบ Flipbook ที่สวยงาม

## GitHub Repository
🔗 [https://github.com/iNT-Mahidol/IdeaSpace-Flipbook-Flutter](https://github.com/iNT-Mahidol/IdeaSpace-Flipbook-Flutter)

## ฟีเจอร์

- **เลือกไฟล์ PDF**: รองรับการเลือกไฟล์ PDF จากอุปกรณ์
- **Flipbook แบบ 3D**: แสดงผล PDF ในรูปแบบการพลิกหน้าแบบสมจริง
- **ประมวลผลล่วงหน้า**: แปลง PDF ทุกหน้าเป็น Widget ก่อนแสดงผล
- **แสดงสถานะหน้า**: แสดงหมายเลขหน้าปัจจุบันและจำนวนหน้าทั้งหมด
- **UI ที่สวยงาม**: ออกแบบให้ใช้งานง่ายและสวยงาม

## การทำงาน

1. **การเลือกไฟล์**: ผู้ใช้เลือกไฟล์ PDF จากอุปกรณ์
2. **การประมวลผล**: 
   - อ่านไฟล์ PDF
   - แปลงแต่ละหน้าเป็น image
   - สร้าง Widget สำหรับแต่ละหน้า
   - เก็บ Widget ทั้งหมดใน List<Widget>
3. **การแสดงผล**: ใช้ PageFlip widget เพื่อแสดงผลแบบ flipbook

## โครงสร้างโค้ด

### ไฟล์หลัก

- `main.dart`: หน้าจอหลักและการเลือกไฟล์
- `PdfScreen.dart`: หน้าจอแสดงผล PDF flipbook
- `pdf_processor.dart`: ประมวลผล PDF และสร้าง Widget
- `pdf_page.dart`: Widget สำหรับแสดงแต่ละหน้า PDF

### Dependencies ที่ใช้

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  page_flip: ^0.2.1           # สำหรับ flipbook effect
  file_picker: ^8.1.3         # เลือกไฟล์
  flutter_pdfview: ^1.3.2     # อ่าน PDF (เป็น fallback)
  path_provider: ^2.1.4       # จัดการ path
  pdf: ^3.11.0                # ประมวลผล PDF
  printing: ^5.12.0           # แปลง PDF เป็น image
```

## การติดตั้งและใช้งาน

### การติดตั้งจาก GitHub
1. Clone โปรเจค:
   ```bash
   git clone https://github.com/iNT-Mahidol/IdeaSpace-Flipbook-Flutter.git
   cd IdeaSpace-Flipbook-Flutter
   ```
2. ติดตั้ง dependencies: `flutter pub get`
3. รันแอป: `flutter run`

## วิธีการใช้งาน

1. เปิดแอป
2. กดปุ่ม "เลือกไฟล์ PDF"
3. เลือกไฟล์ PDF จากอุปกรณ์
4. กดปุ่ม "เปิด PDF Flipbook"
5. รอให้ระบบประมวลผล PDF
6. เมื่อเสร็จแล้วจะแสดงผลแบบ flipbook
7. ใช้นิ้วสัมผัสเพื่อพลิกหน้า

## ข้อควรทราบ

- การประมวลผล PDF ขนาดใหญ่อาจใช้เวลาสักครู่
- แอปจะแสดง loading indicator ขณะประมวลผล
- Widget ทั้งหมดจะถูกสร้างและเก็บไว้ในหน่วยความจำก่อนแสดงผล
- ความละเอียดของรูปภาพตั้งไว้ที่ 150 DPI เพื่อความชัดเจนและประสิทธิภาพ

## การพัฒนาต่อ

สามารถพัฒนาเพิ่มเติม:
- เพิ่มการ zoom in/out
- เพิ่มการค้นหาข้อความ
- เพิ่มการ bookmark
- เพิ่มการแชร์
- เพิ่มการปรับความสว่าง
