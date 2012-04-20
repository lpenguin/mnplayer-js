(function() {
  var Root, buzzBind, replaceAll;

  Root = window;

  Root.App = {
    Views: {},
    Models: {},
    Routers: {},
    Templates: {}
  };

  App.Settings = {
    barLength: 28,
    autoLoad: true,
    messageStep: 500,
    messageSpace: 4
  };

  App.Templates.Player = "<div class=\"play-button symbol clickable\">|>&nbsp;</div>\n<div class=\"pause-button hidden symbol clickable\">||&nbsp;</div>\n<div class=\"symbol\">[</div>\n<div class=\"seek-bar symbol clickable\"></div>\n<div class=\"symbol\">&nbsp;</div>\n<div class=\"time symbol\"></div>\n<div class=\"symbol\">]</div>\n&nbsp;\n<div class=\"symbol info clickable\">[i]</div>\n<div class=\"symbol home-page clickable\">[?]</div><br/>";

  Root.mnplayer = function() {
    var message;
    if (!buzz.isSupported()) {
      message = 'sorry HTML5 is not supported by your browser';
    }
    return $('.mnplayer').each(function(i, ob) {
      var audio, duration, info, mp3url, oggurl, player, url;
      url = $(ob).attr('url');
      mp3url = $(ob).attr('mp3url');
      oggurl = $(ob).attr('oggurl');
      if (mp3url && buzz.isMP3Supported()) url = mp3url;
      if (oggurl && buzz.isOGGSupported()) url = oggurl;
      if (!url) message = 'sorry, no audio';
      duration = $(ob).attr('duration');
      info = $(ob).attr('info');
      audio = new buzz.sound(url, {
        preload: true,
        loop: false
      });
      player = new App.Views.Player({
        model: audio,
        duration: duration,
        info: info,
        message: message
      });
      return $(ob).append(player.render());
    });
  };

  buzzBind = function(sound, event, func, obj) {
    var f;
    f = function(e) {
      return func.call(obj, e, this);
    };
    return sound.bind(event, f);
  };

  replaceAll = function(string, search, replace) {
    return string.split(search).join(replace);
  };

  App.Views.Player = Backbone.View.extend({
    initialize: function(options) {
      this.barLength = App.Settings.barLength;
      if (options.barLength) this.barLength = options.barLength;
      buzzBind(this.model, 'timeupdate', this.timeupdate, this);
      buzzBind(this.model, 'durationchange', this.durationchange, this);
      buzzBind(this.model, 'error', this.soundError, this);
      if (options.duration) this.manualDuration = buzz.fromTimer(options.duration);
      this.info = options.info || '';
      this.showMode = 'bar';
      this.messagePosition = 0;
      if (options.message) return this.showMessage(options.message);
    },
    setBarMode: function() {
      this.showMode = 'bar';
      if (this.messageInterval) return clearInterval(this.messageInterval);
    },
    setMessageMode: function() {
      var that;
      this.showMode = 'message';
      this.messagePosition = 0;
      that = this;
      return this.messageInterval = setInterval((function() {
        return that.updateMessage();
      }), App.Settings.messageStep);
    },
    updateMessage: function() {
      this.drawMessage();
      this.messagePosition++;
      if (this.messagePosition >= this.message.length + App.Settings.messageSpace) {
        return this.messagePosition = 0;
      }
    },
    drawSeekBar: function() {
      this.$el.find('.seek-bar').html(this.makeSeekBar());
      return this.$el.find('.time').html(buzz.toTimer(this.model.getTime()));
    },
    drawMessage: function() {
      this.$el.find('.seek-bar').html(this.makeMessageBar());
      return this.$el.find('.time').html(buzz.toTimer(this.model.getTime()));
    },
    timeupdate: function(e) {
      if (this.showMode === 'bar') this.drawSeekBar();
      if (this.showMode === 'message') this.drawMessage();
      if (this.duration && this.model.getTime() > this.duration) {
        this.pause();
        return this.model.setTime(0);
      }
    },
    durationchange: function(e) {
      this.duration = this.model.getDuration();
      if (this.manualDuration) return this.duration = this.manualDuration;
    },
    showMessage: function(message) {
      this.message = message;
      this.setMessageMode();
      return this.drawMessage();
    },
    soundAbort: function(e) {
      return this.showMessage('aborted');
    },
    soundError: function(e) {
      var msg;
      msg = 'error';
      if (e.target instanceof HTMLAudioElement) {
        switch (this.model.getErrorCode()) {
          case 1:
            msg += ': aborted by user';
            break;
          case 2:
            msg += ': network error';
            break;
          case 3:
            msg += ': decode error';
            break;
          case 4:
            msg += ': audio is not supported by your browser';
        }
      } else if (e.target instanceof HTMLSourceElement) {
        msg += ': audio is not supported by your browser';
      }
      return this.showMessage(msg);
    },
    events: {
      "click .play-button": "play",
      "click .pause-button": "pause",
      "click .seek-bar": "seek",
      "click .home-page": "homePage",
      "click .info": "showInfo"
    },
    template: App.Templates.Player,
    className: "player-js",
    makeSeekBar: function() {
      var i, out, position, _ref;
      position = Math.floor(this.barLength * this.model.getTime() / this.duration);
      out = "";
      for (i = 0, _ref = this.barLength; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        if (i < position) {
          out += '=';
        } else {
          out += '-';
        }
      }
      return out;
    },
    makeMessageBar: function() {
      var left, m, minit, rest, space;
      space = App.Settings.messageSpace;
      m = minit = (this.message || '') + Array(space + 1).join(' ');
      if (m.length > this.barLength) {
        m = m.substring(this.messagePosition, this.barLength + this.messagePosition + 1);
      }
      rest = this.barLength - m.length + 1;
      if (minit.length > this.barLength) {
        left = minit.substring(0, rest);
      } else {
        left = Array(rest + 1).join(' ');
      }
      return replaceAll(m + left, ' ', '&nbsp;');
    },
    showInfo: function() {
      if (this.showMode === 'message') {
        this.setBarMode();
        this.drawSeekBar();
        return;
      }
      return this.showMessage(this.info);
    },
    render: function() {
      this.$el.html(this.template);
      this.$el.find('.seek-bar').html(this.makeSeekBar());
      this.$el.find('.time').html(buzz.toTimer(this.model.getTime()));
      return this.$el;
    },
    play: function() {
      this.model.play();
      return this.togglePlayButton();
    },
    pause: function() {
      this.model.pause();
      return this.togglePlayButton();
    },
    togglePlayButton: function() {
      this.$el.find('.play-button').toggleClass('hidden');
      return this.$el.find('.pause-button').toggleClass('hidden');
    },
    seek: function(e) {
      var width, x;
      if (this.showMode === 'message') {
        this.setBarMode();
        this.drawSeekBar();
        return;
      }
      x = e.pageX - e.target.offsetLeft;
      width = $(e.target).width();
      return this.model.setTime(x / width * this.duration);
    },
    homePage: function() {
      return window.open('https://github.com/lpenguin/mnplayer-js', '_newtab');
    }
  });

  $(function() {
    if (App.Settings.autoLoad) return mnplayer();
  });

}).call(this);
