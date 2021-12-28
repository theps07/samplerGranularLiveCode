//A LiveCoding Environment
//by Puru.
(
p.clear;
Buffer.freeAll;
//initializations
s.options.sampleRate = 48000.0;
s.boot;


t = TempoClock.new(80/60).permanent_(true);
p = ProxySpace.new(s, clock:t).push;
p.quant = 1;
~sig.play.fadeTime_(t.tempo*4);

e = ();

e.buf1 = ();
e.buf1.path = PathName(thisProcess.nowExecutingPath).parentPath ++ "Sounds/";
PathName(e.buf1.path).entries.collect({
	arg n,i;
	e.buf1[i] = Buffer.readChannel(s, n.fullPath, channels:[0]);
});

e.buf2 = ();
e.buf2.path = PathName(thisProcess.nowExecutingPath).parentPath ++ "Sounds2/";
PathName(e.buf2.path).entries.collect({
	arg n,i;
	e.buf2[i] = Buffer.readChannel(s, n.fullPath, channels:[0]);
});

//some synthdefs
SynthDef(\bpSample, {//bandpassed sample
	var sig, env;
	env = Env([0,1,1,0],[\atk.kr(0),\sus.kr(0),\rel.kr(0)],[\atkcrv.ir(2),0,\relcrv.ir(-2)]).kr(Done.freeSelf, 1); //envelope
	sig = PlayBuf.ar(1, \buf.ir(0), \rate.kr(1)*BufRateScale.kr(\buf.ir(0)), startPos: \spos.ir(0)); //Sample playback osc
	sig = XFade2.ar(sig, BPF.ar(sig, Line.ar(0, \freq.kr(440), \ramp.kr(2)), \rq.kr(1), 1/ \rq.kr(1).sqrt), \bpfmix.kr(0)*2-1); //two channel cross fader between original and bandpassed sample
	sig = sig * SinOsc.kr(Line.kr(0.1, \tremolo.kr(2), 5), mul:Line.kr(0.1, 1, 2) ) * env; //env + some am
	sig = Pan2.ar(sig, \pan.kr(0), \amp.kr(1));
	Out.ar(\out.ir(0), sig); //output
}).add;

SynthDef(\bpGnlr, {//bandpassed granular
    var env, posCtrl, sig;
    env = Env(
		[0,1,1,0],
		[\atk.kr(0.1),\sus.kr(1),\rel.kr(3)],
		[\atkcrv.kr(2),0,\relcrv.kr(-2)]).kr(Done.freeSelf, 1);
	posCtrl = Phasor.kr(0, \posRate.kr(1), \spos.kr(0), \epos.kr(0), \spos.kr(0));       //LFTri.kr(posRate).range(spos,epos);// //LFNoise1.kr(10).range(spos,epos);
	sig = GrainBuf.ar(
		2,
		Impulse.ar(\gfreq.kr(10)),
		\gdur.kr(1),
		\buf.ir(0),
		\rate.kr(1),
		posCtrl,
		2,
		\pan.kr(0) * LFNoise1.kr(5).range(-1,1),
		\genv.kr(-1),
		512,
		1,
		0);
    sig = BPF.ar(sig, Line.ar(0, \bfreq.kr(440), \ramp.kr(2)), \rq.kr(1), 1/\rq.kr(1).sqrt);
	sig = sig * env;
	sig = RLPF.ar(sig, \filt.kr(15000), 0.2);
	sig = Pan2.ar(sig, 0, \amp.kr(1));
	Out.ar(\out.ir(0), sig);
}).add;
)


~sig.play.fadeTime_(t.tempo*16);
~sig.release
~sig.clear

(//MOVEMENT1
~sig = Pbindef(//metalHits
	\metalHits,
	\instrument, \bpGnlr,
	\atk, 0.001,
	\sus, 1,
	\rel, 2,
	\buf, e.buf2[0],
	\dur, 1, //Pn(Pgeom(1, 0.5, 8) * t.tempo, inf),
	\posRate, 1,
	\spos, Pseq([0.1, 0.2, 0.4, 0.2, 0.5], inf),
	\epos, Pseq([0.6, 0.5, 0.7, 0.4, 0.8], inf),
	\gfreq, Pseq([1,2,3,4,5,6].scramble * t.tempo * 0.5, inf) ,
	\gdur, t.tempo*4,
	\rate, Pxrand((Scale.minorPentatonic.degrees.midiratio*1.376 * (0.5+exprand(0.001, 0.005))).scramble, inf),
	\pan, Pwhite(-1,1,inf),
	\bfreq, 96.midicps,
	\rq, 8,
	\out, 0,
	\amp, 1,
);
)

////////Engage delay, reverb, filter
(//Effects
//reverb
~verb.play.fadeTime_(32);
~verb = {
	var sig;
	sig = GVerb.ar(\in.ar(0), 250, 4);
	sig = LPF.ar(sig, 2000);
	sig = sig * 0.5;
};

//delay
~del.play.fadeTime_(32);
~del = {
	var sig;
	//On stream I meant to set the default value to 0!2 instead of 0
	sig = CombN.ar(\in.ar(0!2), 1, \indeltime.kr(t.tempo/3), t.tempo*2);
	sig = sig * 0.5;
};
)

