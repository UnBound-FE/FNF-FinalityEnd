package psych.options;

import finality.ui.MainMenuState;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import psych.backend.StageData;
import finality.shaders.VignetteShader;

class OptionsState extends MusicBeatState
{
  var options:Array<String> = ['Note Colors', 'Controls', 'Graphics', 'Visuals and UI', 'Gameplay'];
  private var grpOptions:FlxTypedGroup<Alphabet>;

  private static var curSelected:Int = 0;
  public static var menuBG:FlxSprite;
  public static var onPlayState:Bool = false;
  private static var vcrEffect:VcrGlitchEffect;

  function openSelectedSubstate(label:String)
  {
    switch (label)
    {
      case 'Note Colors':
        openSubState(new psych.options.NotesSubState());
      case 'Controls':
        openSubState(new psych.options.ControlsSubState());
      case 'Graphics':
        openSubState(new psych.options.GraphicsSettingsSubState());
      case 'Visuals and UI':
        openSubState(new psych.options.VisualsUISubState());
      case 'Gameplay':
        openSubState(new psych.options.GameplaySettingsSubState());
    }
  }

  var selectorLeft:Alphabet;
  var selectorRight:Alphabet;

  override function create()
  {
    #if DISCORD_ALLOWED
    DiscordClient.instance.changePresence({details: "Options Menu"});
    #end

    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgnew'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    var body:FlxSprite = new FlxSprite(50);
    body.y = 210;
    body.frames = Paths.getSparrowAtlas('body');
    body.animation.addByPrefix('body', 'body', 24, true);
    body.animation.play('body');
    body.antialiasing = ClientPrefs.data.antialiasing;
    body.updateHitbox();
    body.scrollFactor.set();
    add(body);

    var par2:FlxSprite = new FlxSprite();
    par2.frames = Paths.getSparrowAtlas('par2');
    par2.animation.addByPrefix('par2', 'par2', 1, false);
    par2.animation.play('par2');
    par2.antialiasing = ClientPrefs.data.antialiasing;
    par2.updateHitbox();
    par2.scrollFactor.set();
    add(par2);

    grpOptions = new FlxTypedGroup<Alphabet>();
    add(grpOptions);

    for (i in 0...options.length)
    {
      var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
      optionText.screenCenter();
      optionText.y += (100 * (i - (options.length / 2))) + 50;
      grpOptions.add(optionText);
    }

    selectorLeft = new Alphabet(0, 0, '>', true);
    add(selectorLeft);
    selectorRight = new Alphabet(0, 0, '<', true);
    add(selectorRight);

    if (ClientPrefs.data.shaders)
    {
      vcrEffect = new VcrGlitchEffect();
      var s = new VignetteShader();
      initPsychCamera().setFilters([new ShaderFilter(s), new ShaderFilter(vcrEffect.shader)]);
    }

    changeSelection();
    ClientPrefs.saveSettings();

    super.create();
  }

  override function closeSubState()
  {
    super.closeSubState();
    ClientPrefs.saveSettings();
    #if DISCORD_ALLOWED
    DiscordClient.instance.changePresence({details: "Options Menu"});
    #end
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (ClientPrefs.data.shaders) vcrEffect.update(elapsed);

    if (controls.UI_UP_P)
    {
      changeSelection(-1);
    }
    if (controls.UI_DOWN_P)
    {
      changeSelection(1);
    }

    if (controls.BACK)
    {
      FlxG.sound.play(Paths.sound('cancelMenu'));
      if (onPlayState)
      {
        StageData.loadDirectory(PlayState.SONG);
        LoadingState.loadAndSwitchState(new PlayState());
        FlxG.sound.music.volume = 0;
      }
      else
        MusicBeatState.switchState(new MainMenuState());
      FlxG.camera.fade();
      FlxTween.tween(FlxG.camera, {zoom: 0.15}, 3, {ease: FlxEase.quadInOut});
      MusicBeatState.switchState(new MainMenuState());
    }
    else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
  }

  function changeSelection(change:Int = 0)
  {
    curSelected += change;
    if (curSelected < 0) curSelected = options.length - 1;
    if (curSelected >= options.length) curSelected = 0;

    var bullShit:Int = 0;

    for (item in grpOptions.members)
    {
      item.targetY = bullShit - curSelected;
      bullShit++;

      item.alpha = 0.6;
      if (item.targetY == 0)
      {
        item.alpha = 1;
        selectorLeft.x = item.x - 63;
        selectorLeft.y = item.y;
        selectorRight.x = item.x + item.width + 15;
        selectorRight.y = item.y;
      }
    }
    FlxG.sound.play(Paths.sound('scrollMenu'));
  }

  override function destroy()
  {
    ClientPrefs.loadPrefs();

    if (ClientPrefs.data.shaders) initPsychCamera().setFilters([]); // idk, if game will crash/lagging

    super.destroy();
  }
}