z = NodeProxy.new.play;
z.fadeTime = 1;

//the original patch
(
z[0] = {
  var p,t,f,n,d,a,l,x,y,z,x_,y_;
  p = TRand.ar(0.0,1.0,Impulse.ar(6.0));
  t = Impulse.ar(9*(1+(p>0.95)));
  f = TRand.ar([40.0,120.0,220.0],[440.0,990.0,880.0],t);
  n = TRand.ar(4.0,[8.0, 16.0, 32.0],t);
  d = TRand.ar([0.2,0.4,0.6],[0.6, 0.8, 1.0],t);
  a = TRand.ar(0.0,[0.2, 0.6, 1.0],t);
  l = TRand.ar(-1.0,1.0,t);
  x = MouseX.kr(0.25,2.0);
  y = MouseY.kr(0.25,1.5);
  z = 9.0;
  x_ = x * LFNoise2.kr(z).range(0.25,2.0);
  y_ = y * LFNoise2.kr(z).range(0.25,2.0);
  Out.ar(0, Pan2.ar(Mix.ar(VOSIM.ar(t, f*x_, n, d*y_) * a),l,1));
};
)

(
z[0] = {
 | lofreq = 0.95|
  var p,t,f,n,d,a,l,x,y,z,x_,y_, node;
  p = TRand.ar(0.0,1.0,Impulse.ar(6.0));
  node = lofreq * 0.01;
  t = Impulse.ar(9*(1+(p>node)));
  f = TRand.ar([40.0,120.0,220.0],[440.0,990.0,880.0],t);
  n = TRand.ar(4.0,[8.0, 16.0, 32.0],t);
  d = TRand.ar([0.2,0.4,0.6],[0.6, 0.8, 1.0],t);
  a = TRand.ar(0.0,[0.2, 0.6, 1.0],t);
  l = TRand.ar(-1.0,1.0,t);
  x = MouseX.kr(0.25,2.0);
  y = MouseY.kr(0.25,1.5);
  z = 9.0;
  x_ = x * LFNoise2.kr(z).range(0.25,2.0);
  y_ = y * LFNoise2.kr(z).range(0.25,2.0);
  Out.ar(0, Pan2.ar(Mix.ar(VOSIM.ar(t, f*x_, n, d*y_) * a),l,1));
};
)

Spec.add(\beats1, [0.01, 200, \exp]);

z.gui

(
z[0..1] = {
  var p,t,f,n,d,a,l,x,y,z,x_,y_;
  p = TRand.ar(0.0,1.0,Impulse.ar(6.0));
  t = Impulse.ar(9*(1+(p>0.95)));
  f = TRand.ar([40.0,120.0,220.0],[440.0,990.0,880.0],t);
  n = TRand.ar(4.0,[8.0, 16.0, 32.0],t);
  d = TRand.ar([0.2,0.4,0.6],[0.6, 0.8, 1.0],t);
  a = TRand.ar(0.0,[0.2, 0.6, 1.0],t);
  l = TRand.ar(-1.0,1.0,t);
  x = MouseX.kr(0.25,10.0);
  y = MouseY.kr(0.25,10.5);
  z = 9.0;
  x_ = x * LFClipNoise.kr(z).range(0.25,1.0);
  y_ = y * LFClipNoise.kr(z).range(0.25,1.0);
  Out.ar(0, Pan2.ar(Mix.ar(VOSIM.ar(t, f*x_, n, d*y_) * a),l,1));
};
)

