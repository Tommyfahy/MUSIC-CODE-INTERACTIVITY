// Create a NodeProxy for audio
~simpleSynth = NodeProxy.audio(s);

// Define the synth
~simpleSynth.source = {
    var freq = \freq.kr(440); // Frequency control with default 440 Hz
    var amp = \amp.kr(0.2);   // Amplitude control with default 0.2
    var sound = SinOsc.ar(freq) * amp; // Sine wave oscillator
    sound ! 2; // Stereo output
};

// Play the synth
~simpleSynth.play;

// Adjust the parameters dynamically
~simpleSynth.set(\freq, 880, \amp, 0.1); // Change frequency and amplitude
~simpleSynth.set(\freq, 220);            // Lower the frequency

// Stop the synth
~simpleSynth.stop;