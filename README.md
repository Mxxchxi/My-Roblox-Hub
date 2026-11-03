# My-Roblox-Hub

## Roll A Stickman — V1.2 R12

PlaceId: `115068315659966`

- สคริปต์หลัก: [Games/RollStickman_Combined_V1_2.lua](Games/RollStickman_Combined_V1_2.lua)
- Loader: [Loader.lua](Loader.lua)
- ระบบ: RAID, Dungeon ทุกประเภท, Expeditions, Level Up, Use Potion When และ ANTI AFK
- UI แบ่งเป็น Team / Fight / Potion / Status ลากได้ มีปุ่มย่อ/ขยาย และคีย์ลัด Alt
- Team: Level Up; Fight: RAID / Dungeon / Expeditions; Potion: Use Potion When และสต็อกยา
- Potion: เปิด USE POTION เลือกชนิด Moon/Aura จาก dropdown แล้วติ๊ก Luck Potion / Haste Potion / Gilded Potion ตามที่ต้องการ
- กด SYNC ในหน้า Potion เพื่ออ่านหน้า MOONS; รายชื่อใน dropdown จะเพิ่มจากหัวข้อ Moon และรายการ Summon ที่อ่านได้จาก UI เกมจริง พร้อมจำรายชื่อที่เคยอ่านได้ไว้
- รายการ dropdown เลื่อนได้ การอ่านชื่อจากร้านใช้เพื่อสร้างรายการตัวเลือกเท่านั้น; การเริ่มใช้ยายืนยันจาก MOONS > Now.Title ที่กำลังแสดง และต้องตรงชนิดที่เลือก
- หากยังมีเฉพาะ Aurora ให้เปิดหน้า MOONS แล้วกด SYNC; เกมอาจยังไม่ได้สร้าง UI รายการ Moon อื่นใน client
- ใช้เฉพาะยาที่ติ๊กไว้และยังไม่ active; การเปิดการ์ดที่มีอยู่จะทำต่อหลังขั้นตอนยาตามเดิม
- จำเงื่อนไขและ checkbox ของยาเมื่อรันใหม่; ค่าเดิมที่ยังไม่เคยเลือกจะเริ่มด้วยยาทั้ง 3 ชนิด
- Status: Luck, Aura ที่ยืนยันล่าสุด, พลังทีม, เวฟ, Rolls, Auto Roll, ตั๋วดันเจี้ยน, เวลาเช็กครั้งถัดไป, การ์ด และสต็อกยา
- ค่า Status อัปเดตประมาณทุกวินาที; ค่า UI ที่ซ่อนอยู่แสดง last seen พร้อมอายุข้อมูล
- Aura ยืนยันจาก MOONS > Now.Title เมื่อหน้าต่างถูกอ่าน; ไม่ใช้ชื่อ Aura จากร้านค้า
- พลังทีมอ่านเฉพาะช่อง TEAM POWER / TOTAL POWER ที่พบใน UI; ถ้าไม่พบจะระบุ Not found
- จำแท็บที่เลือกไว้เมื่อรันใหม่
- Diagnostics ที่รองรับแท็บและการย่อ: [Games/RollStickman_Diagnostics_V1_5.lua](Games/RollStickman_Diagnostics_V1_5.lua)
- เมื่อ Dungeon ทั้งสองประเภทไม่มีตั๋ว จะตรวจใหม่หลัง 2 ชั่วโมง
- จำสวิตช์และตำแหน่ง UI ผ่าน readfile/writefile เมื่อ executor รองรับ
- ANTI AFK เปิดเป็นค่าเริ่มต้นสำหรับการติดตั้งครั้งแรก; สวิตช์อื่นเริ่ม OFF

## การใช้งาน

รันบรรทัดนี้ใน executor ที่รองรับ `game:HttpGet` และ `loadstring`:

```lua
local url = "https://raw.githubusercontent.com/Mxxchxi/My-Roblox-Hub/main/Loader.lua"
loadstring(game:HttpGet(url .. "?_=" .. game:GetService("HttpService"):GenerateGUID(false)))()
```

โค้ดนี้เพิ่ม query ที่ไม่ซ้ำให้ URL ของ Loader เพื่อลดการได้ไฟล์จากแคช ส่วน Loader V2 จะหา commit ล่าสุดแล้วโหลดไฟล์หลักผ่าน commit SHA พร้อมตรวจว่าเป็น R10 ขึ้นไปและ UI เปิดสำเร็จ

หากบันทึก Loader เก่าไว้ใน Auto Execute ให้แทนที่ด้วยโค้ดด้านบนหนึ่งครั้ง

สำหรับ Auto Execute ให้เพิ่มบรรทัดเดียวกันในรายการ Auto Execute ของ executor และเปิดใช้งาน สคริปต์จะรอเกมและ UI โหลดก่อนเริ่ม และคืนค่าการตั้งค่าที่บันทึกไว้

## ข้อจำกัด

- การกดปุ่มเกมต้องมี `firesignal`
- การจำค่าข้ามการเปิด Roblox ต้องมี `readfile` และ `writefile`
- ANTI AFK พยายามส่ง input เมื่อเกิด `Player.Idled`; ถ้า executor ไม่รองรับ จะปิดสวิตช์และแจ้งใน log
- ANTI AFK ไม่ป้องกันเน็ตหลุด เกมแครช หรือการตัดการเชื่อมต่อจากเซิร์ฟเวอร์
- ตรวจไวยากรณ์และทดสอบบางส่วนด้วยสภาพจำลองแล้ว ยังไม่ได้ทดสอบ end-to-end ใน Roblox

กด **COPY LOG** เพื่อเก็บผลการทำงานสำหรับตรวจปัญหา
