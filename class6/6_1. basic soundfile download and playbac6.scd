
/* STEP 1:  Download sound files for audio playback from a folder named "audio"
The folder needs to be in the same folder as this file.
*/
s.waitForBoot({																	// guarantee the server is running
	~files = "audio/*".resolveRelative.pathMatch;			// find files in the folder "audio", which
	~buffers = ~files.collect{ | f | Buffer.read(s, f) };			// load those sounds into  buffers on the server
																							// the server, of course,  needs to be running
});

// Create an empty array to hold your buffers
~buffers = Array.new; //if for some reason the array isn't there

// Add buffers to the array directly
~buffers = ~buffers.add(Buffer.read(s, "/Users/danielfishkin/gitprojects/MUSIC-CODE-INTERACTIVITY/class6/daxos/daxKICK_4.wav"));
~buffers = ~buffers.add(Buffer.read(s, "/Users/danielfishkin/gitprojects/MUSIC-CODE-INTERACTIVITY/class6/daxos/daxSHIVEr.wav"));
//just keep adding files into the array, they each have different buf numbers

//this code though, should work, if you wanted to make any folder called whatever, as long as the file path matches.
// like below i used the folder, "daxos"

s.waitForBoot({																	// guarantee the server is running
	~files = "daxos/*".resolveRelative.pathMatch;			// find files in the folder "audio", which
	~buffers = ~files.collect{ | f | Buffer.read(s, f) };			// load those sounds into  buffers on the server
																							// the server, of course,  needs to be running
});



/* STEP 2: Play a sound file
the sound files are in an array named ~buffers.
you select which sound to play as
~buffers[index]
as in ~buffers[0] or ~buffers[1], etc
*/
~np = NodeProxy.audio(s,2).play;
~np.play;

~numChannels = 2;				// number of channels in the sound file
~soundFileIndex = 0;				// which sound file in the array ~buffers. use different numbers to select files for sampling

~np[1] = {  PlayBuf.ar(~numChannels, bufnum: ~buffers[~soundFileIndex], rate: 1.0, loop: 0) };   	// play once
~np[1] = {  PlayBuf.ar(~numChannels, bufnum: ~buffers[~soundFileIndex], rate: 1.0, loop: 1) };   	// loop


~numChannels = 2;
~soundFileIndex = 0;
~np[1] = {  PlayBuf.ar(~numChannels, bufnum: ~buffers[~soundFileIndex], rate: 1.0, loop: 0) };   	// play once
~np[1] = {  PlayBuf.ar(~numChannels, bufnum: ~buffers[~soundFileIndex], rate: 1.0, loop: 1) };   	// loop




// For simplicity, the remaining examples use numbers rather than
// the environment variables~numChannels and ~soundFileIndex

// STEP 3: mess with the rate of playback
(
~np[1] =  { 						// normal rate playback
	var audio, rate;
	rate = MouseX.kr(0.25, 5, 1); // use 1 as the third argument for exponential ranging.
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)
(
~np[1] =  { 					// quarter speed - two octaves lower and  4x longer
	var audio, rate;
	rate = 1/2;
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

(
~np[1] =  { 					// four rates
	var audio, rate;
	rate = 2/[1,6,12, 2]; //the power of multichannel expansion!
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

~np[1] = 0; //this is always your off switch not command period!


(
~np[1] =  { 					// MANY integer related rates
	var audio, rate;
	rate = 1.25*(1..10).asArray; //the power of multichannel expansion!!!!!!!!
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

(1..10).asArray; //proper ways to use arrays outside of brackets
w = (1, 2..10);  // different proper ways to use arrays outside of brackets


(
~np[1] =  { 					// four rates
	var audio, rate, m1, m2, m3, m4;
	m1 = MouseX.kr(0.25, 5, 0);
	m2 = MouseX.kr(0.15, 4, 0);
	m3 = MouseX.kr(8, 0.1, 0);
	m4 = MouseX.kr(0.1, 3, 0);
	rate = 2/[m1,m2,m3,m4];
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

(
// STEP 4: add ring modulation
~np[1] =  { 						// now with ring modulation
	var audio, rate;
	rate = 1/3;
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * SinOsc.ar(3);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)
(
~np[1] =  { 					// quarter speed - two octaves lower and  4x longer
	var audio, rate;
	rate = 1/4;
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * SinOsc.ar(400);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)
(
~np[1] =  { 					// four rates
	var audio, rate;
	rate = 2/[3,6,12, 1];
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * SinOsc.ar(MouseX.kr(20, 300, 0));		// ring modulation
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

// STEP 5: make it crunchy by changing SinOsc to Pulse
(
~np[1] =  { 					// quarter speed - two octaves lower and  4x longer
	var audio, rate;
	rate = 1/4;
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * Pulse.ar(300);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)
(
// STEP 6: make it more polite with a low pass filter
~np[1] =  { 					// quarter speed - two octaves lower and  4x longer
	var audio, rate, cutoff, rq;
	rate = 1/4;
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * Pulse.ar(300);
	cutoff = 2000;
	rq = 0.1;
	audio = RLPF.ar(audio,cutoff, rq);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)
(
~np[1] =  { 					// four rates
	var audio, rate, cutoff, rq;
	rate = 2/[3,6,12, 1];
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * Pulse.ar(400);
	cutoff = LFNoise1.kr(1).range(250, 2000);		// one random cutoff
	rq = 0.1;
	audio = RLPF.ar(audio,cutoff, rq);
	Pan2.ar(audio, LFTri.kr(rate) );
};
)

(
~np[1] =  { 					// four rates
	var audio, rate, cutoff, rq;
	rate = 2/[3,6,12, 1];
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * Pulse.ar(400);
	cutoff = LFNoise1.kr([0.2, 0.4, 0.8, 1.6]).range(250, 2000);
	rq = 0.01;														// VERY resonant at cutoff
	audio = RLPF.ar(audio, cutoff, 0.005);		// four random cutoffs
	audio = Limiter.ar(audio, 0.1);
	Pan2.ar(audio,  LFTri.kr(rate) );
};
)

(
~np[1] =  { 					// undertone rates
	var audio, rate, cutoff, rq;
	rate = 2/(2, 3..8);
	audio = PlayBuf.ar(1, bufnum: ~buffers[1], rate: rate, loop: 1);
	audio = audio * Pulse.ar(400);
	cutoff = LFNoise1.kr([0.2, 0.4, 0.8, 1.6]).range(250, 2000);
	rq = 0.01;														// VERY resonant at cutoff
	audio = RLPF.ar(audio, cutoff, 0.005);		//  random cutoffs
	audio = Limiter.ar(audio, 0.1);
	audio = audio * SinOsc.ar(250);
	Pan2.ar(audio,  LFTri.kr(rate) );
};
)






