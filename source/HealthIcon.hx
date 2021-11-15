package;

import flixel.FlxSprite;
import flixel.FlxG;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';
	public var defaultWidth:Float = 1;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
		if (FlxG.save.data.antialiasing)
		{
			antialiasing = false;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
		if (FlxG.save.data.antialiasing)
		{
			antialiasing = false;
		}
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
		if (FlxG.save.data.antialiasing)
		{
			antialiasing = false;
		}
	}

	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; 
			var file:Dynamic = Paths.image(name);

			loadGraphic(file, true, 150, 150);
			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = true;
			if (FlxG.save.data.antialiasing)
			{
				antialiasing = false;
			}
			if(char.endsWith('-pixel')) {
				antialiasing = false;
			}
		}
	}

	public function getCharacter():String {
		return char;
	}
}