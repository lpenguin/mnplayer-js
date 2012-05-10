(function() {
  var mnplayerTumblrPlugin;

  if (!(window.soundManager.plugins != null)) window.soundManager.plugins = [];

  mnplayerTumblrPlugin = (function() {

    function mnplayerTumblrPlugin() {}

    mnplayerTumblrPlugin.prototype.tumblr_cheat_string = '?plead=please-dont-download-this-or-our-lawyers-wont-let-us-host-audio';

    mnplayerTumblrPlugin.prototype.ready = function() {
      var str;
      str = this.tumblr_cheat_string;
      return $('.audio_player').each(function(i, el) {
        var audio_src, div, embed, re, res, src;
        embed = $(this).find('embed').first();
        src = embed.attr('src');
        re = /\?audio_file\=([^\&]+)\&/;
        res = re.exec(src);
        audio_src = res[1] + str;
        console.log(audio_src);
        div = $('<div></div>');
        div.addClass('mnplayer');
        div.attr('url', audio_src);
        return $(this).after(div);
      });
    };

    return mnplayerTumblrPlugin;

  })();

  window.soundManager.plugins.push(new mnplayerTumblrPlugin());

}).call(this);
