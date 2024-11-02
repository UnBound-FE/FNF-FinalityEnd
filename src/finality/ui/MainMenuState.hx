package finality.ui;

import openfl.filters.ShaderFilter;
import lime.app.Application;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.effects.FlxFlicker;
import flixel.addons.transition.FlxTransitionableState.defaultTransIn;
import flixel.addons.transition.FlxTransitionableState.defaultTransOut;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import finality.shaders.VignetteShader;

class MainMenuState extends MusicBeatState
{
  /**
   * VERSIONS LOLLOL
   */
  public static final psychEngineVersion:String = '0.7.3';

  public static final GAME_VERSION:String = #if debug 'Finality End: DELUXE (3.0)' #else 'Finality End: DELUXE 3.0' #end;

  /**
   * VURADO DOEBANDO DATA SHIT
   */
  final buttonsPath:String = "mainmenu/items/";

  final all_shit:Array<ItemOptions> = [
    {
      tag: 'worlds',
      menu: new StoryMenuState(),
      x: 10,
      y: 10,
      pitch:
        {
          name: 'worlds',
          scale: 1,
          addX: 50,
          addY: -50,
          prefix:
            {
              name: 'headlooped3',
              anims: [
                {name: 'idle', xml: 'headlooped3', fps: 24}],
              idleAnim: 'idle'
            }
        }
    },
    {
      tag: 'extras',
      menu: new FreeplayState(),
      x: (FlxG.width - 400),
      y: 10,
      pitch:
        {
          name: 'extras',
          scale: 1,
          addX: 0,
          addY: -50,
          prefix:
            {
              name: 'headlooped2',
              anims: [
                {name: 'idle', xml: 'headlopped2', fps: 24}],
              idleAnim: 'idle'
            }
        }
    },
    {
      tag: 'options',
      menu: new psych.options.OptionsState(),
      x: 10,
      y: (FlxG.height - 200),
      pitch:
        {
          name: 'options',
          scale: 1,
          addX: 0,
          addY: -40,
          prefix:
            {
              name: 'headlooped4',
              anims: [
                {name: 'idle', xml: 'headlopped4', fps: 24}],
              idleAnim: 'idle'
            }
        }
    },
    {
      tag: 'credits',
      menu: new CreditsVideo(),
      x: (FlxG.width - 400),
      y: (FlxG.height - 200),
      pitch:
        {
          name: 'credits',
          scale: 1.05,
          addX: 0,
          addY: -80,
          prefix:
            {
              name: 'headlooped',
              anims: [
                {name: 'idle', xml: 'headlopped', fps: 24}],
              idleAnim: 'idle'
            }
        }
    },
  ];
  final cacheShit:Array<String> = ['headlooped3'];

  /**
   * SELECTION SHIT
   */
  static var curSelected:Int = 0; // 0 - story, 1 - freeplay, 2 - options, 3 - credits

  static var curUpDownSel:Int = 0; // 0 - up, 1 - down

  var camGame:FlxCamera;
  var camStuff:FlxCamera;

  /**
   * SHADER SHIT
   */
  var vcrEffect:VcrGlitchEffect;

  /**
   * GROUPS
   */
  var firstClass:FlxSpriteGroup;

  var buttonGrp:FlxSpriteGroup;
  var pitchGrp:FlxSpriteGroup;
  var camGrp:FlxSpriteGroup;

  /**
   * This object is bullshit lol lol lol
   */
  var camFollow:FlxObject;

