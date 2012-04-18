(function() {
  var Root;

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

  App.Views.Player = Backbone.View.extend({
    initialize: function(options) {
      this.barLength = App.Settings.barLength;
      if (options.barLength) this.barLength = options.barLength;
      this.model.parentView = this;
      this.model.bind('timeupdate', this.timeupdate);
      this.model.bind('durationchange', this.durationchange);
      if (options.duration) {
        return this.manualDuration = buzz.fromTimer(options.duration);
      }
    },
    timeupdate: function() {
      this.parentView.$el.find('.seek-bar').html(this.parentView.makeSeekBar());
      this.parentView.$el.find('.time').html(buzz.toTimer(this.getTime()));
      if (this.parentView.duration && this.getTime() > this.parentView.duration) {
        this.parentView.pause();
        return this.setTime(0);
      }
    },
    durationchange: function() {
      this.parentView.duration = this.getDuration();
      if (this.parentView.manualDuration) {
        return this.parentView.duration = this.parentView.manualDuration;
      }
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
