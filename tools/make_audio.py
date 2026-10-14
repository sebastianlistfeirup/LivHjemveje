"""Original deterministic score and Foley. No samples or external music."""
from pathlib import Path
import numpy as np
import wave, subprocess
ROOT=Path(__file__).resolve().parents[1]/'assets/audio'
SR=22050
rng=np.random.default_rng(1024)
def write(name,arr):
 arr=np.asarray(arr); arr=np.clip(arr,-.95,.95)
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
  f.setnchannels(1 if arr.ndim==1 else arr.shape[1]);f.setsampwidth(2);f.setframerate(SR);f.writeframes((arr*32767).astype('<i2').tobytes())
def note(freq,dur=2,kind='bell'):
 t=np.arange(int(SR*dur))/SR
 if kind=='flute':
  env=np.minimum(t/.18,1)*np.minimum((dur-t)/.5,1)*.45
  return (np.sin(2*np.pi*freq*t+.02*np.sin(2*np.pi*4*t))+.08*np.sin(2*np.pi*freq*2*t))*env
 env=np.minimum(t/.009,1)*np.exp(-t*2.2)
 return (np.sin(2*np.pi*freq*t)+.25*np.sin(2*np.pi*freq*2*t)*np.exp(-t*2)+.09*np.sin(2*np.pi*freq*3*t))*env
for name,base in [('woodland',0),('evening',-5)]:
 dur=48; a=np.zeros((SR*dur,2))
 chords=[[48,55,60,64],[45,52,57,60],[41,48,53,57],[43,50,55,62]]
 for bar in range(16):
  chord=chords[(bar//2)%4]
  for j in range(4):
   midi=chord[j]+base+(12 if j%2 else 0)
   sound=note(440*2**((midi-69)/12),2.4)*.10
   start=int((bar*3+j*.65)*SR)
   length=min(len(sound),len(a)-start)
   pan=.3+.4*((j+bar)%3)/2
   a[start:start+length,0]+=sound[:length]*(1-pan)
   a[start:start+length,1]+=sound[:length]*pan
  if bar%2==1:
   midi=[76,74,72,67,69,72,74,67][bar//2]+base
   sound=note(440*2**((midi-69)/12),2.0,'flute')*.035
   start=int((bar*3+.3)*SR)
   a[start:start+len(sound),:]+=sound[:,None]
 # Very quiet filtered wind, and a delay that wraps for a continuous loop.
 noise=rng.normal(0,.003,len(a)); wind=np.convolve(noise,np.ones(70)/70,'same')
 a[:,0]+=wind;a[:,1]+=np.roll(wind,155)
 a+=np.roll(a,int(SR*.37),axis=0)*.17
 a+=np.roll(a,int(SR*.73),axis=0)*.10
 # Smooth last/first half second without a click.
 fade=int(SR*.4)
 a[:fade]*=np.linspace(.15,1,fade)[:,None];a[-fade:]*=np.linspace(1,.15,fade)[:,None]
 write(name,a)
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(ROOT/(name+'.wav')),'-c:a','libvorbis','-q:a','4',str(ROOT/(name+'.ogg'))],check=True)
 (ROOT/(name+'.wav')).unlink()
write('touch',note(440,.20)*.09)
write('place',note(330,.35)*.11+note(660,.35)*.025)
chime=np.zeros(int(SR*1.5))
for i,f in enumerate([523.25,659.25,783.99,1046.50]):
 n=note(f,.85)*.10;s=int(SR*i*.16);chime[s:s+len(n)]+=n
write('success',chime)
t=np.arange(int(SR*.5))/SR
write('water',np.convolve(rng.normal(0,.1,len(t)),np.ones(8)/8,'same')*np.sin(np.pi*t/.5)**2)
print('Two original 48-second soundscapes and four sound effects.')