  /**
   * Creating many many stuff
   */
  override function create()
  {
    camGame = initPsychCamera();

    camStuff = new FlxCamera();
    camStuff.bgColor.alpha = 0;
    FlxG.cameras.add(camStuff, false);

    if (!FlxG.sound.music.playing)
    {
      FlxG.sound.music.loadEmbedded(Paths.music('freakyMenu'));
      FlxG.sound.music.play();
    }

    FlxG.mouse.visible = true;

    stuffVariables();

    super.create();

    firstClass = new FlxSpriteGroup();
    add(firstClass);

    var bg = new FlxSprite().loadGraphic(Paths.image('nothing'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.screenCenter();
    bg.scrollFactor.set(0.15, 0.15);
    bg.updateHitbox();
    firstClass.add(bg);

    var backdrop4ik1:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0xF04B0298, 0x0));
    backdrop4ik1.velocity.set(40, 40);
    firstClass.add(backdrop4ik1);

    var bt1 = new FlxSprite().loadGraphic(Paths.image('pol'));
    bt1.antialiasing = ClientPrefs.data.antialiasing;
    bt1.screenCenter();
    bt1.scrollFactor.set(0.15, 0.15);
    bt1.updateHitbox();
    firstClass.add(bt1);

    var par5:FlxSprite = new FlxSprite();
    par5.frames = Paths.getSparrowAtlas('par5');
    par5.animation.addByPrefix('par5', 'par5', 1, false);
    par5.animation.play('par5');
    par5.screenCenter();
    par5.antialiasing = ClientPrefs.data.antialiasing;
    par5.scrollFactor.set(0.15, 0.15);
    par5.updateHitbox();
    firstClass.add(par5);

    var bt1 = new FlxSprite().loadGraphic(Paths.image('tvscary'));
    bt1.antialiasing = ClientPrefs.data.antialiasing;
    bt1.screenCenter();
    bt1.scrollFactor.set(0.15, 0.15);
    bt1.updateHitbox();
    firstClass.add(bt1);

    var bt1 = new FlxSprite().loadGraphic(Paths.image('aura'));
    bt1.antialiasing = ClientPrefs.data.antialiasing;
    bt1.screenCenter();
    bt1.scrollFactor.set(0.15, 0.15);
    bt1.updateHitbox();
    firstClass.add(bt1);

    pitchGrp = new FlxSpriteGroup();
    add(pitchGrp);

    buttonGrp = new FlxSpriteGroup();
    add(buttonGrp);

    camGrp = new FlxSpriteGroup();
    camGrp.scrollFactor.set();
    camGrp.cameras = [camStuff];
    add(camGrp);

    for (shit in all_shit)
    {
      if (shit.pitch.prefix != null)
      {
        var pp:FlxSprite = new FlxSprite();
        pp.frames = Paths.getSparrowAtlas(shit.pitch.prefix.name);
        for (i in 0...shit.pitch.prefix.anims.length)
        {
          final ppLooped:Bool = (shit.pitch.prefix.anims[i].loop != null ? shit.pitch.prefix.anims[i].loop : true);
          pp.animation.addByPrefix(shit.pitch.prefix.anims[i].name, shit.pitch.prefix.anims[i].xml, shit.pitch.prefix.anims[i].fps, ppLooped);
        }
        pp.visible = false;
        pp.animation.play(shit.pitch.prefix.idleAnim);
        pp.antialiasing = ClientPrefs.data.antialiasing;
        pp.setGraphicSize(pp.width * (shit.pitch.scale != null ? shit.pitch.scale : 1));
        pp.screenCenter();
        pp.x += (shit.pitch.addX != null ? shit.pitch.addX : 0);
        pp.y += (shit.pitch.addY != null ? shit.pitch.addY : 0);
        pp.scrollFactor.set(0.15, 0.15);
        pp.updateHitbox();
        pitchGrp.add(pp);
        trace("ermm " + shit.pitch.name);
      }

      if (shit.pitch.text != null)
      {
        var pp:FlxText = new FlxText(0, 0, 500, shit.pitch.text, 20);
        pp.setFormat(Paths.font('HelpMe.ttf'), 20, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        pp.visible = false;
        pp.screenCenter();
        pp.scrollFactor.set(0.15, 0.15);
        pp.updateHitbox();
        pitchGrp.add(pp);
        trace('ermm ' + shit.pitch.name);
      }

      var item:FlxSprite = new FlxSprite(shit.x, shit.y);
      item.frames = Paths.getSparrowAtlas(buttonsPath + shit.tag);
      item.antialiasing = ClientPrefs.data.antialiasing;
      item.animation.addByPrefix('idle', shit.tag + " basic", 24);
      item.animation.addByPrefix('select', shit.tag + " white", 24);
      item.animation.play('idle');
      item.alpha = .6;
      item.scale.set(0.9, 0.9);
      item.scrollFactor.set(0.25, 0.25);
      item.updateHitbox();
      buttonGrp.add(item);
    }

    var staticLol:FlxSprite = new FlxSprite();
    staticLol.frames = Paths.getSparrowAtlas('staticShit');
    staticLol.animation.addByPrefix('idle', 'StaticIdle', 24, true);
    staticLol.animation.play('idle');
    staticLol.visible = ClientPrefs.data.flashing;
    staticLol.setGraphicSize(staticLol.width * 1.6);
    staticLol.setPosition(-100, -100);
    staticLol.scrollFactor.set();
    staticLol.updateHitbox();
    camGrp.add(staticLol);

    var vuradoImport:FlxText = new FlxText(5, FlxG.height - 24, 0, GAME_VERSION, 12);
    vuradoImport.scrollFactor.set();
    vuradoImport.setFormat(Paths.font('HelpMe.ttf'), 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
    camGrp.add(vuradoImport);

    if (ClientPrefs.data.shaders)
    {
      vcrEffect = new VcrGlitchEffect();
      var s = new VignetteShader();
      FlxG.camera.setFilters([new ShaderFilter(vcrEffect.shader), new ShaderFilter(s)]);
    }

    FlxG.camera.zoom = 0.925;
    changeSelection(0, false, true);
  }

  var selected:Bool = false;

  override function update(e:Float)
  {
    musicVolumeFix(e);

    super.update(e);

    if (vcrEffect != null) vcrEffect.update(e);

    var lerpVal:Float = boundTo(e * 2.4, 0, 1);
    if (!selected)
    {
      FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, (FlxG.mouse.screenX - (FlxG.width / 2)) * 0.015, lerpVal);
      FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, (FlxG.mouse.screenY - (FlxG.height / 2) - 6) * 0.015, lerpVal);

      if (controls.BACK || FlxG.mouse.justPressedRight) select();
      if (controls.ACCEPT) select('custom');

      #if debug
      FlxG.mouse.visible = true;
      #end

      final curMouse = FlxG.mouse;

      if (curMouse.overlaps(buttonGrp.members[curSelected])) if (FlxG.mouse.justPressed) select('custom');

      if (curMouse.justMoved)
      {
        // lol

        for (i in 0...buttonGrp.members.length)
        {
          if (curMouse.overlaps(buttonGrp.members[i]))
          {
            if (i == curSelected) continue;

            changeSelection(i, true);
          }
        }
      }
      else
      {
        if (controls.UI_LEFT_P) changeSelection(-1);
        if (controls.UI_RIGHT_P) changeSelection(1);

        if (controls.UI_UP_P) changeUpDown(-1);
        if (controls.UI_DOWN_P) changeUpDown(1);
      }
    }
  }

