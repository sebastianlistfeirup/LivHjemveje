"""Original light pizzicato and dramatic woodland cues; no borrowed recordings."""
import numpy as np
import wave, subprocess
from pathlib import Path
SR=24000
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
rng=np.random.default_rng(714)
def voice(midi,duration,kind):
 t=np.arange(int(duration*SR))/SR; f=440*2**((midi-69)/12)
 if kind=='pluck':
  envelope=(1-np.exp(-t*220))*np.exp(-t*3.6)
  wave=sum(np.sin(2*np.pi*f*k*t+.006*np.sin(t*13))*np.exp(-t*k*.27)/k**1.6 for k in range(1,7))
 elif kind=='pad':
  envelope=np.minimum(t/.35,1)*np.minimum((duration-t)/.7,1)
  wave=(np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*1.002*t)+.16*np.sin(2*np.pi*f*2*t))*.45
 elif kind=='flute':
  envelope=np.minimum(t/.09,1)*np.minimum((duration-t)/.2,1)
  wave=np.sin(2*np.pi*f*t+.014*np.sin(2*np.pi*5*t))+.1*np.sin(2*np.pi*f*2*t)
 else:
  envelope=(1-np.exp(-t*160))*np.exp(-t*9)
  wave=np.sin(2*np.pi*(f*t+8*(1-np.exp(-t*18))))
 return wave*envelope
for name,bpm in [('playful',92),('danger',108)]:
 beat=60/bpm; length=32*4*beat; n=int(length*SR); a=np.zeros((n,2))
 def put(midi,start,dur,gain,kind,pan=.5):
  snd=voice(midi,dur,kind)*gain; idx=(np.arange(len(snd))+int(start*SR))%n
  a[idx,0]+=snd*np.sqrt(1-pan);a[idx,1]+=snd*np.sqrt(pan)
 chords=[[48,55,60,64],[45,52,57,60],[53,57,60,65],[55,59,62,67]] if name=='playful' else [[45,52,57,60],[41,48,53,57],[43,50,55,59],[40,47,52,56]]
 melody=[76,79,81,79,76,74,72,74,76,74,72,67,69,72,74,71] if name=='playful' else [69,72,71,67,69,76,72,71,65,69,67,64,67,71,68,64]
 for bar in range(32):
  chord=chords[(bar//2)%4]
  for note in chord:put(note,bar*4*beat,4.6*beat,.035,'pad',.3+(.1*(note%4)))
  for j in range(8):
   note=chord[[0,2,1,3,2,1,3,1][j]]+(12 if name=='playful' else 0)
   put(note,(bar*4+j*.5)*beat,1.5*beat,.13 if name=='playful' else .09,'pluck',.25+.5*(j%3)/2)
  for j in [0,2]:put(chord[0]-12,(bar*4+j)*beat,1.8*beat,.12,'pluck',.5)
  if bar%2==0:
   for j in range(4):put(melody[(bar//2*2+j)%len(melody)],(bar*4+j*.85+.25)*beat,.78*beat,.075,'flute',.4)
  if name=='danger':
   for j in [0,1.5,2,3]:put(35,(bar*4+j)*beat,.45,.1,'drum',.5)
 # Loop-safe stereo chamber reflections.
 a+=np.roll(a,int(.19*SR),axis=0)*.18
 a+=np.roll(a,int(.37*SR),axis=0)*.12
 a+=np.roll(a,int(.63*SR),axis=0)*.08
 a*=.55/max(.55,np.max(np.abs(a)))
 path=OUT/(name+'.wav')
 with wave.open(str(path),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((np.clip(a,-.98,.98)*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(path),'-c:a','libvorbis','-q:a','4',str(OUT/(name+'.ogg'))],check=True)
 path.unlink();print(name,round(length,1),'seconds')
