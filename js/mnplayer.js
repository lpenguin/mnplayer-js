(function() {
  var Root, buzzBind;

  Root = window;

  Root.App = {
    Views: {},
    Models: {},
    Routers: {},
    Templates: {}
  };

  App.Settings = {
    barLength: 28,
    autoLoad: true
  };

  App.Templates.Player = "<div class=\"play-button symbol\">|>&nbsp;</div>\n<div class=\"pause-button hidden symbol\">||&nbsp;</div>\n<div class=\"symbol\">[</div>\n<div class=\"seek-bar symbol\"></div>\n<div class=\"symbol\">&nbsp;</div>\n<div class=\"time symbol\"></div>\n<div class=\"symbol\">]</div>\n&nbsp;\n<div class=\"symbol home-page\">[?]</div><br/>";

  Root.mnplayer = function() {
    return $('.mnplayer').each(function(i, ob) {
      var audio, duration, player, url;
      url = $(ob).attr('url');
      duration = $(ob).attr('duration');
      audio = new buzz.sound(url, {
        preload: true,
        loop: false
      });
      player = new App.Views.Player({
        model: audio,
        duration: duration
      });
      return $(ob).append(player.render());
    });
  };

  buzzBind = function(sound, event, func, obj) {
    var f;
    f = function() {
      return func.call(obj, this);
    };
    return sound.bind(event, f);
  };

  App.Views.Player = Backbone.View.extend({
    initialize: function(options) {
      this.barLength = App.Settings.barLength;
      if (options.barLength) this.barLength = options.barLength;
      buzzBind(this.model, 'timeupdate', this.timeupdate, this);
      buzzBind(this.model, 'durationchange', this.durationchange, this);
      if (options.duration) {
        return this.manualDuration = buzz.fromTimer(options.duration);
      }
    },
    timeupdate: function(sound) {
      this.$el.find('.seek-bar').html(this.makeSeekBar());
      this.$el.find('.time').html(buzz.toTimer(this.model.getTime()));
      if (this.duration && this.model.getTime() > this.duration) {
        this.pause();
        return this.model.setTime(0);
      }
    },
    durationchange: function(sound) {
      this.duration = this.model.getDuration();
      if (this.manualDuration) return this.duration = this.manualDuration;
    },
    events: {
      "click .play-button": "play",
      "click .pause-button": "pause",
      "click .seek-bar": "seek",
      "click .home-page": "homePage"
    },
    template: App.Templates.Player,
    className: "player-js",
    makeSeekBar: function() {
      var i, out, position, _ref;
      position = Math.floor(this.barLength * this.model.getTime() / this.duration);
      out = "";
      for (i = 0, _ref = this.barLength; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        if (i <= position) {
          out += '=';
        } else {
          out += '-';
        }
      }
      return out;
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
