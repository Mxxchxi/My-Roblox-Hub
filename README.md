# My-Roblox-Hub

## Roll A Stickman — V1.2 R21 · Neon V2

PlaceId: `115068315659966`

- สคริปต์หลัก: [Games/RollStickman_Combined_V1_2.lua](Games/RollStickman_Combined_V1_2.lua)
- Loader: [Loader.lua](Loader.lua)
- ระบบ: RAID, Dungeon ทุกประเภท, Expeditions, Level Up, Use Potion When และ ANTI AFK
- UI Neon V2 สีม่วง ขนาด 670×460 ใช้เมนูด้านซ้ายจากต้นแบบ RollAStickman_NeonV2.lua
- เมนู Status / Team / Fight / Potion / Pet / Open Card / Moon / Settings; ลากได้ มีปุ่มย่อ/ขยาย และคีย์ลัด Alt
- ใช้ฟังก์ชันจริงจาก R18; ไม่ใช้ตัวเลือก Aurora A/B/C หรือปุ่มสาธิตของต้นแบบ
- หน้า Moon แสดงชนิด/เวลาคงเหลือ พร้อม SYNC MOON NOW; ตรวจอัตโนมัติเมื่อยังไม่ทราบ Moon, เวลาหมด หรือไอคอนเปลี่ยน
- หน้า Settings รวม ANTI AFK, สถานะการบันทึกค่า, COPY LOG / PET REPORT Activity Log ที่เลื่อนได้ และ Discord Webhook
- STOP ALL ปิดทุกสวิตช์; RESTORE SWITCHES คืนเฉพาะสวิตช์ที่เปิดอยู่ก่อน STOP ALL ครั้งล่าสุดในรอบการรันปัจจุบัน
- Diagnostics R10 เริ่มที่ x=700 เพื่อพ้นหน้าต่างหลักที่เริ่ม x=12 และกว้าง 670; ใช้สีเดียวกันและยังลากย้ายได้
- Team: Level Up; Fight: RAID / Dungeon / Expeditions; Potion: Use Potion When และสต็อกยา
- Potion: เปิด USE POTION แล้วเลือก Moon ได้หลายตัวจาก dropdown แบบ checkbox พร้อมเลือก Luck / Haste / Gilded Potion
- Normal ยืนยันเป็น x1; ตัวคูณที่ทราบเรียงจากน้อยไปมาก
- อ่าน Moon พร้อมเวลาจริงจาก MOONS > Now.Title; หากไม่มีเวลาที่หัวข้อ ใช้ The sky rolls again in จาก Now.Sub หรือเวลาบน HUD
- ระหว่าง countdown ที่ยืนยันแล้วยังใช้ได้ จะใช้ข้อมูลที่จำไว้โดยไม่เปิด MOONS ซ้ำ; เมื่อหมดเวลาจะอ่านใหม่ แม้ Moon รอบใหม่ชื่อเดิม
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
- Open Card มี Open Card When แบบ multi-select ของตัวเอง แยกจาก Use Potion When; จำตัวเลือกแยกเมื่อรันใหม่
- ย้ายค่ารุ่นเก่าโดยคัดลอกชุด Moon ของ Potion มาเป็นค่าเริ่มต้นของ Open Card เพียงครั้งแรก หลังจากนั้นแก้แต่ละชุดได้อิสระ
- เพิ่ม Require active Luck Potion และ Require active Pet Luck เปิดเป็นค่าเริ่มต้น; ถ้ายังยืนยันบัฟไม่ได้ ระบบจะรอและไม่เปิดการ์ด
- Luck Potion ใช้เวลาคงเหลือที่อ่านจาก POTIONS
- Pet Luck รองรับโบนัส Pet ที่สวมอยู่จาก OnHead เช่น EQUIPPED 3/4 · +5% luck · +24.4% rolls from play และยังรองรับบัฟแบบจับเวลา
- ข้อมูล Pet ที่สวมอยู่มีอายุยืนยัน 5 นาที; เมื่อจำเป็นจะตรวจผ่านปุ่ม PETS ที่ค้นพบจริงใน UI โดยไม่กด EQUIP BEST หรือเลือก Pet แบบสุ่ม
- รอบทำงาน: ยาตาม Potion When → Luck Pet → ตรวจเงื่อนไข/เปิดการ์ดตาม Open Card When → ปิดหน้าการ์ด → Rolls Pet → กลับต่อสู้
- หากเงื่อนไขการ์ดไม่ครบ จะข้ามการ์ดแล้วคืน Rolls Pet และกลับต่อสู้; ถ้าบัฟที่จำเป็นหมดระหว่างเปิดจะหยุดกดรอบถัดไป
- แต่ละขั้นยังเคารพสวิตช์/checkbox; ไม่บังคับใช้ Potion ใน Moon ที่ไม่ได้เลือก แม้จะเลือก Moon นั้นไว้สำหรับ Open Card
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

