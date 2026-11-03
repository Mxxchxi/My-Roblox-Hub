# My-Roblox-Hub

## Roll A Stickman — V1.2 R16

PlaceId: `115068315659966`

- สคริปต์หลัก: [Games/RollStickman_Combined_V1_2.lua](Games/RollStickman_Combined_V1_2.lua)
- Loader: [Loader.lua](Loader.lua)
- ระบบ: RAID, Dungeon ทุกประเภท, Expeditions, Level Up, Use Potion When และ ANTI AFK
- UI แบ่งเป็น Team / Fight / Potion / Pet / Open Card / Status ลากได้ มีปุ่มย่อ/ขยาย และคีย์ลัด Alt
- Team: Level Up; Fight: RAID / Dungeon / Expeditions; Potion: Use Potion When และสต็อกยา
- Potion: เปิด USE POTION แล้วเลือก Moon ได้หลายตัวจาก dropdown แบบ checkbox พร้อมเลือก Luck / Haste / Gilded Potion
- Normal ยืนยันเป็น x1; ตัวคูณที่ทราบเรียงจากน้อยไปมาก
- ตรวจ Moon จากไอคอน HUD ที่เคยยืนยันกับ MOONS แล้ว เมื่อไอคอนยังไม่รู้จักจะเปิดตรวจอัตโนมัติไม่ถี่กว่า 300 วินาที
- ไอคอนที่พบว่าใช้ร่วมกันหลาย Moon จะไม่ใช้ระบุชนิด; ใช้การตรวจหน้า MOONS ทุก 5 นาทีแทน
- ปุ่ม SYNC เป็นการตรวจตามคำสั่งผู้ใช้ จึงกดได้ทันที
- ชื่อที่ยืนยันจากภาพเกมมีพร้อมใช้: Normal, Silver, Harvest, Blue, Eclipse, Starfall, Aurora
- แสดงตัวคูณหลังชื่อ เช่น Silver (x1.5), Aurora (x12) และเรียงค่าที่ทราบจากน้อยไปมาก
- ตัวคูณที่ยังอ่านไม่ได้แสดง x? อยู่ท้ายรายการ; กด SYNC เพื่ออ่านค่า Luck ของ Moon จากเกมและบันทึกไว้
- Dropdown แสดงครบ 7 รายการพร้อมกัน; หากมีชื่อเพิ่มจะเลื่อนได้ และเลื่อนไปยังตัวเลือกปัจจุบันเมื่อเปิด
- กด SYNC ในหน้า Potion เพื่ออ่านหน้า MOONS เพิ่มเติมและจำรายชื่อที่เคยอ่านได้ไว้
- รายการ dropdown เลื่อนได้ การอ่านชื่อจากร้านใช้เพื่อสร้างรายการตัวเลือกเท่านั้น; การเริ่มใช้ยายืนยันจาก MOONS > Now.Title ที่กำลังแสดง และต้องตรงชนิดที่เลือก
- รองรับชื่อ Aura ปัจจุบันที่ไม่ลงท้ายด้วย Moon และหัวข้อชื่อสั้นในรายการที่มีค่า Luck แยกอีกช่อง
- SYNC บันทึก MOON DATA และข้อความ UI จากหน้า MOONS ลง COPY LOG เพื่อระบุชื่อที่ยังขาด
- หากรายชื่อยังขาด ให้เปิด MOONS แล้วกด SYNC จากนั้นส่ง COPY LOG เพื่อยืนยันชื่อและตำแหน่ง UI จริง
- ใช้เฉพาะยาที่ติ๊กไว้และยังไม่ active
- แท็บ Open Card มี AUTO OPEN CARD และ checkbox แยก Reward Cards / Pouch / Crate / Chest
- Open Card ใช้ชุด Moon เดียวกับ Use Potion When แต่เปิด/ปิดแยกจาก USE POTION ได้
- เพิ่ม Require active Luck Potion และ Require active Pet Luck เปิดเป็นค่าเริ่มต้น; ถ้ายังยืนยันบัฟไม่ได้ ระบบจะรอและไม่เปิดการ์ด
- Luck Potion ใช้เวลาคงเหลือที่อ่านจาก POTIONS; Pet Luck อ่านเฉพาะตัวแสดงบัฟที่กำลังแสดงและมีเวลา/ACTIVE ชัดเจน
- เมื่อเปิดทั้งสองระบบ จะใช้ยาที่เลือกก่อนเปิดการ์ด; เปิดเฉพาะรายการที่มีอยู่และไม่กด GET MORE
- ตั้งค่าจากรุ่นเก่าที่ยังเปิด USE POTION อยู่จะคืนค่า AUTO OPEN CARD เป็น ON เพื่อรักษาพฤติกรรมเดิม; การติดตั้งใหม่เริ่ม OFF
- จำเงื่อนไขและ checkbox ของยาเมื่อรันใหม่; ค่าเดิมที่ยังไม่เคยเลือกจะเริ่มด้วยยาทั้ง 3 ชนิด
- ถ้าเลือก Starfall ไว้ จะไม่ใช้ยาระหว่าง Aurora; เปลี่ยน dropdown เป็น Aurora เมื่อต้องการเงื่อนไขนั้น
- Status: Luck, Aura ที่ยืนยันล่าสุด, พลังทีม, เวฟ, Rolls, Auto Roll, ตั๋วดันเจี้ยน, เวลาเช็กครั้งถัดไป, การ์ด และสต็อกยา
- ค่า Status อัปเดตประมาณทุกวินาที; ค่า UI ที่ซ่อนอยู่แสดง last seen พร้อมอายุข้อมูล
- Aura ยืนยันจาก MOONS > Now.Title เมื่อหน้าต่างถูกอ่าน; ไม่ใช้ชื่อ Aura จากร้านค้า
- พลังทีมอ่านเฉพาะช่อง TEAM POWER / TOTAL POWER ที่พบใน UI; ถ้าไม่พบจะระบุ Not found
- จำแท็บที่เลือกไว้เมื่อรันใหม่
- Diagnostics ที่รองรับแท็บและการย่อ: [Games/RollStickman_Diagnostics_V1_5.lua](Games/RollStickman_Diagnostics_V1_5.lua)
- เมื่อ Dungeon ทั้งสองประเภทไม่มีตั๋ว จะตรวจใหม่หลัง 2 ชั่วโมง
- จำสวิตช์และตำแหน่ง UI ผ่าน readfile/writefile เมื่อ executor รองรับ
- ANTI AFK เปิดเป็นค่าเริ่มต้นสำหรับการติดตั้งครั้งแรก; สวิตช์อื่นเริ่ม OFF

## Pet — ต้องมีข้อมูล UI เพื่อผูกคำสั่งจริง

- เพิ่มแท็บ Pet และ multi-select สองชุด: Boost luck pet when และ Boost card from play (if not Aurora)
- ชุดที่สองไม่ให้เลือก Aurora
- ขณะนี้บันทึกเงื่อนไข Pet ได้ แต่ **ยังไม่กดบูสต์ Pet อัตโนมัติ** เพราะยังไม่มีปุ่ม/สถานะจากหน้า Pet จริง
- เปิด PETS ในเกม แล้วกด Pet > CAPTURE PET UI > COPY LOG และส่งรายงาน เพื่อผูกปุ่มทั้งสองให้ถูกต้อง
- ถ้า Require active Pet Luck เปิดอยู่และยังยืนยันบัฟไม่ได้ Open Card จะรอ

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
