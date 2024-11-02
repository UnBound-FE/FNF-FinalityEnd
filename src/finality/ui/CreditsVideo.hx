package finality.ui;

import hxcodec.flixel.FlxVideo;

class CreditsVideo extends MusicBeatState
{
  var fileName:String = 'spyye';

  override function create()
  {
    // bitch
    super.create();

    if (FileSystem.exists(Paths.video(fileName)))
    {
      var video:FlxVideo = new FlxVideo();
      // Recent versions
      video.play(Paths.video(fileName));
      video.onEndReached.add(() -> {
        FlxG.sound.music.fadeIn(4, 0, 0.7);
        MusicBeatState.switchState(new MainMenuState());
      }, true);
    }
    else
    {
      Sys.println('Hold on! File don\'t exists!');
      Sys.sleep(1.0);
      MusicBeatState.switchState(new MusicBeatState());
    }
  }
}
