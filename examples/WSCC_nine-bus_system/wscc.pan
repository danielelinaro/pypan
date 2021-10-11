ground electrical gnd

parameters GM=4 D=sqrt(2) FREQ=4.4098e-01 BE=1.555 F0=60
parameters LAMBDA=0.0
parameters M1=47.28 M2=12.80 M3=6.02

options outintnodes=yes topcheck=2 pivrelthresh=0.1p

Al_dummy_lambda alter param="LAMBDA" rt=yes

#ifdef PAN
Dc dc print=yes nettype=1
#endif

begin power

Av1     g1   ex1  poweravr vmax=5 vmin=-5 ka=20 ta=0.2 kf=0.063 tf=0.35 \
                          ke=0.01 te=0.314 tr=0.001 ae=0.0039 be=BE \
			  vrating=16.5k type=2
G1      g1   ex1  powergenerator slack=yes vg=1.04 type=GM d=D \
			 xd=0.1460 xdp=0.0608 \
			 td0p=8.96 \
			 xq=0.0969 xqp=0.0969 \
			 tq0p=0.310 m=M1 \
			 vrating=16.5k prating=100M \
			 omegab=F0*2*pi

Av2     g2   ex2  poweravr vmax=5 vmin=-5 ka=20 ta=0.2 kf=0.063 tf=0.35 \
                          ke=0.01 te=0.314 tr=0.001 ae=0.0039 be=BE \
			  vrating=18.0k type=2
G2      g2   ex2  powergenerator pg=(1+LAMBDA)*1.63 vg=1.025 type=GM d=D \
			 xd=0.8958 xdp=0.1198 \
			 td0p=6.00 \
			 xq=0.8645 xqp=0.1969 \
			 tq0p=0.535 m=M2 \
                         vrating=18.0k prating=100M \
			 omegab=F0*2*pi

Av3     g3   ex3  poweravr vmax=5 vmin=-5 ka=20 ta=0.2 kf=0.063 tf=0.35 \
                          ke=0.01 te=0.314 tr=0.001 ae=0.0039 be=BE \
			  vrating=13.8k type=2
G3      g3   ex3  powergenerator pg=(1+LAMBDA)*0.85 vg=1.025 type=GM d=D \
                         xd=1.3125 xdp=0.1813 \
			 td0p=5.89 \
			 xq=1.2578 xqp=0.2500 \
			 tq0p=0.600 m=M3 \
                         vrating=13.8k prating=100M \
			 omegab=F0*2*pi

T14     g1  bus4  powertransformer kt=230/16.5 x=57.6m vrating=16.5k prating=100M
T27     g2  bus7  powertransformer kt=230/18.0 x=62.5m vrating=18.0k prating=100M
T39     g3  bus9  powertransformer kt=230/13.8 x=58.6m vrating=13.8k prating=100M

Li46  bus6  bus4  powerline r=17.0m x= 92.0m b=158m vrating=230k prating=100M
Li54  bus4  bus5  powerline r=10.0m x= 85.0m b=176m vrating=230k prating=100M print=1

Pwr1  bus7  p gnd  q gnd  pwr7  powerec type=4
Li57  pwr7  bus5  powerline r=32.0m x=161.0m b=306m vrating=230k prating=100M print=1

Li96  bus9  bus6  powerline r=39.0m x=170.0m b=358m vrating=230k prating=100M
Li78  bus7  bus8  powerline r= 8.5m x= 72.0m b=149m vrating=230k prating=100M
Li98  bus9  bus8  powerline r=11.9m x=100.8m b=209m vrating=230k prating=100M

Lo5   bus5        powerload pc=(1+LAMBDA)*1.25 qc=(1+LAMBDA)*0.50 vrating=230k prating=100M
Lo6   bus6        powerload pc=(1+LAMBDA)*0.90 qc=(1+LAMBDA)*0.30 vrating=230k prating=100M
Lo8   bus8        powerload pc=(1+LAMBDA)*1.00 qc=(1+LAMBDA)*0.35 vrating=230k prating=100M

end