  static function boundTo(value:Float, min:Float, max:Float):Float
  {
    return Math.max(min, Math.min(max, value));
  }

  function changeUpDown(v:Int)
  {
    curUpDownSel += v;

    if (curUpDownSel >= 2) curUpDownSel = 0;
    if (curUpDownSel < 0) curUpDownSel = 1;

    changeSelection(0);
  }

  var staticTween:FlxTween;

  function changeSelection(v:Int, ?isMouse:Bool = false, ?isCreateFunc:Bool = false)
  {
    FlxG.sound.play(Paths.sound('scrollMenu'));

    if (staticTween != null) staticTween.cancel();

    camGrp.members[0].alpha = (isCreateFunc ? 0.001 : FlxG.random.float(0.4, 0.6));

    staticTween = FlxTween.tween(camGrp.members[0], {alpha: 0.05}, 0.6, {ease: FlxEase.quadOut, onComplete: (t:FlxTween) -> t = null});

    buttonGrp.members[curSelected].animation.play('idle');
    buttonGrp.members[curSelected].alpha = .6;
    buttonGrp.members[curSelected].updateHitbox();

    pitchGrp.members[curSelected].visible = false;
    pitchGrp.members[curSelected].updateHitbox();

    if (!isMouse)
    {
      curSelected += v;

      if (curUpDownSel == 0)
      {
        if (curSelected >= 2) curSelected = 0;
        if (curSelected < 0) curSelected = 1;
      }
      else if (curUpDownSel == 1)
      {
        if (curSelected >= 4) curSelected = 2;
        if (curSelected < 2) curSelected = 3;
      }
    }
    else
    {
      curSelected = v;

      // for keys support shit
      if (curSelected == 0 || curSelected == 1) curUpDownSel = 0;
      else
        curUpDownSel = 1;
    }

    buttonGrp.members[curSelected].animation.play('select');
    buttonGrp.members[curSelected].alpha = 1;
    pitchGrp.members[curSelected].visible = true;
  }

