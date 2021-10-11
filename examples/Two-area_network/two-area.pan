ground electrical gnd

parameters RL=0.1m XL=1m/10 BC=1.75m 
parameters L25=25 L10=10 L110=110
parameters TYPE=4 D=2 F0=60 

options outintnodes=yes

#ifdef PAN

parameter TSTOP=1000*60
parameter FRAND=10

Load control begin

  load( "mat5", "noise_samples.mat" );

  Dc dc nettype=1 print=1
  Tr tran stop=TSTOP nettype=1 annotate=3 method=1 timepoints=1/FRAND \
          forcetps=1 maxiter=65 mem=["time","S[123]:omega*"]

  [f, psS1Hp]  = mtpsd( F0*get("Tr.S1:omegahp"), null, null, FRAND );

  save("raw", "psS1Hp", "freq", f, "psS1Hp", psS1Hp );

  function [f,C,R]=StLoad(Params,PortNum,V,I,StNum,X,dX,Time)

    if( PortNum != 3 )
	printf( "Wrong number of ports.\n" );
        abort();
    end

    P = Params(1)*V(3);
    Q = 0;

    SqrMag = V(1)*V(1) + V(2)*V(2);
    if( SqrMag < 200k*200k )
        SqrMag = 200k*200k;
    end

    f(1) = I(1) - (V(1)*P + V(2)*Q) / SqrMag;
    f(2) = I(2) - (V(2)*P - V(1)*Q) / SqrMag;
    f(3) = I(3);

    R(1,1) =  1.0;
    R(1,2) =  0.0;
    R(2,1) =  0.0;
    R(2,2) =  1.0;
    R(3,3) =  1.0;

    C(1,1) = -( P/SqrMag - (V(1)*P + V(2)*Q)*2*V(1)/(SqrMag*SqrMag));
    C(1,2) = -( Q/SqrMag - (V(1)*P + V(2)*Q)*2*V(2)/(SqrMag*SqrMag));
    C(1,3) = -(Params(1)*V(1)/SqrMag);
    C(2,1) = -(-Q/SqrMag - (V(2)*P - V(1)*Q)*2*V(1)/(SqrMag*SqrMag));
    C(2,2) = -( P/SqrMag - (V(2)*P - V(1)*Q)*2*V(2)/(SqrMag*SqrMag));
    C(2,3) = -(Params(1)*V(2)/SqrMag);
    C(3,1) = 0;
    C(3,2) = 0;
    C(3,3) = 0;
  end

  function [Pars,Keys]=StLoadSetup()
    Pars(1) = 1.0e6; // Default value of the "P" parameter
    Keys(1) = "P";   // The "P" parameter
  end

endcontrol

#endif

begin power

//
// Synchronous maxchines, avr and tg
//
Av1      g1   ex1 poweravr vmax=5 vmin=-5 ka=20 ta=0.055 te=0.36 kf=0.125 \
                       tf=1.8 tr=0.05 vrating=20k type=2 ae=0.0056 be=1.075

Tg1     pm1 omega1     powertg type=1 omegaref=1 r=0.002 pmax=1 pmin=0.0 \
			ts=0.1 tc=0.45 t3=0 t4=12 t5=50 gen="G1"

S1      pm1   sf1 omega1 x1 y1 powershaft mhp=6.5 mip=6.5 mlp=6.5 gen="G1"

G1       g1   ex1  sf1 omega1 x1 y1 powergenerator slack=yes vg=1 type=TYPE \
                    omegab=F0*2*pi \
		    vrating=20k prating=1G pg=0.7 \
		    xd=1.8 xq=1.7 xl=0.2 xdp=0.3 xqp=0.55 xds=0.25 xqs=0.25 \
		    ra=2.5m td0p=8 tq0p=0.4 td0s=0.03 tq0s=0.05 \
		    d=D m=2*6.5

Av2      g2   ex2 poweravr vmax=5 vmin=-5 ka=20 ta=0.055 te=0.36 kf=0.125 \
                       tf=1.8 tr=0.05 vrating=20k type=2 ae=0.0056 be=1.075

Tg2     pm2 omega2     powertg type=1 omegaref=1 r=0.02 pmax=1 pmin=0.0 \
			ts=0.1 tc=0.45 t3=0 t4=12 t5=50

S2      pm2   sf2 omega2 x2 y2 powershaft mhp=6.5 mip=6.5 mlp=6.5 gen="G2"

