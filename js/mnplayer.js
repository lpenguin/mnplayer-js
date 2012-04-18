(function() {
  var Root;

  Root = window;

  Root.App = {
    Views: {},
    Models: {},
    Routers: {},
    Templates: {}
  };

  App.Templates.Player = "<div class=\"play-button symbol\">|>&nbsp;</div>\n<div class=\"pause-button hidden symbol\">||&nbsp;</div>\n<div class=\"symbol\">[</div>\n<div class=\"seek-bar symbol\"></div>\n<div class=\"symbol\">&nbsp;</div>\n<div class=\"time symbol\"></div>\n<div class=\"symbol\">]</div>";

  Root.mnplayer = function() {
    return $('.mnplayer').each(function(i, ob) {
      var audio, player, url;
      url = $(ob).attr('url');
      audio = new buzz.sound(url);
      player = new App.Views.Player({
        model: audio
      });
      return $(ob).append(player.render());
    });
  };

  App.Views.Player = Backbone.View.extend({
    initialize: function() {
      this.barLength = 30;
      this.model.parentView = this;
      return this.model.bind('timeupdate', this.timeupdate);
    },
    timeupdate: function() {
      console.log('timeupdate');
      this.parentView.$el.find('.seek-bar').html(this.parentView.makeSeekBar());
      return this.parentView.$el.find('.time').html(buzz.toTimer(this.getTime()));
    },
    events: {
      "click .play-button": "play",
      "click .pause-button": "pause",
      "click .seek-bar": "seek"
    },
    template: App.Templates.Player,
    className: "player-js",
    makeSeekBar: function() {
      var i, out, position, _ref;
      position = Math.floor(this.barLength * this.model.getPercent() / 100);
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
      return this.model.setPercent(x / width * 100);
    }
  });

}).call(this);
