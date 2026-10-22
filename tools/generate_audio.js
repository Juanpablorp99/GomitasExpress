// Genera la música y los efectos de sonido del juego (estilo chiptune) en assets/audio/.
// Uso (necesita Node.js):   node tools/generate_audio.js
// Si después quieren usar sonidos propios, reemplacen los .wav con el MISMO nombre
// y el juego los usa sin tocar el código (ver scripts/game/audio_manager.gd).

const fs = require("fs");
const path = require("path");

const RATE = 22050;
const OUT = path.join(__dirname, "..", "assets", "audio");

// --- Utilidades ----------------------------------------------------------------

const NOTE = { C: 0, "C#": 1, D: 2, "D#": 3, E: 4, F: 5, "F#": 6, G: 7, "G#": 8, A: 9, "A#": 10, B: 11 };

/** "A4" -> 440 Hz. null o "-" = silencio. */
function freq(name) {
	if (!name || name === "-") return 0;
	const m = /^([A-G]#?)(\d)$/.exec(name);
	const midi = NOTE[m[1]] + (parseInt(m[2]) + 1) * 12;
	return 440 * Math.pow(2, (midi - 69) / 12);
}

function buffer(seconds) {
	return new Float32Array(Math.ceil(seconds * RATE));
}

const WAVES = {
	square: (p) => (p % 1 < 0.5 ? 1 : -1),
	pulse: (p) => (p % 1 < 0.25 ? 1 : -1),
	triangle: (p) => 1 - 4 * Math.abs((p % 1) - 0.5),
	saw: (p) => 2 * (p % 1) - 1,
	sine: (p) => Math.sin(2 * Math.PI * p),
};

/**
 * Suma una nota al buffer. opts: wave, vol, attack, release, slide (Hz al final),
 * vibrato (Hz de profundidad).
 */
function tone(buf, start, dur, f0, opts = {}) {
	const wave = WAVES[opts.wave || "square"];
	const vol = opts.vol ?? 0.3;
	const attack = opts.attack ?? 0.005;
	const release = opts.release ?? Math.min(0.08, dur * 0.5);
	const f1 = opts.slide ?? f0;
	const vib = opts.vibrato ?? 0;
	const i0 = Math.floor(start * RATE);
	const n = Math.floor(dur * RATE);
	let phase = 0;
	for (let i = 0; i < n && i0 + i < buf.length; i++) {
		const t = i / RATE;
		const k = i / n;
		const f = f0 + (f1 - f0) * k + (vib ? vib * Math.sin(2 * Math.PI * 5.5 * t) : 0);
		phase += f / RATE;
		let env = 1;
		if (t < attack) env = t / attack;
		else if (t > dur - release) env = Math.max(0, (dur - t) / release);
		buf[i0 + i] += wave(phase) * vol * env;
	}
}

/** Ruido blanco (golpes, viento, cinta). `decay` = qué tan rápido se apaga. */
function noise(buf, start, dur, opts = {}) {
	const vol = opts.vol ?? 0.3;
	const decay = opts.decay ?? 8;
	const smooth = opts.smooth ?? 0; // 0 = ruido duro, cerca de 1 = más grave/suave
	const i0 = Math.floor(start * RATE);
	const n = Math.floor(dur * RATE);
	let last = 0;
	for (let i = 0; i < n && i0 + i < buf.length; i++) {
		const t = i / RATE;
		const raw = Math.random() * 2 - 1;
		last = last * smooth + raw * (1 - smooth);
		const env = opts.envelope ? opts.envelope(t / dur) : Math.exp(-decay * t);
		buf[i0 + i] += last * vol * env;
	}
}

function kick(buf, t, vol = 0.5) {
	tone(buf, t, 0.12, 150, { wave: "sine", slide: 40, vol, release: 0.06 });
}
function snare(buf, t, vol = 0.22) {
	noise(buf, t, 0.12, { vol, decay: 30 });
}
function hat(buf, t, vol = 0.07) {
	noise(buf, t, 0.03, { vol, decay: 120 });
}

function writeWav(file, buf) {
	// normaliza para que no sature
	let peak = 0;
	for (const v of buf) peak = Math.max(peak, Math.abs(v));
	const gain = peak > 0.9 ? 0.9 / peak : 1;
	const data = Buffer.alloc(buf.length * 2);
	for (let i = 0; i < buf.length; i++) {
		const s = Math.max(-1, Math.min(1, buf[i] * gain));
		data.writeInt16LE(Math.round(s * 32767), i * 2);
	}
	const header = Buffer.alloc(44);
	header.write("RIFF", 0);
	header.writeUInt32LE(36 + data.length, 4);
	header.write("WAVE", 8);
	header.write("fmt ", 12);
	header.writeUInt32LE(16, 16);
	header.writeUInt16LE(1, 20); // PCM
	header.writeUInt16LE(1, 22); // mono
	header.writeUInt32LE(RATE, 24);
	header.writeUInt32LE(RATE * 2, 28);
	header.writeUInt16LE(2, 32);
	header.writeUInt16LE(16, 34);
	header.write("data", 36);
	header.writeUInt32LE(data.length, 40);
	fs.mkdirSync(path.dirname(file), { recursive: true });
	fs.writeFileSync(file, Buffer.concat([header, data]));
	console.log("  " + path.relative(OUT, file));
}

// --- Música ------------------------------------------------------------------
// Cada canción: tempo, acordes (uno por compás de 4 tiempos), melodía (una nota por
// corchea, "-" = silencio, "." = sigue la nota anterior) y estilo de batería.

/** Parte una cadena "C5 . E5 - G5" en notas con su duración en corcheas. */
function parseMelody(text) {
	const tokens = text.trim().split(/\s+/);
	const notes = [];
	for (const tok of tokens) {
		if (tok === "." && notes.length) notes[notes.length - 1].len++;
		else notes.push({ note: tok, len: 1 });
	}
	return notes;
}

const CHORDS = {
	C: ["C", "E", "G"], Dm: ["D", "F", "A"], Em: ["E", "G", "B"], F: ["F", "A", "C"],
	G: ["G", "B", "D"], Am: ["A", "C", "E"], Bb: ["A#", "D", "F"], E: ["E", "G#", "B"],
	D: ["D", "F#", "A"], Bm: ["B", "D", "F#"], Gm: ["G", "A#", "D"], A: ["A", "C#", "E"],
};

function song(spec) {
	const beat = 60 / spec.bpm;
	const eighth = beat / 2;
	const bars = spec.chords.length;
	const buf = buffer(bars * 4 * beat);

	spec.chords.forEach((chord, bar) => {
		const t0 = bar * 4 * beat;
		const [root, third, fifth] = CHORDS[chord];
		// bajo
		const bassPattern = spec.bass || [0, 0, 2, 0];
		for (let b = 0; b < 4; b++) {
			const n = [root, root, fifth, root][bassPattern[b]] || root;
			const octave = spec.bassOctave ?? 2;
			tone(buf, t0 + b * beat, beat * 0.9, freq(n + octave) * (bassPattern[b] === 1 ? 2 : 1),
				{ wave: "triangle", vol: 0.32, release: 0.05 });
		}
		// acompañamiento: arpegio en corcheas
		const arp = [root, third, fifth, third];
		for (let e = 0; e < 8; e++) {
			const n = arp[e % 4] + (spec.arpOctave ?? 4);
			tone(buf, t0 + e * eighth, eighth * 0.8, freq(n),
				{ wave: spec.arpWave || "pulse", vol: spec.arpVol ?? 0.07, release: 0.04 });
		}
		// batería
		for (let b = 0; b < 4; b++) {
			const t = t0 + b * beat;
			if (spec.drums === "full") {
				if (b === 0 || b === 2) kick(buf, t);
				if (b === 1 || b === 3) snare(buf, t);
				hat(buf, t + eighth);
				hat(buf, t);
			} else if (spec.drums === "soft") {
				if (b === 0) kick(buf, t, 0.35);
				if (b === 2) snare(buf, t, 0.1);
				hat(buf, t + eighth, 0.04);
			} else if (spec.drums === "bells") {
				// cascabeles de trineo
				noise(buf, t, 0.08, { vol: 0.05, decay: 40 });
				noise(buf, t + eighth, 0.08, { vol: 0.035, decay: 40 });
				if (b === 0) kick(buf, t, 0.3);
			}
		}
	});

	// melodía
	let t = 0;
	for (const { note, len } of parseMelody(spec.melody)) {
		const f = freq(note);
		if (f) tone(buf, t, len * eighth * 0.92, f,
			{ wave: spec.leadWave || "square", vol: spec.leadVol ?? 0.16, vibrato: len > 2 ? 3 : 0, release: 0.06 });
		t += len * eighth;
	}
	return buf;
}

const MUSIC = {
	// Menú: alegre y saltarín (Do mayor)
	menu: {
		bpm: 120, drums: "soft", leadWave: "square",
		chords: ["C", "Am", "F", "G", "C", "Am", "F", "G"],
		melody: `
			E5 . G5 . C6 . G5 .   A5 . E5 . C5 . E5 .   F5 . A5 . C6 . A5 .   G5 . . . D5 . . .
			E5 . G5 . C6 . D6 .   E6 . D6 . C6 . A5 .   F5 . G5 . A5 . B5 .   C6 . . . - . - .`,
	},
	// Nivel 1 — Bodega Fini: movido, de trabajo (Sol mayor)
	level_1: {
		bpm: 132, drums: "full",
		chords: ["G", "G", "C", "D", "G", "Em", "C", "D"],
		melody: `
			G5 - G5 B5 D6 - B5 -   G5 - A5 B5 A5 - G5 -   E5 - E5 G5 C6 - G5 -   F#5 . . . A5 . . .
			G5 - G5 B5 D6 - E6 -   D6 - B5 G5 E5 . . .    C5 E5 G5 C6 E6 - C6 -   D6 . . . - . - .`,
	},
	// Nivel 2 — Turno de noche: misterioso, más lento (La menor)
	level_2: {
		bpm: 104, drums: "soft", leadWave: "triangle", leadVol: 0.24, arpWave: "saw", arpVol: 0.045,
		bass: [0, 2, 0, 2],
		chords: ["Am", "Am", "F", "E", "Am", "Dm", "F", "E"],
		melody: `
			A4 . . . C5 . E5 .   D5 . C5 . B4 . . .   A4 . . . F5 . E5 .   G#4 . . . . . - .
			A4 . C5 . E5 . A5 .  G5 . F5 . D5 . . .   C5 . D5 . E5 . F5 .  E5 . . . . . - .`,
	},
	// Nivel 3 — Almacén en la nieve: campanitas de invierno (Fa mayor)
	level_3: {
		bpm: 116, drums: "bells", leadWave: "sine", leadVol: 0.3, arpWave: "triangle", arpVol: 0.09, arpOctave: 5,
		chords: ["F", "Dm", "Bb", "C", "F", "Dm", "Gm", "C"],
		melody: `
			A5 . A5 . A5 . . .   F5 . G5 . A5 . . .    D6 . C6 . A#5 . A5 .   G5 . . . . . - .
			A5 . C6 . F6 . E6 .  D6 . C6 . A5 . . .    A#5 . A5 . G5 . A#5 .  C6 . . . . . - .`,
	},
};

// --- Efectos de sonido ---------------------------------------------------------

const SFX = {
	// botón de menú
	click: () => {
		const b = buffer(0.08);
		tone(b, 0, 0.06, 900, { wave: "square", vol: 0.25, slide: 1200 });
		return b;
	},
	// al abrir el juego / menú
	menu_start: () => {
		const b = buffer(1.0);
		["C5", "E5", "G5", "C6"].forEach((n, i) => tone(b, i * 0.09, 0.2, freq(n), { vol: 0.25 }));
		tone(b, 0.36, 0.6, freq("E6"), { wave: "triangle", vol: 0.35, vibrato: 4, release: 0.4 });
		return b;
	},
	// llega un pedido nuevo a la caja: "ding-dong"
	new_order: () => {
		const b = buffer(0.7);
		tone(b, 0, 0.35, freq("E6"), { wave: "sine", vol: 0.45, release: 0.3 });
		tone(b, 0.18, 0.5, freq("C6"), { wave: "sine", vol: 0.45, release: 0.45 });
		return b;
	},
	// pedido URGENTE: alarma de dos tonos
	urgent_order: () => {
		const b = buffer(0.75);
		for (let i = 0; i < 3; i++) {
			tone(b, i * 0.24, 0.11, freq("A5"), { wave: "square", vol: 0.25 });
			tone(b, i * 0.24 + 0.12, 0.11, freq("E6"), { wave: "square", vol: 0.25 });
		}
		return b;
	},
	// agarrar gomitas de la estantería: "pop"
	pick: () => {
		const b = buffer(0.12);
		tone(b, 0, 0.1, 400, { wave: "sine", slide: 1100, vol: 0.5, release: 0.04 });
		return b;
	},
	// reponer la estantería con una caja
	restock: () => {
		const b = buffer(0.3);
		noise(b, 0, 0.08, { vol: 0.3, decay: 40, smooth: 0.6 });
		tone(b, 0.08, 0.18, freq("G5"), { wave: "triangle", vol: 0.3, slide: freq("C6") });
		return b;
	},
	// armar el pedido en la mesa: cinta de embalar
	pack: () => {
		const b = buffer(0.5);
		noise(b, 0, 0.35, { vol: 0.28, smooth: 0.3, envelope: (k) => Math.sin(Math.PI * k) });
		tone(b, 0.36, 0.1, freq("C6"), { wave: "square", vol: 0.2 });
		return b;
	},
	// despachar el pedido: caja registradora "cha-ching"
	deliver: () => {
		const b = buffer(0.9);
		noise(b, 0, 0.06, { vol: 0.35, decay: 50 });
		["C6", "E6", "G6"].forEach((n, i) => tone(b, 0.05 + i * 0.06, 0.12, freq(n), { wave: "square", vol: 0.18 }));
		tone(b, 0.24, 0.6, freq("C7"), { wave: "sine", vol: 0.35, release: 0.5 });
		tone(b, 0.24, 0.6, freq("G6"), { wave: "sine", vol: 0.2, release: 0.5 });
		return b;
	},
	// combo (entrega rápida seguida)
	combo: () => {
		const b = buffer(0.5);
		["G5", "C6", "E6", "G6", "C7"].forEach((n, i) => tone(b, i * 0.05, 0.12, freq(n), { wave: "pulse", vol: 0.2 }));
		return b;
	},
	// el cliente se cansó de esperar: "wah wah"
	order_failed: () => {
		const b = buffer(1.0);
		tone(b, 0, 0.25, freq("E4"), { wave: "saw", vol: 0.22, slide: freq("D#4") });
		tone(b, 0.28, 0.25, freq("D#4"), { wave: "saw", vol: 0.22, slide: freq("D4") });
		tone(b, 0.56, 0.42, freq("D4"), { wave: "saw", vol: 0.22, slide: freq("C#4"), vibrato: 4 });
		return b;
	},
	// no se puede hacer eso
	error: () => {
		const b = buffer(0.18);
		tone(b, 0, 0.15, 160, { wave: "square", vol: 0.2, slide: 120 });
		return b;
	},
	// choque con el montacargas
	hit: () => {
		const b = buffer(0.45);
		tone(b, 0, 0.25, 220, { wave: "sine", vol: 0.6, slide: 50 });
		noise(b, 0, 0.2, { vol: 0.4, decay: 20, smooth: 0.5 });
		tone(b, 0.12, 0.3, freq("A5"), { wave: "triangle", vol: 0.12, vibrato: 30 });
		return b;
	},
	// comprar un robot: encendido
	robot_buy: () => {
		const b = buffer(0.7);
		tone(b, 0, 0.4, 200, { wave: "square", vol: 0.18, slide: 900 });
		["C6", "G6"].forEach((n, i) => tone(b, 0.42 + i * 0.1, 0.12, freq(n), { wave: "pulse", vol: 0.22 }));
		return b;
	},
	// robot atascado
	robot_broken: () => {
		const b = buffer(0.7);
		for (let i = 0; i < 4; i++) tone(b, i * 0.08, 0.06, 600 - i * 120, { wave: "square", vol: 0.2 });
		tone(b, 0.32, 0.35, 300, { wave: "saw", vol: 0.2, slide: 60 });
		return b;
	},
	// robot reparado
	robot_repair: () => {
		const b = buffer(0.5);
		["C5", "E5", "G5", "C6"].forEach((n, i) => tone(b, i * 0.07, 0.1, freq(n), { wave: "pulse", vol: 0.22 }));
		return b;
	},
	// pedido al proveedor / llegó el camión: bocina
	truck: () => {
		const b = buffer(0.8);
		tone(b, 0, 0.25, freq("A3"), { wave: "saw", vol: 0.25 });
		tone(b, 0, 0.25, freq("C#4"), { wave: "saw", vol: 0.2 });
		tone(b, 0.35, 0.4, freq("A3"), { wave: "saw", vol: 0.25 });
		tone(b, 0.35, 0.4, freq("C#4"), { wave: "saw", vol: 0.2 });
		return b;
	},
	// evento: hora pico (silbato)
	event_rush: () => {
		const b = buffer(0.9);
		tone(b, 0, 0.3, 2200, { wave: "sine", vol: 0.3, vibrato: 120 });
		tone(b, 0.4, 0.45, 2200, { wave: "sine", vol: 0.3, vibrato: 120 });
		return b;
	},
	// evento: apagón (todo se apaga)
	event_blackout: () => {
		const b = buffer(1.0);
		tone(b, 0, 0.9, 440, { wave: "saw", vol: 0.25, slide: 40, release: 0.3 });
		noise(b, 0, 0.1, { vol: 0.4, decay: 40 });
		return b;
	},
	// evento: derrame (salpicadura)
	event_spill: () => {
		const b = buffer(0.6);
		noise(b, 0, 0.5, { vol: 0.45, decay: 9, smooth: 0.4 });
		for (let i = 0; i < 3; i++) tone(b, 0.1 + i * 0.1, 0.08, 700 + i * 200, { wave: "sine", slide: 300, vol: 0.2 });
		return b;
	},
	// evento: tormenta de nieve (viento)
	event_storm: () => {
		const b = buffer(2.0);
		noise(b, 0, 2.0, { vol: 0.5, smooth: 0.93, envelope: (k) => Math.sin(Math.PI * k) });
		return b;
	},
	// quedan 30 segundos: tic-tac
	time_warning: () => {
		const b = buffer(1.0);
		for (let i = 0; i < 4; i++) tone(b, i * 0.25, 0.05, i % 2 ? 1200 : 1600, { wave: "square", vol: 0.2 });
		return b;
	},
	// nivel ganado
	win: () => {
		const b = buffer(2.0);
		const notes = ["C5", "E5", "G5", "C6", "-", "A5", "C6", "E6"];
		notes.forEach((n, i) => { if (freq(n)) tone(b, i * 0.12, 0.14, freq(n), { vol: 0.22 }); });
		["C6", "E6", "G6"].forEach((n) => tone(b, 1.0, 0.9, freq(n), { wave: "triangle", vol: 0.25, vibrato: 4, release: 0.5 }));
		return b;
	},
	// nivel perdido
	lose: () => {
		const b = buffer(1.8);
		["G4", "F#4", "F4", "E4"].forEach((n, i) => tone(b, i * 0.3, i === 3 ? 0.9 : 0.28, freq(n),
			{ wave: "triangle", vol: 0.35, vibrato: i === 3 ? 5 : 0, release: 0.2 }));
		return b;
	},
};

console.log("Generando audio en " + OUT);
for (const [name, spec] of Object.entries(MUSIC)) writeWav(path.join(OUT, "music", name + ".wav"), song(spec));
for (const [name, make] of Object.entries(SFX)) writeWav(path.join(OUT, "sfx", name + ".wav"), make());
console.log("Listo.");
