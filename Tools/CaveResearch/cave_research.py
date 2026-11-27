"""My Anime Mine cave research assistant. Reads the foreground window and uses ordinary mouse input."""
import ctypes
import io
import os
import re
import shutil
import subprocess
import sys
import time
from decimal import Decimal
from pathlib import Path

import numpy as np
from PIL import Image, ImageGrab, ImageOps


class Pause(Exception):
    """The current screen does not establish a safe next action."""


def bands(indices, gap=1):
    if not len(indices):
        return []
    return [(int(g[0]), int(g[-1]) + 1) for g in np.split(indices, np.where(np.diff(indices) > gap)[0] + 1)]


def ocr(mask, alphabet=None):
    ys, xs = np.where(mask)
    if not len(xs):
        return ""
    img = Image.fromarray(np.where(mask[ys.min():ys.max()+1, xs.min():xs.max()+1], 0, 255).astype("uint8"))
    factor = max(1, min(5, 64 // max(img.height, 1)))
    img = ImageOps.expand(img.resize((img.width*factor, img.height*factor)), 12, fill=255)
    path = shutil.which("tesseract") or str(Path(os.getenv("ProgramFiles", "")) / "Tesseract-OCR/tesseract.exe")
    cmd = [path, "stdin", "stdout", "-l", "eng", "--psm", "7"]
    if alphabet:
        cmd += ["-c", "tessedit_char_whitelist=" + alphabet]
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    p = subprocess.run(cmd, input=buf.getvalue(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=8,
                       creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    if p.returncode:
        raise Pause("OCR failed. Check the English Tesseract language pack.")
    return p.stdout.decode().strip()


def money(s):
    m = re.fullmatch(r'\$([0-9]+(?:\.[0-9]+)?)([a-zA-Z]*)', s.replace(' ', ''))
    if not m:
        raise Pause("Unreadable price or balance: " + repr(s))
    # Only compare numbers within the same display unit or across known units.
    return Decimal(m[1]), m[2].lower()


def cost_key(value):
    n, unit = value
    if unit not in ("", "k", "m", "b", "t", "qad"):
        raise Pause("Unknown currency unit: " + unit)
    # Qad's exact exponent is unnecessary: it sorts after the smaller known units.
    if unit == "qad":
        return 1, n
    return 0, n * (1000 ** ("", "k", "m", "b", "t").index(unit))


def affordable(price, balance):
    if price[1] == balance[1]:
        return price[0] <= balance[0]
    return cost_key(price) <= cost_key(balance)


class Screen:
    def __init__(self, image):
        self.rgb = np.asarray(image.convert("RGB"))
        self.h, self.w = self.rgb.shape[:2]
        r, g, b = (self.rgb[:, :, i].astype("int16") for i in range(3))
        self.white = (r > 213) & (g > 213) & (b > 213) & (np.maximum(r, np.maximum(g,b))-np.minimum(r,np.minimum(g,b)) < 27)
        self.blue = (b-r > 55) & (g-r > 17) & (b > 108)
        self.cyan = (g > 141) & (b > 153) & (g-r > 62)
        self.green = (g > 145) & (g-r > 53) & (g-b > 44)
        self.lime = (g > 190) & (r > 110) & (r-b > 60) & (g-r > 22)
        self.buy_fill = (abs(r-34)<14) & (abs(g-112)<16) & (abs(b-68)<15)
        self.red = (r > 142) & (r-g > 90) & (r-b > 85)

    def cave(self):
        w = self.w
        left = self.blue[:, int(w*.02):int(w*.16)]
        rows = bands(np.where(left.mean(axis=1) > .26)[0], max(2, self.h//70))
        cards = [(a,b) for a,b in rows if .08*self.h < b-a < .26*self.h]
        if len(cards) != 1:
            raise Pause("Open Upgrades and select one cave. Its blue card must be visible.")
        a,b = cards[0]
        name = ocr(self.white[a:int(a+(b-a)*.36), :int(w*.177)])
        if not re.fullmatch(r"[A-Za-z][A-Za-z0-9 '\-]{1,40}", name):
            raise Pause("Cannot read the selected cave name.")
        return name

    def balance(self):
        h,w = self.h,self.w
        return money(ocr(self.lime[int(.89*h):, int(.44*w):int(.68*w)], CASH))

    def detail(self):
        h,w = self.h,self.w
        x1,x2 = int(w*.75), int(w*.98)
        strip = self.cyan[:, x1:x2]
        rows = [(a,b) for a,b in bands(np.where(strip.mean(axis=1)>.075)[0], 3)
                if h*.022 < b-a < h*.07]
        if len(rows)!=1:
            raise Pause("Select a skill with a readable progress bar.")
        a,b = rows[0]
        name = ocr(self.white[max(0,int(a-.125*h)):int(a-.017*h),x1:x2])
        raw = ocr(self.white[a:b,x1:x2], "0123456789/")
        rank = re.fullmatch(r"(\d+)/(\d+)",raw)
        name = re.sub(r"(?<= )[Il|]+$", lambda m: "I"*len(m[0]), name)
        if not name or not rank or not 0 <= int(rank[1]) <= int(rank[2]) or int(rank[2]) == 0:
            raise Pause("Cannot read the skill name and level: " + repr((name,raw)))
        lvl, cap = map(int,rank.groups())
        if lvl==cap:
            return name,lvl,cap,None,None
        filled = self.buy_fill[b:, x1:x2]
        buttons = [(b+y,b+z) for y,z in bands(np.where(filled.mean(axis=1)>.46)[0],3)
                   if h*.035 < z-y < h*.15]
        if len(buttons)!=1:
            return name,lvl,cap,None,None
        y,z = buttons[0]
        # Requirements label is immediately above the buy button, below the effect description.
        req = ocr(self.green[max(b,int(y-.088*h)):y,x1:x2])
        if req.casefold() != "requirements complete":
            return name,lvl,cap,None,None
        price = money(ocr(self.white[y:z,x1:x2],CASH))
        return name,lvl,cap,price,((x1+x2)//2,(y+z)//2)

    def nodes(self):
        h,w = self.h,self.w
        xa,xb=int(.19*w),int(.72*w)
        mask=self.green[:int(.92*h),xa:xb]
        res=[]
        for a,b in bands(np.where(mask.sum(axis=1)>6)[0], 2):
            if not h*.004 < b-a < h*.034:
                continue
            for j,k in bands(np.where(mask[a:b].any(axis=0))[0],max(3,w//220)):
                if not w*.012 < k-j < w*.09:
                    continue
                x=xa+(j+k)//2
                y=(a+b)//2
                # Only consider price text on a skill tile, not icon pixels.
                tile_red = self.red[max(0,a-4):min(h,b+4),max(0,xa+j-5):xa+k+5]
                if tile_red.mean() < .16 and not ocr(mask[a:b,j:k],CASH).startswith("$"):
                    continue
                # Tiny tile prices can be misread. Compare prices from the large detail panel.
                if (k-j) > 1.8*(b-a):
                    res.append((x,y))
        return res

    def selected(self, point):
        # The selected tile has a continuous bright cyan left AND right outline.
        x,y=point
        width=int(.095*self.w)
        left=max(0,x-width)
        roi=self.cyan[max(0,y-int(.035*self.h)):y+1,left:min(self.w,x+width)]
        cols=np.where(roi.mean(axis=0)>.86)[0]+left
        return any(.019*self.w<x-v<.05*self.w for v in cols) and any(.019*self.w<v-x<.05*self.w for v in cols)


CASH="$0123456789.ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"


def test_image(path):
    s=Screen(Image.open(path))
    print("Cave:",s.cave(),"Balance:",s.balance(),"Detail:",s.detail())
    print("Visible prices:",[(xy,s.selected(xy)) for xy in s.nodes()])



class Window:
    def __init__(self):
        from ctypes import wintypes as wt
        self.wt = wt
        self.ui = ctypes.windll.user32
        self.ui.GetForegroundWindow.restype = wt.HWND
        self.ui.WindowFromPoint.argtypes = [wt.POINT]
        self.ui.WindowFromPoint.restype = wt.HWND
        self.ui.GetAncestor.argtypes = [wt.HWND, wt.UINT]
        self.ui.GetAncestor.restype = wt.HWND
        self.ui.GetWindowThreadProcessId.argtypes = [wt.HWND, ctypes.POINTER(wt.DWORD)]
        self.ui.ClientToScreen.argtypes = [wt.HWND, ctypes.POINTER(wt.POINT)]
        self.ui.GetClientRect.argtypes = [wt.HWND, ctypes.POINTER(wt.RECT)]
        try:
            self.ui.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4))
        except AttributeError:
            self.ui.SetProcessDPIAware()
        self.hwnd = self.ui.GetForegroundWindow()
        pid = wt.DWORD()
        self.ui.GetWindowThreadProcessId(self.hwnd, ctypes.byref(pid))
        kernel = ctypes.windll.kernel32
        kernel.OpenProcess.restype = wt.HANDLE
        handle = kernel.OpenProcess(0x1000, False, pid.value)
        size = wt.DWORD(1024)
        buf = ctypes.create_unicode_buffer(size.value)
        try:
            if not handle or not kernel.QueryFullProcessImageNameW(wt.HANDLE(handle), 0, buf, ctypes.byref(size)):
                raise Pause("Cannot identify the foreground window.")
        finally:
            if handle:
                kernel.CloseHandle(wt.HANDLE(handle))
        if Path(buf.value).name.lower() not in {"robloxplayerbeta.exe", "windows10universal.exe"}:
            raise Pause("Bring the Roblox game window to the front during the countdown.")
        self.bounds = self.rectangle()

    def rectangle(self):
        rect,pt = self.wt.RECT(),self.wt.POINT()
        if not self.ui.GetClientRect(self.hwnd,ctypes.byref(rect)) or not self.ui.ClientToScreen(self.hwnd,ctypes.byref(pt)):
            raise Pause("Cannot locate the Roblox client area.")
        return pt.x,pt.y,pt.x+rect.right,pt.y+rect.bottom

    def guard(self):
        if self.ui.GetAsyncKeyState(0x1B) or self.ui.GetForegroundWindow()!=self.hwnd or self.rectangle()!=self.bounds:
            raise Pause("Stopped: Escape pressed, focus changed, or window moved.")

    def screen(self):
        self.guard()
        return Screen(ImageGrab.grab(bbox=self.bounds, all_screens=True))

    def pointer(self, xy):
        self.guard()
        x,y = self.bounds[0]+xy[0],self.bounds[1]+xy[1]
        if not self.bounds[0]<=x<self.bounds[2] or not self.bounds[1]<=y<self.bounds[3]:
            raise Pause("Target is outside the game window.")
        if self.ui.GetAncestor(self.ui.WindowFromPoint(self.wt.POINT(x,y)),2)!=self.hwnd:
            raise Pause("Another window covers the target.")
        self.ui.SetCursorPos(x,y)

    def click(self,xy):
        self.pointer(xy)
        self.ui.mouse_event(2,0,0,0,0)
        self.ui.mouse_event(4,0,0,0,0)

    def scroll(self, xy, direction):
        self.pointer(xy)
        self.ui.mouse_event(0x800,0,0,120*direction,0)


def scene(window,cave):
    s=window.screen()
    if s.cave()!=cave:
        raise Pause("Cave changed. Start again for the new cave.")
    return s


def buy(window,cave,expected):
    screen=scene(window,cave)
    name,level,cap,price,xy=screen.detail()
    if (name,level,cap,price)!=expected or xy is None or not affordable(price,screen.balance()):
        raise Pause("Selection, eligibility, price, or balance changed.")
    # Reject scene changes during OCR. Compare actual text and the selected outline.
    fresh=window.screen()
    def marks(s):
        return (s.white[:,int(.74*s.w):],s.green[:,int(.74*s.w):],
                s.cyan[:,int(.19*s.w):int(.72*s.w)],s.blue[:,:int(.17*s.w)],
                s.lime[int(.89*s.h):,int(.44*s.w):int(.68*s.w)])
    if any(np.mean(a!=b)>.0005 for a,b in zip(marks(screen),marks(fresh))):
        raise Pause("The menu changed before the purchase. No click sent.")
    window.click(xy)
    print(f"Clicked once: {cave} / {name} ({level}/{cap}). Waiting for level change.",flush=True)
    deadline=time.monotonic()+7
    while time.monotonic()<deadline:
        time.sleep(.35)
        now=scene(window,cave).detail()
        if now[0]!=name or now[2]!=cap:
            raise Pause("Selection changed after click. Verify in game.")
        if now[1]==level+1:
            print(f"Confirmed on screen: {level}/{cap} -> {now[1]}/{cap}",flush=True)
            return
        if now[1]!=level:
            break
    raise Pause("No confirmed level increase. Purchase was not retried.")


def page_id(s):
    # Compare the shapes of tree tiles, independent of the selected cyan outline.
    roi=np.s_[int(.04*s.h):int(.91*s.h):8,int(.19*s.w):int(.72*s.w):8]
    return (s.red | s.green)[roi].copy()


def same_page(a,b):
    return a.shape==b.shape and np.mean(a!=b)<.003


def move_page(window,cave,s,direction):
    before=page_id(s)
    window.scroll((int(s.w*.58),int(s.h*.68)),direction)
    time.sleep(.45)
    after=scene(window,cave)
    return after,not same_page(before,page_id(after))


def top(window,cave):
    s=scene(window,cave)
    for _ in range(36):
        s,moved=move_page(window,cave,s,1)
        if not moved:
            return s
    raise Pause("Could not locate the top of the tree.")


def pick(window,cave,s,xy):
    fresh = scene(window,cave)
    if not same_page(page_id(s),page_id(fresh)) or xy not in fresh.nodes():
        raise Pause("Candidate moved. Selection cancelled.")
    window.click(xy)
    time.sleep(.35)
    s=scene(window,cave)
    if not s.selected(xy):
        raise Pause("Could not verify the selected skill outline.")
    return s,s.detail()


def cheapest(window,cave):
    s=top(window,cave)
    balance=s.balance()
    candidates=[]
    visited=[]
    for page in range(36):
        key=page_id(s)
        if any(same_page(key,old) for old in visited):
            raise Pause("Tree scrolling loop detected.")
        visited.append(key)
        for xy in s.nodes():
            s,d=pick(window,cave,s,xy)
            if d[3] is not None and affordable(d[3],balance):
                candidates.append((d[:4],page,xy,key))
        s,moved=move_page(window,cave,s,-1)
        if not moved:
            break
    else:
        raise Pause("Could not establish the end of the list of visible skills.")
    if not candidates:
        raise Pause("No affordable eligible skill found in the scanned area.")
    units={item[0][3][1] for item in candidates}
    chosen=min(candidates,key=lambda item: item[0][3][0] if len(units)==1 else cost_key(item[0][3]))
    expected,page,xy,key=chosen
    s=top(window,cave)
    for _ in range(page):
        s,moved=move_page(window,cave,s,-1)
        if not moved:
            raise Pause("Cannot return to the selected page.")
    if not same_page(key,page_id(s)):
        raise Pause("Tree layout changed since the scan.")
    s,d=pick(window,cave,s,xy)
    if d[:4]!=expected:
        raise Pause("Skill or price changed since the scan.")
    return expected


def run(mode):
    if os.name!="nt":
        raise Pause("Interactive mode requires Windows.")
    print("Open Upgrades and select your cave and skill. Focus Roblox within 5 seconds. Esc stops.",flush=True)
    time.sleep(5)
    window=Window()
    first=window.screen()
    cave=first.cave()
    initial=first.detail()[0] if mode=="selected" else None
    print("Cave:",cave,"Mode:",mode,flush=True)
    while True:
        if mode=="selected":
            s=scene(window,cave)
            d=s.detail()
            if d[0]!=initial:
                raise Pause("Selected skill changed.")
            if d[1]==d[2]:
                print("Max:",initial)
                return
            if d[3] is None or not affordable(d[3],s.balance()):
                raise Pause("Requirements or funds are insufficient.")
            expected=d[:4]
        else:
            expected=cheapest(window,cave)
        buy(window,cave,expected)


if __name__=="__main__":
    try:
        if sys.argv[1:2]==["--inspect"]:
            test_image(sys.argv[2])
        elif sys.argv[1:2] in (["selected"],["cheapest"]):
            run(sys.argv[1])
        else:
            print("Choose selected or cheapest, or --inspect PATH")
            sys.exit(2)
    except (Pause,OSError,subprocess.SubprocessError) as exc:
        print("Stopped:",exc,flush=True)
        sys.exit(1)
