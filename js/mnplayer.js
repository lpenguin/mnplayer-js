(function() {
  var Root, eventBind, fromTimer, replaceAll, startTimer, stopTimer, toTimer;

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
    messageSpace: 4,
    updateTime: 500
  };

  App.Templates.Player = "<div class=\"play-button symbol clickable\">|>&nbsp;</div>\n<div class=\"pause-button hidden symbol clickable\">||&nbsp;</div>\n<div class=\"symbol\">[</div>\n<div class=\"seek-bar symbol clickable\"></div>\n<div class=\"symbol\">&nbsp;</div>\n<div class=\"time symbol\"></div>\n<div class=\"symbol\">]</div>\n&nbsp;\n<div class=\"symbol info clickable\">[i]</div>\n<div class=\"symbol home-page clickable\">[?]</div><br/>";

  Root.mnplayer = function() {
    return $('.mnplayer').each(function(i, ob) {
      var audio, duration, info, message, player, url;
      message = "";
      url = $(ob).attr('url');
      audio = soundManager.createSound({
        id: 'sound' + i,
        url: url,
        autoLoad: true
      });
      duration = $(ob).attr('duration');
      info = $(ob).attr('info');
      player = new App.Views.Player({
        model: audio,
        duration: duration,
        info: info,
        message: message
      });
      return $(ob).append(player.render());
    });
  };

  eventBind = function(sound, event, func, obj) {
    var f;
    f = function(e) {
      return func.call(obj, e, this);
    };
    return sound.bind(event, f);
  };

  replaceAll = function(string, search, replace) {
    return string.split(search).join(replace);
  };

  fromTimer = function(time) {
    var minutes, seconds, vals;
    vals = time.split(":");
    minutes = vals[0];
    seconds = vals[1];
    return (parseInt(minutes * 60 + parseInt(seconds))) * 1000;
  };

  toTimer = function(ms) {
    var minutes, seconds;
    ms = Math.floor(ms / 1000);
    seconds = ms % 60;
    minutes = Math.floor(ms / 60);
    if (seconds < 10) seconds = '0' + seconds;
    if (minutes < 10) minutes = '0' + minutes;
    return minutes + ":" + seconds;
  };

  startTimer = function(func, delay, scope) {
    var id;
    id = setInterval(function() {
      return func.call(scope);
    }, delay);
    return id;
  };

  stopTimer = function(id) {
    return clearInterval(id);
  };

  App.Views.Player = Backbone.View.extend({
    initialize: function(options) {
      this.barLength = App.Settings.barLength;
      if (options.barLength) this.barLength = options.barLength;
      this.audio = this.model;
      this.duration = this.audio.duration;
      this.audio._whileloading(this.durationchange, this);
      if (options.duration) this.manualDuration = fromTimer(options.duration);
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
      return this.$el.find('.time').html(toTimer(this.model.position));
    },
    drawMessage: function() {
      this.$el.find('.seek-bar').html(this.makeMessageBar());
      return this.$el.find('.time').html(toTimer(this.model.position));
    },
    timeupdate: function(e) {
      if (this.showMode === 'bar') this.drawSeekBar();
      if (this.showMode === 'message') this.drawMessage();
      if (this.duration && this.model.duration > this.duration) {
        this.pause();
        return this.model.setPosition(0);
      }
    },
    getDuration: function() {
      if (this.manualDuration) return this.manualDuration;
      return this.audio.duration;
    },
    durationchange: function(e) {
      this.duration = this.model.duration;
      if (this.manualDuration) return this.duration = this.manualDuration;
    },
    showMessage: function(message) {
      this.message = message;
      if (this.showMode !== 'message') this.setMessageMode();
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
      position = Math.floor(this.barLength * this.model.position / this.getDuration() + 1);
      console.log(position + '/' + this.barLength);
      out = "";
      for (i = 1, _ref = this.barLength; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        if (i <= position && position !== 1) {
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
        m = m.substring(this.messagePosition, this.barLength + this.messagePosition);
      }
      rest = this.barLength - m.length;
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
      this.$el.find('.time').html(toTimer(this.model.position));
      return this.$el;
    },
    play: function() {
      this.timeupdateTimer = startTimer(this.timeupdate, App.Settings.updateTime, this);
      this.model.play();
      return this.togglePlayButton();
    },
    pause: function() {
      stopTimer(this.timeupdateTimer);
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
      this.model.setPosition(x / width * this.getDuration());
      return this.timeupdate();
    },
    homePage: function() {
      return window.open('https://github.com/lpenguin/mnplayer-js', '_newtab');
    }
  });

  Root.soundManager.url = 'http://lpenguin.narod2.ru/swf/';

  soundManager.preferFlash = false;

  Root.soundManager.onready(function() {
    if (App.Settings.autoLoad) return mnplayer();
  });

}).call(this);