//send to reverb send
~verb.xmap(\in, ~sig, \fadeTime, 16);
//remove from reverb send
~verb.map(\in, 0!2)

//send to delay
~del.xmap(\in, ~sig, \fadeTime, 16);
//remove from delay send
~del.xmap(\in, 0!2);

//add fiter
~lfo2 = {SinOsc.kr(0.12).exprange(400,5000)}
~sig.xmap(\filt, ~lfo2, \fadeTime, 32);

//start with dur
//add Pn
//play with gdur
//play with gfreq mult factor (0.5, 1, 2)

(//TRANSITION TO MOVEMENT2
~sig = Pbindef(//water wubs
	\waterWubs,
	\instrument, \bpGnlr,
	\atk, 0.001,
	\sus, 0,
	\rel, 4,
	\buf, e.buf2[5],
	\dur, t.tempo,
	\posRate, 1,
	\spos, 0.2,
	\epos, 1,
	\gfreq, Pseq([2, 1, 4], inf),
	\gdur, Pseq([0.25, 0.5, 1, 0.125]*2, inf),
	\rate, 1,
	\pan, Pxrand([-1, 1], inf),
	\bfreq,( [0, 5] + 72).midicps,
	\ramp, t.tempo *0.5,
	\rq, 0.012*2,
	\out, 0,
	\outfx,
	\send,
	\amp, 2,
);
)

//short transition to MOVEMENT 2

(//MOVEMENT 2
~sig = Task({//waterChords
	loop{
		rrand(4,6).do(
Synth(\bpSample,
	[
		\buf, e.buf2[5],
		\atk, exprand(2,3),
		\sus, 1,
		\rel, exprand(4,6),
		\bpfmix, exprand(0.8, 1),
		\freq, (Scale.minorPentatonic.degrees+1.376.ratiomidi+72).choose.midicps,
		\tremolo, exprand(2,10),
		\rq, exprand(0.001, 0.008),
		\rate, exprand(0.1,0.5),
		\pan, rrand(-0.5,0.5),
		\out, 0, //output to reverb bus
		\amp, exprand(1,1.5),
			]);
		);
			t.tempo.wait;
	}
});
)

//let waterChords play
//disengage filter
~sig.xmap(\filt, 20000, \fadetime, 32);

(//Movement 3: Pads
~sig = {
	var scl, sig, trig, env, buf, rel, ttemp, rate;
	scl = Scale.minorPentatonic.degrees + 0; //choose([0, 12 ,24]);
	scl = (scl-12)++scl++(scl+12);
	rel = {exprand(0.2,2)}!12;
	//ttemp = t.tempo * 12
	ttemp = t.tempo * \speed.kr(6);
	trig = Trig.kr(Impulse.kr(ttemp!12), rel);
	rate = TChoose.kr(trig, scl.midiratio*1.376);
	//buf = TChoose.kr(trig, (0..6).collect({arg n; e.buf1[n]}));
	//buf = Select.kr(2, (0..6).collect({arg n; e.buf1[n]}));
	buf = TChoose.kr(trig, [2]); //6 or 2
	sig = PlayBuf.ar(1, buf, rate, trig, \spos.kr(0));
	env = Env.perc(0.001, rel, 1, -2).kr(0, trig);
	sig = sig * env * 0.5;
	sig = Splay.ar(sig);
	sig = RLPF.ar(sig, \filt.kr(15000), 0.2);
	sig = RHPF.ar(sig, 200, 1);
}
)

//start with single buf[2] and speed 1
//Cycle between Speeds 1, 2 and 3
//increase speed to 12
//cycle through bufs
//transition to all wet signal
(
//remove dry, only reverb + delay wet
~sig.stop(fadeTime:32);
~del.xmap(\in, ~verb);
~verb.xmap(\in, ~sig);
)

//modulate delay time
~lfo = {SinOsc.kr(0.1).exprange(0.1,0.5)}
~del.xmap(\indeltime, ~lfo);
~del.xmap(\indeltime, t.tempo/4);


//add single buffer, cycle between buf[2] and buf[6]

/////////engage filter
//lfos
~lfo = {SinOsc.kr(0.1).exprange(0.1, 0.5)};
~lfo2 = {SinOsc.kr(0.12).exprange(400,5000)};

//apply resonant lowpass filter to source signal
~sig.xmap(\filt, ~lfo2, \fadeTime, 32);
~sig.xmap(\filt, 20000, \fadetime, 32);

//bring dry back into the mix
~sig.play(fadeTime:16);

//increase speed

//fade out
(
//unmap and fade out
~verb.xmap(\in, 0);
~del.xmap(\in, 0!2);
~sig.clear(16);
)

///////////////////

//Additional FXP

//effects in series: sig -> del -> reverb
~verb.map(\in, ~del);

//speed controls
~speed = {1};
~speed = {TChoose.kr(t.tempo * 4, Array.geom(8, 1, 2))};
~sig.xmap(\speed, ~speed);

//spos control
~spos = {SinOsc.kr(t.tempo*3).range(0,3000000/2)};
~sig.xmap(\spos, ~spos);

//filter control
~spos = {SinOsc.kr(t.tempo/8).exprange(400, 10000)};
~sig.xmap(\filt, ~spos);

~sig.stop
~sig.release;

p.clear;
p.pop;
