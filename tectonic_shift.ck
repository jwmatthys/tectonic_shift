//spork ~ record();
//spork ~ timer();

float x[16];
float y[16];

OscRecv oscIn;
12001 => oscIn.port;
oscIn.listen();
int numBlobs;
int numPlaying;

GVerb plateVerb => dac;
4::second => plateVerb.revtime;
100 => plateVerb.roomsize;

800 => float tempo;
spork ~ oscListen();
spork ~ blobListen();
spork ~ plate(0,tempo,0.4);
spork ~ plate(1,tempo*3/2,0.3);
spork ~ plate(2,tempo*2/3,0.2);
spork ~ plate(3,tempo*4/3,0.2);
spork ~ combs();
spork ~ percussion(tempo/6);

while (true) second => now;

fun void percussion(float tpo)
{
	Audiofiles ritual;
	ritual.init();
	FluidSynth f => Echo e => Gain g => Spectacle spect => Envelope env1 => Envelope env2 => NRev rev => dac;
	(tpo*18)::ms => e.max => e.delay;
	(tpo*36)::ms => spect.delayMin;
	(tpo*72)::ms => spect.delayMax;
	1 => spect.mix;
	12 => spect.bands;
	spect.table("delay","random");

	ADSR spectMix => blackhole;
	spectMix.set(8::minute,4::minute,0,0::ms);
	
	0.8 => g.gain;
	g => e;
	me.dir()+"HS_African_Percussion.sf2" => string sf2path;
	f.open(sf2path);
	1 => f.gain;
	0.05 => rev.mix;
	int toggleVel;
	1 => spectMix.keyOn;
	
	while (1)
	{
		(tpo * Math.random2f(0,0.25)) => float human;
		//<<< "numBlobs:",numBlobs, env1.value()>>>;
		if (numBlobs<3)
		{
			if (env1.value()>0)
			{
				2::minute => env1.duration => env2.duration;
				0 => env1.target => env2.target;
			}
		}
		else
		{
			(3::minute / numBlobs) => env1.duration => env2.duration;
			numBlobs/16.0 => env1.target => env2.target;
			
			repeat(6)
			{
				spectMix.value() => spect.mix;
				if (spectMix.state()==2) 1 => spectMix.keyOn;
				human::ms => now;
				if (Math.random2(5,20)<numBlobs)
				{
					(y[Math.random2(0,numBlobs-1)]*60 + 30)$int => int note;
					Math.random2(80,100)+(toggleVel*27) => int vel;
					!toggleVel => toggleVel;
					f.noteOn(note,vel);
				}
			(tpo-human)::ms => now;
			}
			if (numPlaying < 3 && Math.random2(10,100)<numBlobs)
			{
				spork ~ ritual.play();
			}
		}
		if (Math.random2(0,10)<3) (tpo*12)::ms=>now;
	}
}

fun void combs()
{
	Noise n => ADSR env => Multicomb m => Echo e => Gain g => Elliptic ell => Pan2 pan => plateVerb;
   //g => plateVerb;
	// modulate multicomb range
	Phasor ph => blackhole;
	2000 => ph.gain;
	0.000833 => ph.freq; // every 20 minutes
	env.set(4::second,5::second,0,0::ms);
	env => env;
	0.5 => env.gain;
	g => e;
	20::second => e.max => e.delay;
	0.7 => g.gain;
	3 => m.num;
	0.01 => m.gain;
	2::second => m.revtime;
	20 => ell.ripple;
	60 => ell.atten;
	ell.lpf(1500,1900);
	0 => pan.gain;
	20::second => now;
	0.7 => pan.gain;
	
	while (true)
	{
		if (numBlobs<3)
		{
			200 => m.minfreq;
			ph.last()+200 => m.maxfreq;
			Math.random2f(-1,1) => pan.pan;
			1 => env.keyOn;
		}
		Math.random2(50,80)::second => now;
	}
}

