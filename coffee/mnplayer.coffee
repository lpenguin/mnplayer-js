Root = window
Root.App = 
    Views: {}
    Models: {}
    Routers: {}
    Templates: {}

App.Templates.Player = """
    <div class="play-button symbol">|>&nbsp;</div>
    <div class="pause-button hidden symbol">||&nbsp;</div>
    <div class="symbol">[</div>
    <div class="seek-bar symbol"></div>
    <div class="symbol">&nbsp;</div>
    <div class="time symbol"></div>
    <div class="symbol">]</div>
    &nbsp;
    <div class="symbol home-page">[?]</div><br/>
"""

Root.mnplayer = ( ) ->
    $('.mnplayer').each (i, ob) ->
        url = $(ob).attr 'url'
        duration = $(ob).attr 'duration'
        audio = new buzz.sound url, { preload:true, loop:false}
        #console.log audio.getDuration()
        player = new App.Views.Player model: audio, duration: duration 
        $(ob).append player.render()
    
App.Views.Player = Backbone.View.extend
    initialize: (options) ->
        @barLength = 30;
        @model.parentView = this
        @model.bind('timeupdate', @timeupdate)
        @model.bind 'durationchange', @durationchange
        if options.duration
            @manualDuration = buzz.fromTimer options.duration

#        _.bind @timeupdate, this
    timeupdate: () ->
        @parentView.$el.find('.seek-bar').html @parentView.makeSeekBar()
        @parentView.$el.find('.time').html buzz.toTimer @getTime()
        if @parentView.duration and @getTime() > @parentView.duration
            @parentView.pause()
            @setTime(0)
    durationchange: () ->
        @parentView.duration = @getDuration()
        if @parentView.manualDuration
            @parentView.duration = @parentView.manualDuration
    events: 
        "click .play-button": "play"
        "click .pause-button": "pause"
        "click .seek-bar": "seek"
        "click .home-page": "homePage"
    
    template: App.Templates.Player
    className: "player-js"
    makeSeekBar: () ->
        position = Math.floor @barLength * @model.getTime() / @duration
        out = ""
        for i in [0..@barLength]
            if i <= position
                out += '='
            else
                out += '-'
        return out
    render: () ->
        @$el.html @template
        @$el.find('.seek-bar').html @makeSeekBar()
        @$el.find('.time').html buzz.toTimer @model.getTime()
        return @$el
    play: () ->
        @model.play()
        @togglePlayButton()
    pause: () ->
        @model.pause()
        @togglePlayButton()
    togglePlayButton: () ->
        @$el.find('.play-button').toggleClass 'hidden'
        @$el.find('.pause-button').toggleClass 'hidden'
    seek: (e) ->
        x = e.pageX - e.target.offsetLeft;
        width = $(e.target).width()
        @model.setTime x/width * @duration
    homePage: () ->
        window.open('https://github.com/lpenguin/mnplayer-js','_newtab');