## Pet — AUTO PET

- เปิด Pet > AUTO PET; Boost luck pet when ใช้ Moon แบบ multi-select และ Boost cards from play ใช้ Every X minutes (1–120 นาที เริ่มต้น 5 นาที)
- รอบเปิดการ์ดใช้ Luck Pet ที่มีโบนัสสูงสุดเมื่อ AUTO PET เปิด; หลังจบ/ข้ามการ์ดจะคืน Rolls Pet แม้ Moon นั้นยังไม่หมด
- Boost luck pet when ยังใช้กับงาน Pet แยก และ Boost cards from play ยังมี Every X minutes ระหว่างรอบ
- เมื่อนำ Rolls Pet กลับแล้ว งาน Pet แยกจะไม่เปลี่ยนกลับเป็น Luck Pet ทันทีใน Moon รอบเดิม; play timer เริ่มนับจากการคืนค่าครั้งนั้น
- รอบตรวจที่สวม Pet ไม่สำเร็จจะไม่เลื่อนกำหนดครั้งถัดไป; ถ้า Pet เป้าหมายสวมอยู่แล้วจะยืนยันโดยไม่กดถอด
- ปรับเวลาได้ด้วยปุ่ม - / + หรือพิมพ์นาทีลงช่อง; มีสวิตช์ปิดเฉพาะ play timer และแสดงเวลาคงเหลือ
- เงื่อนไข Luck Pet มีลำดับก่อน play timer
- ครั้งแรกอ่านค่า Gives จากรายละเอียดของ Pet ที่มีทั้งหมด โดยตรวจชื่อและระดับของการ์ดให้ตรงกันก่อนบันทึก; ไม่เดาค่าจากความหายาก
- จำค่าสเตตัสที่อ่านได้เมื่อรันใหม่ และอ่านใหม่เมื่อชื่อ/ระดับเปลี่ยน; SCAN PET STATS อ่านใหม่ทุกตัวโดยไม่เปลี่ยนอุปกรณ์
- ตรวจ EQUIP/UNEQUIP ก่อนทำงาน; หากสวมอยู่แล้วจะไม่กด UNEQUIP รวมถึง Pet ใน Den
- ยืนยันผล EQUIP จากปุ่มที่เปลี่ยนเป็น UNEQUIP, ป้าย ON และโบนัสรวมใน OnHead ก่อนรายงานว่าสำเร็จ
- หากเกมไม่ยอมสวม หรือข้อมูลไม่ตรง จะบันทึกว่าไม่ยืนยันและให้ Open Card รอ; ไม่ถอด Pet เดิมโดยคาดเดา
- เมื่อ AUTO PET เปิด Open Card จะรอการยืนยัน Pet ตามเงื่อนไขก่อนเปิดการ์ด แล้วตรวจ Luck Potion / Pet Luck ตาม checkbox ที่ตั้งไว้
- AUTO PET เริ่ม OFF สำหรับผู้ที่ยังไม่เคยตั้งค่า; จำสวิตช์และตัวเลือกเมื่อรันใหม่
- Pet ใช้ตัวตรวจ Moon ร่วมกับ Potion / Open Card; Diagnostics R10 จะไม่เปิด MOONS แทรกเมื่อระบบใดระบบหนึ่งเปิดอยู่
- ปุ่ม CAPTURE (3s) ยังใช้เก็บรายละเอียด Pet สำหรับแก้ปัญหาได้; COPY LOG รวมทุก capture และบันทึก RollStickman_PetUI_Report.txt เมื่อ writefile รองรับ

