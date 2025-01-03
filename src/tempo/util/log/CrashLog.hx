package tempo.util.log;

#if CRASH_HANDLER
import tempo.util.MemoryUtil;
import tempo.util.DateUtil;
import flixel.FlxG;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.system.System;
import openfl.events.UncaughtErrorEvent;

// TODO: Create a program 'TempoCrashHandler.exe' and here writing data, starting, and etc.

@:nullSafety
class CrashLog
{
  public static function init()
  {
    Sys.println('Crash Log: Standard uncaught error handler enabling...');
    FlxG.game.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, standardError);

    #if (cpp && !debug) // for debug build - idk where a error
    Sys.println('Crash Log: C++ critical error handler enabling...');
    untyped __global__.__hxcpp_set_critical_error_handler(criticalError);
    #end
  }

  public static var standardSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  static function standardError(e:UncaughtErrorEvent)
  {
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.shutdown();
    #end

    try
    {
      standardSignal.dispatch(CrashReference.generateMsg(e));

      #if sys
      CrashReference.logError(e);
      #end

      CrashReference.displayError(e);
    }
    catch (e)
      Sys.println('Crash Log: Handling Error: $e');

    System.exit(1);
  }

  #if (cpp && !debug)
  public static var criticalSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  static function criticalError(e:String)
  {
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.shutdown();
    #end

    try
    {
      criticalSignal.dispatch(e);

      #if sys
      CrashReference.logErrorMsg(e, true);
      #end

      @:privateAccess CrashReference.displayErrorMsg(e #if windows, "Critical Error" #end);
    }
    catch (e)
    {
      Sys.println('Crash Log: Critical Handling Error: $e');
      Sys.println('Message: $e');
    }

    System.exit(1);
  }
  #end

  static final pr:String = "======================";

  public static function createContent(msg:String):String
  {
    final driverInfo:String = FlxG?.stage?.context3D?.driverInfo ?? 'N\\A';
    final curState:String = FlxG.state != null ? Type.getClassName(Type.getClass(FlxG.state)) : 'Unknown State';

    var fc:String = '$pr\n';
    fc += '| Tempo Crash Dialog |\n';
    fc += '$pr\n\n';
    fc += 'Generated By: ${Constants.CRASH_GENERATED_BY}\n';
    fc += 'Crashed at: ${DateUtil.generateTimestamp()}\n';
    fc += 'Driver Info: ${driverInfo}\n';
    fc += 'Platform: ${Sys.systemName()}\n';
    fc += 'Render method: ${CrashReference.renderMethod()}\n\n';
    fc += MemoryUtil.buildGCInfo() + '\n\n';
    fc += '$pr\n\n';
    fc += 'Flixel Current State: ${curState}\n\n';
    fc += '$pr\n\n';
    fc += 'Haxelibs:\n';

    for (lib in Constants.LIBRARY_VERSIONS)
      fc += '- ${lib}\n';

    fc += '\n';
    fc += '$pr\n\n';
    fc += msg;
    fc += '\n';

    return fc;
  }
}

@:keep
@:access(engine.util.log.CrashLog)
private class CrashReference
{
  static var file:String = "";

  public static function displayError(e:UncaughtErrorEvent):Void
    displayErrorMsg(generateMsg(e) #if windows, generateFirMsg(e) #end);

  public static function displayErrorMsg(e:String #if windows, msg:String #end):Void
  {
    #if windows
    final appName:String = (openfl.Lib.application.meta.get('file') != null ? openfl.Lib.application.meta.get('file') : 'Finality End') + ".exe";
    final parentDir:String = Sys.programPath().substr(0, Sys.programPath().length - appName.length);

    trace(appName);
    trace(parentDir);

    Sys.command("cd " + parentDir);

    try
      Sys.command('start', [
        'TempoCrashHandler.exe',
        '"$msg"',
        '"$e"',
        '"$file"',
        '"${Constants.GITHUB_URL + '/issues'}"',
        '$appName'
      ])
    catch (ex:haxe.Exception)
      Sys.println(ex);
    #else
    openfl.Lib.application.window.alert('| TEMPO CRASH LOG |' + '\n' + CrashLog.pr + '\n' + e + '\n' + CrashLog.pr + '\n\n'
      + 'Generated by: ${TConstants.CRASH_GENERATED_BY}' + '\n' + 'Reporting to: ${TConstants.GITHUB_URL}/issues',
      "FATAL UNCAUGHT ERROR");
    #end

    trace(#if windows '\n$msg\n\n' + #end e.replace('$', '\n'));
  }

  #if sys
  public static function logError(e:UncaughtErrorEvent)
  {
    logErrorMsg(generateMsg(e));
  }

  public static function logErrorMsg(e:String, c:Bool = false)
  {
    FileUtil.createFolderIfNotExist('logs');

    Sys.println("\nGame crash dump in: " + haxe.io.Path.normalize('./logs/tempo-crash${c ? '-critical' : ''}-${DateUtil.generateTimestamp()}.log'));

    file = "tempo-crash" + (c ? '-critical' : '') + '-' + DateUtil.generateTimestamp();

    sys.io.File.saveContent('./logs/$file.log', CrashLog.createContent(e));
  }
  #end

  public static function renderMethod():String
  {
    var output:String = 'UNKNOWN';
    output = try
    {
      switch (FlxG.renderMethod)
      {
        case FlxRenderMethod.DRAW_TILES: 'DRAW_TILES';
        case FlxRenderMethod.BLITTING: "BLITTING";
        default: 'UNKNOWN';
      }
    }
    catch (e)
      'ERROR ON QUERY RENDER METHOD: $e';

    return output;
  }

  #if windows
  static function generateFirMsg(e:UncaughtErrorEvent):String
    return Std.string(e.error);
  #end

  public static function generateMsg(e:UncaughtErrorEvent):String
  {
    var msg:String = "";
    var callStack:Array<haxe.CallStack.StackItem> = haxe.CallStack.exceptionStack(true);

    #if !windows
    msg += '${e.error}\n';

    for (stackItem in callStack)
    {
      switch (stackItem)
      {
        case FilePos(innerStackItem, file, line, column):
          msg += ' ${file}#${line}' + (innerStackItem != null ? ' ${innerStackItem}' : '');
          if (column != null) msg += ':${column}';
        case CFunction:
          msg += '[Function] ';
        case Module(m):
          msg += '[Module(${m})] ';
        case Method(classname, method):
          msg += '[Function(${classname}.${method})] ';
        case LocalFunction(v):
          msg += '[LocalFunction(${v})] ';
        default:
          Sys.println(stackItem);
      }
      msg += '\n';
    }
    #else
    for (stackItem in callStack)
    {
      switch (stackItem)
      {
        case FilePos(innerStackItem, file, line, column):
          msg += '${file}#${line}' + (innerStackItem != null ? ' ${innerStackItem}' : '');
          if (column != null) msg += ':${column}';
        case CFunction:
          msg += '[Function] ';
        case Module(m):
          msg += '[Module(${m})] ';
        case Method(classname, method):
          msg += '[Function(${classname}.${method})] ';
        case LocalFunction(v):
          msg += '[LocalFunction(${v})] ';
        default:
          Sys.println(stackItem);
      }
      msg += '$';
    }
    #end

    return msg;
  }
}
#end
