package psych.states.editors;

class PopUpSubState extends MusicBeatSubstate
{
  var _text:String;
  var _timer:Float;

  public function new(text:String, timer:Float):Void
  {
    super();

    _text = text;
    _timer = timer;
  }

  override function create():Void
  {
    var bg:FlxSprite = new FlxSprite(-1, -1).makeGraphic(FlxG.width + 2, FlxG.height + 2, FlxColor.BLACK);
    bg.alpha = 0.6;
    bg.scrollFactor.set();
    add(bg);

    var text:FlxText = new FlxText(0, 0, FlxG.width, _text, 20);
    text.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
    text.screenCenter();
    text.updateHitbox();
    text.scrollFactor.set();
    add(text);

    new FlxTimer().start(_timer, (_) -> {
      FlxG.state.persistentUpdate = true;

      FlxTween.tween(bg, {alpha: 0}, 0.4, {ease: FlxEase.quadInOut, onComplete: (_) -> close()});
      FlxTween.tween(text, {alpha: 0}, 0.4, {ease: FlxEase.quadInOut});
    });

    super.create();
  }

  override function update(e:Float):Void
  {
    super.update(e);
  }
}
