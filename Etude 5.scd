// Initialize NodeProxy
~sound = NodeProxy.audio(s);

// Define the instrument using NodeProxy
~sound.source = {
    var freq, lfoRate, lfo, sig;

    // Mouse X controls pitch (50 - 1000 Hz)
    freq = MouseX.kr(50, 1000, 1);

    // Mouse Y controls LFO rate (0.1 - 10 Hz)
    lfoRate = MouseY.kr(0.1, 10, 1);

    // LFO modulating amplitude
    lfo = SinOsc.kr(lfoRate).range(0.2, 1); // Scaled between 0.2 and 1

    // Generate a sine wave with LFO-modulated amplitude
    sig = SinOsc.ar(freq, 0, lfo) * 0.3;

    sig ! 2; // Stereo output
};

// Activate the NodeProxy
~sound.play;

// Control parameters dynamically
~sound.set(\freq, 440, \lfoRate, 5);

// Stop the sound after 30 seconds
Routine {
    30.wait;
    ~sound.stop;
}.play;
