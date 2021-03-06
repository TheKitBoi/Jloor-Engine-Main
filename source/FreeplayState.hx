package;

import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import Conductor.BPMChangeEvent;
import Song.SwagSong;


#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';
	var bg:FlxSprite;
	var ohYeah = 0;
	var musicOptimizationOn:Bool = false;
	var camFollow:FlxObject;
	var totalText:FlxText;
	//var iconP2:HealthIcon;

	var musicOptimization:Array<String> = [ 
	"Tutorial", "Bopeebo", "Fresh", "Dad-Battle",
	"Spookeez", "South", "Monster",
	"Pico", "Philly-Nice", "Blammed",
	"Satin-Panties", "High", "Milf",
	"Cocoa", "Eggnog", "Winter-Horrorland",
	"Senpai", "Roses", "Thorns",
	"Test"								  
	];
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	public var bgColors:Array<String> = [
		'#a5004d',
		'#cc29fd',
		'#d57e00',
		'#f3ff6e',
		'#b7d855',
		'#d8558e',
		'#ffaa6f',
		'#ff3c6e',
		'#7bd6f6',
		'#ffffff'
	];
	private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		if(!musicOptimizationOn){  #if sys sys.thread.Thread.create(() -> { #end
			loadingMusic(); #if sys }); #end }

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1]));
		}

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		 #if windows
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Freeplay Menu", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		addSong('Test', -99, 'bf-pixel-opponent');

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		totalText = new FlxText(FlxG.width * 0.85, FlxG.height - 28, 0, "", 24);
		totalText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		totalText.scrollFactor.set(0, 0);
		//add(totalText);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		//FlxG.sound.playMusic(Paths.music('title'), 0);
		//FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		//add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		totalText.text = curSelected + 1 + " / " + songs.length + " Songs";
		scoreText.text = "PERSONAL BEST:" + lerpScore;

		//totalText.y = Math.floor(FlxMath.lerp(totalText.y, FlxG.height - 28, 0.14 * (60 / Main.framerate)));

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));

			for (x in 0...grpSongs.length)
				{
					FlxTween.tween(grpSongs.members[x], {x: grpSongs.members[x].x - 400}, 0.5, {ease: FlxEase.backIn});
					FlxTween.tween(grpSongs.members[x], {alpha: 0.0}, 0.5, {ease: FlxEase.quadIn});
				}

			for (x in 0...iconArray.length)
				{
					FlxTween.tween(iconArray[x], {x: iconArray[x].x - 400}, 0.5, {ease: FlxEase.backIn});
					FlxTween.tween(iconArray[x], {alpha: 0.0}, 0.5, {ease: FlxEase.quadIn});
				}

			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);
			
		new FlxTimer().start(0.6, function (tmrr:FlxTimer)
			{
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				PlayState.storyWeek = songs[curSelected].week;
				trace('CUR WEEK' + PlayState.storyWeek);
				LoadingState.loadAndSwitchState(new PlayState());
			});
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "< EASY >";
				diffText.color = FlxColor.LIME;
			case 1:
				diffText.text = '< NORMAL >';
				diffText.color = FlxColor.YELLOW;
			case 2:
				diffText.text = "< HARD >";
				diffText.color = FlxColor.RED;
		}
	}
	
	override function beatHit()
		{
			super.beatHit();
				trace('beat');
				switch(songs[curSelected].songName.toLowerCase()){
				case 'milf': 
					if (curBeat % 2 == 1){
						FlxG.camera.zoom = 1;
						FlxTween.tween(FlxG.camera, {zoom: 1.05}, 0.3, {ease: FlxEase.quadOut, type: BACKWARD});
					}
				default: 
						FlxG.camera.zoom = 1;
						FlxTween.tween(FlxG.camera, {zoom: 1.05}, 0.3, {ease: FlxEase.quadOut, type: BACKWARD});
				}
			}
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		//camFollow.y = curSelected * 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		switch(songs[curSelected].songName.toLowerCase()) 
		{
			case 'tutorial': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[0]));
			case 'bopeebo' | 'fresh' | 'dad-battle' | 'cocoa' | 'eggnog':
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[1]));
			case 'spookeez' | 'south': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[2]));
			case 'monster' | 'winter-horrorland': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[3]));
			case 'pico' | 'philly-nice' | 'blammed': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[4]));
			case 'satin-panties' | 'high' | 'milf': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[5]));
			case 'senpai' | 'roses': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[6]));
			case 'thorns': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[7]));
			case 'test': 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[8]));
			default: 
				FlxTween.color(bg, 0.1, bg.color, FlxColor.fromString(bgColors[9]));
		}
		
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
		PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		Conductor.changeBPM(PlayState.SONG.bpm);
		
		changeDiff();

		var bullShit:Int = 0;

		totalText.y -= 25;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			item.selected = false;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.selected = true;
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function loadingMusic(){
        for(x in musicOptimization){ FlxG.sound.cache(Paths.inst(x)); FlxG.sound.cache(Paths.voices(x));
            ohYeah++;
        }
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}