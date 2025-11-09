// Read about FlxGroups here: https://haxeflixel.com/documentation/flxgroup/
import flixel.group.FlxTypedGroup;

// Current note
var curSpawnNote:Note;

// Variables for Girlfriend's notes
var gfNotes:Array<Note> = [];
var gfStrums:Array<StrumNote> = [];
var ghostNotes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();

// Recreation of invalidateNote
function invalidateNote(note:Note)
{
	note.kill();
	ghostNotes.remove(note, true);
	note.destroy();
}

// Recreation of opponentNoteHit (because ShadowMario made the function private for some reason...)
function ghostNoteHit(note:Note):Void
{
	var animToPlay:String = game.singAnimations[note.noteData % game.singAnimations.length];

	if(game.gf != null)
	{
		game.gf.playAnim(animToPlay, true);
		game.gf.holdTimer = 0;
	}

	note.hitByOpponent = true;

	if (!note.isSustainNote)
		invalidateNote(note);
}

function onInit()
{
	// Functions for creating the strumline!

	// Creates a new strumline
	gfStrums = createStrumline("GF Notes");

	// Adds it to the game! Behind Boyfriend!
	addStrumBehind("bf", "GF Notes");

	// Basic position for your strumline
	var strumY:Float;

	if (ClientPrefs.data.downScroll)
		strumY = FlxG.height - 150;
	else
		strumY = 50;

	// Code to position the strumline (and then make it hidden)
	positionStrumline("GF Notes", getStrumlineMidpoint("bf"), strumY);
	setVisible("GF Notes", false);

	// Code to filter out Girlfriend's notes from the rest of notes
	gfNotes = game.unspawnNotes.filter(
		(note:Note) -> {
			if (note.noteType == "GF Notes")
			{
				note.mustPress = false;
				note.rgbShader.r = FlxColor.WHITE;
				note.copyAlpha = false;
				note.alpha = 0.3;
				return true;
			}
			return false;
		}
	);

	for (note in gfNotes)
		game.unspawnNotes.remove(note);

	curSpawnNote = gfNotes.shift();

	// Adds Girlfriend's notes behind everyone else's
	game.noteGroup.insert(0, ghostNotes);
}

function onUpdate(elapsed:Float)
{
	if (curSpawnNote != null)
	{
		var time:Float = game.spawnTime * playbackRate;

		if(game.songSpeed < 1)
			time /= game.songSpeed;

		if(curSpawnNote.multSpeed < 1)
			time /= note.multSpeed;

		if (curSpawnNote.strumTime - Conductor.songPosition < time)
		{
			ghostNotes.insert(0, curSpawnNote);
			curSpawnNote.spawned = true;

			curSpawnNote = gfNotes.shift();
		}
	}
	else
	{
		if (ghostNotes.length < 1)
		{
			remove(ghostNotes);
			this.active = false;
			return;
		}
	}

	ghostNotes.forEachAlive((note:Note) -> {
		if (Conductor.songPosition - note.strumTime > game.noteKillOffset)
		{
			invalidateNote(note);
			return;
		}
	
		var strum:StrumNote = gfStrums[note.noteData];
		note.followStrumNote(strum, Conductor.crochet, game.songSpeed / game.playbackRate);

		if (note.wasGoodHit && !note.ignoreNote)
			ghostNoteHit(note);

		if(note.isSustainNote && strum.sustainReduce)
			note.clipToStrumNote(strum);
	});
}