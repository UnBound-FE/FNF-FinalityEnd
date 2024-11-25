package psych.scripts;

import psych.objects.Character;
import psych.scripts.libs.*;
import psych.scripts.LuaUtils;
import psych.scripts.CustomSubstate;
#if LUA_ALLOWED
import psych.scripts.FunkinLua;
#end
import tempo.util.MathUtil;
#if HSCRIPT_ALLOWED
import tscript.TScript;

class HScript extends TScript
{
  public var modFolder:String;

  #if LUA_ALLOWED
  public var parentLua:FunkinLua;

  public static function initHaxeModule(parent:FunkinLua)
  {
    if (parent.hscript == null)
    {
      trace('initializing haxe interp for: ${parent.scriptName}');
      parent.hscript = new HScript(parent);
    }
  }

  public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
  {
    var hs:HScript = try parent.hscript catch (e) null;
    if (hs == null)
    {
      trace('initializing haxe interp for: ${parent.scriptName}');
      parent.hscript = new HScript(parent, code, varsToBring);
    }
    else
    {
      hs.varsToBring = varsToBring;
      hs.doString(code);
      @:privateAccess
      if (hs.parsingException != null)
      {
        PlayState.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.msg}', FlxColor.RED);
      }
    }
  }
  #end

  public var origin:String;

  override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null)
  {
    if (file == null) file = '';

    super(file, false, false);

    #if LUA_ALLOWED
    parentLua = parent;
    if (parent != null)
    {
      this.origin = parent.scriptName;
      this.modFolder = parent.modFolder;
    }
    #end

    if (scriptFile != null && scriptFile.length > 0)
    {
      this.origin = scriptFile;
      #if MODS_ALLOWED
      var myFolder:Array<String> = scriptFile.split('/');
      if (myFolder[0] + '/' == Paths.mods()
        && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
        this.modFolder = myFolder[1];
      #end
    }

    this.varsToBring = varsToBring;

    preset();
    execute();
  }

  var varsToBring(default, set):Any = null;

  override function preset()
  {
    super.preset();

    // Some very commonly used classes
    set('FlxG', flixel.FlxG);
    set('FlxMath', flixel.math.FlxMath);
    set('FlxSprite', flixel.FlxSprite);
    set('FlxText', flixel.text.FlxText);
    set('FlxCamera', flixel.FlxCamera);
    set('PsychCamera', psych.backend.PsychCamera);
    set('FlxTimer', flixel.util.FlxTimer);
    set('FlxTween', flixel.tweens.FlxTween);
    set('FlxEase', flixel.tweens.FlxEase);
    set('FlxFlicker', flixel.effects.FlxFlicker);
    set('FlxColor', ScriptingFlxColor);
    set('Countdown', psych.backend.BaseStage.Countdown);
    set('PlayState', PlayState);
    set('Paths', Paths);
    set('Controls', Controls);
    set('Conductor', Conductor);
    set('Constants', Constants);
    set('CoolUtil', CoolUtil);
    set('MathUtil', MathUtil);
    set('ClientPrefs', ClientPrefs);
    set('Character', Character);
    set('Alphabet', Alphabet);
    set('Note', psych.objects.Note);
    set('CustomSubstate', CustomSubstate);
    #if (!flash && sys)
    set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
    #end
    set('ShaderFilter', openfl.filters.ShaderFilter);
    set('StringTools', StringTools);
    #if flxanimate
    set('FlxAnimate', FlxAnimate);
    #end

    // Functions & Variables
    set('setVar', function(name:String, value:Dynamic) {
      PlayState.instance.variables.set(name, value);
      return value;
    });
    set('getVar', function(name:String) {
      var result:Dynamic = null;
      if (PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
      return result;
    });
    set('removeVar', function(name:String) {
      if (PlayState.instance.variables.exists(name))
      {
        PlayState.instance.variables.remove(name);
        return true;
      }
      return false;
    });
    set('debugPrint', function(text:String, ?color:FlxColor = null) {
      if (color == null) color = FlxColor.WHITE;
      PlayState.instance.addTextToDebug(text, color);
    });
    set('getModSetting', function(saveTag:String, ?modName:String = null) {
      if (modName == null)
      {
        if (this.modFolder == null)
        {
          PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
          return null;
        }
        modName = this.modFolder;
      }
      return LuaUtils.getModSetting(saveTag, modName);
    });

    // Keyboard & Gamepads
    set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
    set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
    set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

    set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
    set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
    set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

    set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    set('gamepadJustPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justPressed, name) == true;
    });
    set('gamepadPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.pressed, name) == true;
    });
    set('gamepadReleased', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justReleased, name) == true;
    });

    set('keyJustPressed', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_P;
        case 'down':
          return Controls.instance.NOTE_DOWN_P;
        case 'up':
          return Controls.instance.NOTE_UP_P;
        case 'right':
          return Controls.instance.NOTE_RIGHT_P;
        default:
          return Controls.instance.justPressed(name);
      }
      return false;
    });
    set('keyPressed', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT;
        case 'down':
          return Controls.instance.NOTE_DOWN;
        case 'up':
          return Controls.instance.NOTE_UP;
        case 'right':
          return Controls.instance.NOTE_RIGHT;
        default:
          return Controls.instance.pressed(name);
      }
      return false;
    });
    set('keyReleased', function(name:String = '') {
      name = name.toLowerCase();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_R;
        case 'down':
          return Controls.instance.NOTE_DOWN_R;
        case 'up':
          return Controls.instance.NOTE_UP_R;
        case 'right':
          return Controls.instance.NOTE_RIGHT_R;
        default:
          return Controls.instance.justReleased(name);
      }
      return false;
    });

    // For adding your own callbacks
    // not very tested but should work
    #if LUA_ALLOWED
    set('createGlobalCallback', function(name:String, func:Dynamic) {
      for (script in PlayState.instance.luaArray)
        if (script != null && script.lua != null && !script.closed) Lua_helper.add_callback(script.lua, name, func);

      FunkinLua.customFunctions.set(name, func);
    });

    // this one was tested
    set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
      if (funk == null) funk = parentLua;

      if (parentLua != null) funk.addLocalCallback(name, func);
      else
        FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
    });
    #end

    set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
      try
      {
        var str:String = '';
        if (libPackage.length > 0) str = libPackage + '.';

        set(libName, Type.resolveClass(str + libName));
      }
      catch (e:Dynamic)
      {
        var msg:String = e.message.substr(0, e.message.indexOf('\n'));
        #if LUA_ALLOWED
        if (parentLua != null)
        {
          FunkinLua.lastCalledScript = parentLua;
          FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
          return;
        }
        #end
        if (PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
        else
          trace('$origin - $msg');
      }
    });
    #if LUA_ALLOWED
    set('parentLua', parentLua);
    #else
    set('parentLua', null);
    #end
    set('this', this);
    set('game', FlxG.state);
    set('controls', Controls.instance);

    set('buildTarget', LuaUtils.getBuildTarget());
    set('customSubstate', CustomSubstate.instance);
    set('customSubstateName', CustomSubstate.name);

    set('Function_Stop', LuaUtils.Function_Stop);
    set('Function_Continue', LuaUtils.Function_Continue);
    set('Function_StopLua', LuaUtils.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
    set('Function_StopHScript', LuaUtils.Function_StopHScript);
    set('Function_StopAll', LuaUtils.Function_StopAll);

    set('add', FlxG.state.add);
    set('insert', FlxG.state.insert);
    set('remove', FlxG.state.remove);

    if (PlayState.instance == FlxG.state)
    {
      set('addBehindGF', PlayState.instance.addBehindGF);
      set('addBehindDad', PlayState.instance.addBehindDad);
      set('addBehindBF', PlayState.instance.addBehindBF);
      setSpecialObject(PlayState.instance, false, PlayState.instance.instancesExclude);
    }
  }

  public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):FileData
  {
    if (funcToRun == null) return null;

    trace('test');
    if (!exists(funcToRun))
    {
      #if LUA_ALLOWED
      FunkinLua.luaTrace(origin + ' - No HScript function named: $funcToRun', false, false, FlxColor.RED);
      #else
      PlayState.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
      #end
      return null;
    }

    final callValue = call(funcToRun, funcArgs);
    if (!callValue.succeeded)
    {
      final e = callValue.exceptions[0];
      if (e != null)
      {
        var msg:String = e.toString();
        #if LUA_ALLOWED
        if (parentLua != null)
        {
          FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
          return null;
        }
        #end
        PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
      }
      return null;
    }
    return callValue;
  }

  public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):FileData
  {
    if (funcToRun == null) return null;
    return call(funcToRun, funcArgs);
  }

  #if LUA_ALLOWED
  public static function implement(funk:FunkinLua)
  {
    funk.addLocalCallback("runHaxeCode",
      function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
        initHaxeModuleCode(funk, codeToRun, varsToBring);
        final retVal:FileData = funk.hscript.executeCode(funcToRun, funcArgs);
        if (retVal != null)
        {
          if (retVal.succeeded) return (retVal.returnValue == null
            || LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

          final e = retVal.exceptions[0];
          final calledFunc:String = if (funk.hscript.origin == funk.lastCalledFunction) funcToRun else funk.lastCalledFunction;
          if (e != null) FunkinLua.luaTrace(funk.hscript.origin + ":" + calledFunc + " - " + e, false, false, FlxColor.RED);
          return null;
        }
        else if (funk.hscript.returnValue != null)
        {
          return funk.hscript.returnValue;
        }
        return null;
      });

    funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
      var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
      if (!callValue.succeeded)
      {
        var e = callValue.exceptions[0];
        if (e != null) FunkinLua.luaTrace('ERROR (${funk.hscript.origin}: ${callValue.calledFunction}) - ' + e.details(), false, false, FlxColor.RED);
        return null;
      }
      else
        return callValue.returnValue;
    });

    funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
      var str:String = '';
      if (libPackage.length > 0) str = libPackage + '.';
      else if (libName == null) libName = '';

      var c:Dynamic = Type.resolveClass(str + libName);
      if (c == null) c = Type.resolveEnum(str + libName);
      if (c != null) TScript.globalVariables[libName] = c;

      if (funk.hscript != null)
      {
        try
        {
          if (c != null) funk.hscript.set(libName, c);
        }
        catch (e:Dynamic)
        {
          FunkinLua.luaTrace(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
        }
      }
    });
  }
  #end

  override public function destroy()
  {
    origin = null;
    #if LUA_ALLOWED parentLua = null; #end

    super.destroy();
  }

  function set_varsToBring(values:Any)
  {
    if (varsToBring != null)
    {
      for (key in Reflect.fields(varsToBring))
      {
        unset(key.trim());
      }
    }

    if (values != null)
    {
      for (key in Reflect.fields(values))
      {
        key = key.trim();
        set(key, Reflect.field(values, key));
      }
    }

    return varsToBring = values;
  }
}
#end