  function select(value:String = 'title')
  {
    FlxG.mouse.visible = false;

    if (staticTween != null) staticTween.cancel();

    camGrp.members[0].alpha = 0.25;

    staticTween = FlxTween.tween(camGrp.members[0], {alpha: 0.075}, 0.35, {ease: FlxEase.quadIn, onComplete: (t:FlxTween) -> t = null});
    FlxTween.tween(camGrp.members[0], {alpha: 1}, 1.25, {ease: FlxEase.cubeInOut, startDelay: 0.35, onComplete: (t:FlxTween) -> t = null});

    var lerpVal:Float = boundTo(FlxG.elapsed * 2.4, 0, 1);
    switch (value)
    {
      case 'custom':
        if (buttonGrp == null)
        {
          FlxG.sound.play(Paths.sound('cancelMenu'));
          trace('fuck, buttonGrp is null!');

          return;
        }

        FlxG.sound.play(Paths.sound('confirmMenu'));
        selected = true;

        FlxG.camera.fade(FlxColor.BLACK, 1);

        camStuff.fade(FlxColor.BLACK, 1);

        FlxTween.tween(FlxG.camera, {angle: (FlxG.random.bool(50) ? 360 : -360)}, 3, {ease: FlxEase.cubeIn});
        FlxTween.tween(FlxG.camera, {zoom: 1.4}, 1.74, {ease: FlxEase.quadOut});

        FlxG.camera.scroll.x = FlxMath.lerp(FlxG.camera.scroll.x, buttonGrp.members[curSelected].getScreenPosition().x, lerpVal);
        FlxG.camera.scroll.y = FlxMath.lerp(FlxG.camera.scroll.y, buttonGrp.members[curSelected].getScreenPosition().y, lerpVal);

        if (all_shit[curSelected].tag == 'credits' || all_shit[curSelected].tag == 'extras') FlxG.sound.music.fadeOut(1, 0, (_) -> {
          FlxG.sound.music.stop();
        });

        FlxFlicker.flicker(buttonGrp.members[curSelected], 1, 0.06, false, false, (_) -> {
          switch (all_shit[curSelected].tag)
          {
            case 'options':
              psych.options.OptionsState.onPlayState = false;
              if (PlayState.SONG != null)
              {
                PlayState.SONG.arrowSkin = null;
                PlayState.SONG.splashSkin = null;
                PlayState.stageUI = 'normal';
              }
            default: // nothing bitch
          }
          MusicBeatState.switchState(all_shit[curSelected].menu);
        });

        for (i in 0...buttonGrp.members.length)
        {
          if (i == curSelected) continue;

          FlxTween.tween(buttonGrp.members[i], {alpha: 0}, 0.4,
            {
              ease: FlxEase.quadOut,
              onComplete: (_:FlxTween) -> {
                _ = null;
                buttonGrp.members[i].kill();
              }
            });
        }

      default:
        FlxG.camera.fade();
        FlxTween.tween(FlxG.camera, {zoom: 0.15}, 3, {ease: FlxEase.quadInOut});
        FlxG.sound.play(Paths.sound('cancelMenu'));
        selected = true;
        MusicBeatState.switchState(new TitleState());
    }
  }

  private function musicVolumeFix(e:Float)
  {
    if (FlxG.sound.music != null && FlxG.sound.music.playing) if (FlxG.sound.music.volume < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * e;
      if (FreeplayState.vocals != null && FreeplayState.vocals.playing) FreeplayState.vocals.volume += 0.5 * e;
    }
  }

  private function stuffVariables()
  {
    #if MODS_ALLOWED
    Mods.pushGlobalMods();
    #end
    Mods.loadTopMod();

    #if DISCORD_ALLOWED
    DiscordClient.instance.changePresence({details: "Main Menu"});
    #end

    for (f in cacheShit)
      Paths.image(f);

    transIn = defaultTransIn;
    transOut = defaultTransOut;

    persistentUpdate = persistentUpdate = true;
  }
}

typedef ItemOptions =
{
  var tag:String;
  var menu:FlxState;
  var x:Float;
  var y:Float;
  var pitch:PitchOptions;
}

typedef PitchOptions =
{
  var name:String;
  var ?addX:Float;
  var ?addY:Float;
  var ?scale:Float;
  var ?prefix:PrefixLol;
  var ?text:String;
}

typedef PrefixLol =
{
  var name:String;
  var anims:Array<AnimData>;
  var idleAnim:String;
}

typedef AnimData =
{
  var name:String;
  var xml:String;
  var fps:Float;
  var ?loop:Bool;
}