G2       g2   ex2 sf2 omega2 x2 y2 powergenerator vg=1 type=TYPE omegab=F0*2*pi \
		    vrating=20k prating=1G pg=0.7 \
		    xd=1.8 xq=1.7 xl=0.2 xdp=0.3 xqp=0.55 xds=0.25 xqs=0.25 \
		    ra=2.5m td0p=8 tq0p=0.4 td0s=0.03 tq0s=0.05 \
		    d=D m=2*6.5

Av3      g3   ex3 poweravr vmax=5 vmin=-5 ka=20 ta=0.055 te=0.36 kf=0.125 \
                       tf=1.8 tr=0.05 vrating=20k type=2 ae=0.0056 be=1.075

Tg3     pm3 omega3 powertg type=1 omegaref=1 r=0.02 pmax=1 pmin=0.0 \
			ts=0.1 tc=0.45 t3=0 t4=12 t5=50 

S3      pm3   sf3 omega3 x3 y3 powershaft mhp=6.5 mip=6.5 mlp=6.5 gen="G3"

G3       g3   ex3 sf3 omega3 x3 y3 powergenerator vg=1 type=TYPE omegab=F0*2*pi \
		    vrating=20k prating=1G pg=0.719/1  \
		    xd=1.8 xq=1.7 xl=0.2 xdp=0.3 xqp=0.55 xds=0.25 xqs=0.25 \
		    ra=2.5m td0p=8 tq0p=0.4 td0s=0.03 tq0s=0.05 \
		    d=D m=2*6.175

Av4      g4   ex4 poweravr vmax=5 vmin=-5 ka=20 ta=0.055 te=0.36 kf=0.125 \
                       tf=1.8 tr=0.05 vrating=20k type=2 ae=0.0056 be=1.075

Tg4 pm4 omega4     powertg type=1 omegaref=1 r=0.002 pmax=1 pmin=0.0 \
			ts=0.1 tc=0.45 t3=0 t4=12 t5=50 

S4      pm4   sf4 omega4 x4 y4 powershaft mhp=6.5 mip=6.5 mlp=6.5 gen="G4"

G4       g4   ex4 sf4 omega4 x4 y4 powergenerator vg=1 type=TYPE omegab=F0*2*pi \
		    vrating=20k prating=1G pg=0.7 \
		    xd=1.8 xq=1.7 xl=0.2 xdp=0.3 xqp=0.55 xds=0.25 xqs=0.25 \
		    ra=2.5m td0p=8 tq0p=0.4 td0s=0.03 tq0s=0.05 \
		    d=D m=2*6.175 slack=yes

//
// Transformers connecting machine to busses
//
T15      g1  bus5 powertransformer kt=230/20 x=0.15/11 vrating=20k prating=900M
T26      g2  bus6 powertransformer kt=230/20 x=0.15/11 vrating=20k prating=900M
T311     g3 bus11 powertransformer kt=230/20 x=0.15/11 vrating=20k prating=900M
T410     g4 bus10 powertransformer kt=230/20 x=0.15/11 vrating=20k prating=900M

//
// Lines 
//
L56    bus5  bus6 powerline prating=100M r=L25*RL x=L25*XL b=L25*BC vrating=230k
L67    bus6  bus7 powerline prating=100M r=L10*RL x=L10*XL b=L10*BC vrating=230k

// 
// Lines connecting the two areas
//
L78    bus7  bus8 powerline prating=100M r=L110*RL x=L110*XL b=L110*BC vrating=230k 
L89    bus8  bus9 powerline prating=100M r=L110*RL x=L110*XL b=L110*BC vrating=230k
L910   bus9 bus10 powerline prating=100M r=L10*RL x=L10*XL b=L10*BC vrating=230k
L1011 bus10 bus11 powerline prating=100M r=L25*RL x=L25*XL b=L25*BC vrating=230k

//
// Loads
//
Lo7    bus7       powerload pc=0.967 qc=0.1+1*-0.2  vrating=230k prating=1G
Lo9    bus9       powerload pc=1.767/1.3 qc=0.1+1*-0.35 vrating=230k prating=1G

//
// Couplers
//
Pc7    bus7       d7  gnd  q7  gnd  powerec type=0
Pc9    bus9       d9  gnd  q9  gnd  powerec type=0

end

Sl7    d7   gnd  q7  gnd  rnd7  gnd  STLOAD   
Sl9    d9   gnd  q9  gnd  rnd9  gnd  STLOAD   

V7   rnd7   gnd  vsource wave="noise_samples_bus_7"
V9   rnd9   gnd  vsource wave="noise_samples_bus_9"

model STLOAD nport macro=yes setup="stoch_load_setup" evaluate="stoch_load_eval"