fun void plate(int num, float speed, float gain)
{
	3 => int oldMeshX;
	3 => int oldMeshY;
	Mesh2D mesh => Pan2 pan => plateVerb;
	ExpDelay del => pan;
	6 => del.gain;
	3::second => del.max => del.delay;
	1.75 => del.durcurve;
	20 => del.reps;
	gain => mesh.gain;
	0.9999 => mesh.decay;
	0.2 => pan.gain;
	second => now;
	while (1)
	{
		((x[num]*9)+3)$int => int meshX;
		((y[num]*9)+3)$int => int meshY;
		if (meshX != oldMeshX || meshY != oldMeshY)
		{
			meshX => mesh.x;
			meshY => mesh.y;
			x[num] => mesh.xpos;
			y[num] => mesh.ypos;
			(x[num] * 2) - 1 => pan.pan;
			Math.random2f(0, speed * 0.03) => float humanize;
			(speed - humanize)::ms => now;
			1 => mesh.noteOn;
			if (Math.randomf()<0.1) mesh => del;
			humanize::ms => now;
			meshX => oldMeshX;
			meshY => oldMeshY;
		}
	Math.random2f(speed*0.95,speed*1.05)::ms => now;
	mesh =< del;
	}
}

fun void oscListen()
{
	
	oscIn.event( "/clover, i f f") @=> OscEvent msg;
	
	while (true)
	{
		msg => now;
		while (msg.nextMsg())
		{
			msg.getInt() => int n;
			msg.getFloat() => x[n];
			msg.getFloat() => y[n];
			//<<< n,x[n],y[n]>>>;
		}
	}
}

fun void blobListen()
{
	oscIn.event( "/blobs, i") @=> OscEvent blobs;
	
	while (true)
	{
		blobs => now;
		while (blobs.nextMsg())
		{
			blobs.getInt() => numBlobs;
		}
	}
}

fun void timer()
{
	int t;
	while (1)
	{
		minute => now;
		<<< ++t,"minutes elapsed">>>;
	}
}

class Audiofiles
{
	18 => int numFiles;
	SndBuf ritual[numFiles];
	Envelope ritualEnv[numFiles];
	Envelope ritualEnv2[numFiles];
	Pan2 ritualPan[numFiles];
	int ritualPlaying[numFiles];

	fun void init()
	{
		for (int i; i<numFiles; i++)
		{
			ritual[i] => ritualEnv[i] => ritualEnv2[i] => ritualPan[i] => dac;
			0.1 => ritualPan[i].gain;
			"ritual" + Std.itoa(i+1) + ".wav" => ritual[i].read;
			0 => ritual[i].rate;
			10::second => ritualEnv[i].duration => ritualEnv2[i].duration;
		}
	}
	
	fun void play()
	{
		int w; // which SndBuf
		do {
			Math.random2(0,numFiles-1) => w;
		} while (ritualPlaying[w]);
		<<< "playing ritual",w+1>>>;
		numPlaying++;
		true => ritualPlaying[w];
		ritual[w].length() => dur filelen;
		Math.random2f(30,60)::second => dur playlen;
		if (playlen > filelen) filelen => playlen;
		filelen / samp => float fnsamps;
		playlen / samp => float playsamps;
		Math.random2f(0,fnsamps-playsamps)$int => ritual[w].pos;
		Math.random2f(-1,1) => ritualPan[w].pan;
		1 => ritual[w].rate;
		1 => ritualEnv[w].target;
		1 => ritualEnv2[w].target;
		(playlen - 10::second) => now;
		0 => ritualEnv[w].target;
		0 => ritualEnv2[w].target;
		15::second => now;
		numPlaying--;
		false => ritualPlaying[w];
	}
}

fun void record()
{
	dac => WvOut2 rec => blackhole;
	"tectonic-test" => rec.wavFilename;
	10::minute => now;
	<<< "finished test recording" >>>;
}