## รอบทำงานเมื่อ Moon ตรงเงื่อนไข

1. ถ้า Moon ยังไม่ทราบหรือหมดเวลา อ่านสถานะพร้อม countdown ใหม่
2. เมื่อ Moon ตรง Potion When หรือ Open Card When ที่เปิดใช้งาน เริ่มรอบหนึ่งครั้งต่อ Moon window
3. ใช้เฉพาะ Potion ที่เลือก เมื่อ Moon ตรง Potion When
4. ใส่ Luck Pet เมื่อ AUTO PET เปิด แล้วตรวจ checkbox ของ Open Card
5. เปิดเฉพาะการ์ดที่เลือกเมื่อ Moon ตรง Open Card When และเงื่อนไขครบ; หากไม่ครบให้ข้าม
6. ปิด CARD PACKS ทั้งเมื่อจบ, เงื่อนไขไม่ครบ, หมดเวลา, คำสั่งไม่ยืนยัน หรือเกิดข้อผิดพลาด
7. คืน Rolls Pet เมื่อ AUTO PET ยังเปิด แล้วส่งกลับหน้าต่อสู้

ตรวจการปิดหน้าต่างก่อนทำขั้นถัดไป; หากปิดไม่สำเร็จจะรายงาน unconfirmed แทนการกดปุ่มหลังหน้าต่างนั้น การกด STOP ALL จะยกเลิกการสวม Pet เพิ่มเติม

## Moon และ Discord Webhook

- Moon ใช้ countdown tracking; ช่องนาที 1–120 ใช้กำหนดการลองใหม่เมื่ออ่าน Moon/เวลาไม่สำเร็จเท่านั้น
- ใช้ข้อมูล Moon/เวลาที่เคยยืนยันจนหมดอายุ; ไม่เดาจากชื่อในร้านหรือชื่อที่ซ่อนอยู่ในหน้าต่างเก่า
- ระบบ countdown แทนที่โหมด HUD ONLY รุ่นก่อน เพื่อให้ตรวจ Moon ที่ยังไม่ทราบ/หมดเวลาตามลำดับงานใหม่
- Diagnostics R10 ใช้เวลาสิ้นสุด Moon เดียวกับสคริปต์หลัก และไม่เปิดหน้าต่างแทรกระหว่างงานอัตโนมัติ
- Settings: วาง URL Discord Webhook มาตรฐาน แล้วเปิด Discord webhook: card opens; TEST WEBHOOK ส่งข้อความทดสอบเมื่อกดเท่านั้น
- Webhook เริ่ม OFF; จำ URL/สวิตช์ตามระบบบันทึกค่าของ executor และไม่พิมพ์ URL/token ใน log
- ทุกครั้งที่ส่งคำสั่งเปิด Reward Cards / Pouch / Crate / Chest จะเก็บเวลา, ชนิด/รอบ/สต็อก, Luck HUD, Luck หน้าต่อสู้, Moon, ตัวนับเวลา, Pet และสถานะยา
- บันทึกค่า Luck ก่อนกดปุ่มแต่ละรอบ; ค่าที่อ่านจาก cache จะมีอายุข้อมูลกำกับ ส่วนผลจำนวนการ์ดลดลงยังแสดงแยกหลังยืนยัน
- COPY LOG รวม CARD OPEN REPORT ล่าสุด 500 ครั้ง แยกจาก Activity Log ที่หมุนเวียน
- เมื่อ Webhook เปิด จะส่ง CARD OPEN PRESSED พร้อมสเตตัสนี้ผ่านคิวแยกจากลูปเกม; เคารพ rate-limit headers และลองใหม่เมื่อ HTTP 429 ไม่เกิน 3 ครั้ง
- ถ้า executor ไม่มี request/http_request ที่รองรับ HTTP จะเก็บ log ในเครื่องและแสดง Webhook unavailable

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
