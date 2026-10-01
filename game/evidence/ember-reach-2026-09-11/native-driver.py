# Native browser input for this test. The Helium CDP bridge sometimes delivers
# mouse moves without acknowledging them; only movement uses a short reply wait.
# Clicks still use normal press/release with a held interval so Unity sees a frame.
from browser_harness import _ipc as native_ipc

def tap(px, py):
    ratio = js('devicePixelRatio')
    x, y = px / ratio, py / ratio
    native_call('Input.dispatchMouseEvent',timeout=20,type='mouseMoved',x=x,y=y,button='none',buttons=0)
    time.sleep(.3)
    cdp('Input.dispatchMouseEvent',type='mousePressed',x=x,y=y,button='left',buttons=1,clickCount=1)
    time.sleep(.6)
    cdp('Input.dispatchMouseEvent',type='mouseReleased',x=x,y=y,button='left',buttons=0,clickCount=1)
    time.sleep(.8)

def keypress(key, code, vk):
    cdp('Input.dispatchKeyEvent',type='keyDown',key=key,code=code,windowsVirtualKeyCode=vk,nativeVirtualKeyCode=vk)
    time.sleep(.15)
    cdp('Input.dispatchKeyEvent',type='keyUp',key=key,code=code,windowsVirtualKeyCode=vk,nativeVirtualKeyCode=vk)
    time.sleep(.25)
import base64

def native_call(method, timeout=20, **params):
    conn, token = native_ipc.connect(NAME, timeout=timeout)
    try:
        result = native_ipc.request(conn,token,{'method':method,'params':params,'session_id':None})
    finally:
        conn.close()
    if 'error' in result:
        raise RuntimeError(result['error'])
    return result.get('result',{})

def snapshot(path):
    result = native_call('Page.captureScreenshot',timeout=30,format='png',captureBeyondViewport=False)
    with open(path,'wb') as file:
        file.write(base64.b64decode(result['data']))
    print(path,flush=True)
