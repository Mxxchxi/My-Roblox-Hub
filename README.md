# My-Roblox-Hub

## Roll A Stickman — V1.2 R9

PlaceId: `115068315659966`

- สคริปต์หลัก: [Games/RollStickman_Combined_V1_2.lua](Games/RollStickman_Combined_V1_2.lua)
- Loader: [Loader.lua](Loader.lua)
- ระบบ: RAID, Dungeon ทุกประเภท, Expeditions, Level Up, Aurora Boost และ ANTI AFK
- UI ลากได้ มีปุ่มย่อ/ขยาย และคีย์ลัด Alt
- เมื่อ Dungeon ทั้งสองประเภทไม่มีตั๋ว จะตรวจใหม่หลัง 2 ชั่วโมง
- จำสวิตช์และตำแหน่ง UI ผ่าน readfile/writefile เมื่อ executor รองรับ
- ANTI AFK เปิดเป็นค่าเริ่มต้นสำหรับการติดตั้งครั้งแรก; สวิตช์อื่นเริ่ม OFF

## การใช้งาน

รันบรรทัดนี้ใน executor ที่รองรับ `game:HttpGet` และ `loadstring`:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"))()
```

บรรทัดนี้โหลดสคริปต์จาก branch `main` ทุกครั้ง จึงได้รับเวอร์ชันที่อัปเดตบน GitHub

สำหรับ Auto Execute ให้เพิ่มบรรทัดเดียวกันในรายการ Auto Execute ของ executor และเปิดใช้งาน สคริปต์จะรอเกมและ UI โหลดก่อนเริ่ม และคืนค่าการตั้งค่าที่บันทึกไว้

## ข้อจำกัด

- การกดปุ่มเกมต้องมี `firesignal`
- การจำค่าข้ามการเปิด Roblox ต้องมี `readfile` และ `writefile`
- ANTI AFK พยายามส่ง input เมื่อเกิด `Player.Idled`; ถ้า executor ไม่รองรับ จะปิดสวิตช์และแจ้งใน log
- ANTI AFK ไม่ป้องกันเน็ตหลุด เกมแครช หรือการตัดการเชื่อมต่อจากเซิร์ฟเวอร์
- ตรวจไวยากรณ์และทดสอบบางส่วนด้วยสภาพจำลองแล้ว ยังไม่ได้ทดสอบ end-to-end ใน Roblox

กด **COPY LOG** เพื่อเก็บผลการทำงานสำหรับตรวจปัญหา
