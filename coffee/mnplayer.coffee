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
        audio = new buzz.sound url
        player = new App.Views.Player model: audio 
        $(ob).append player.render()
    
App.Views.Player = Backbone.View.extend
    initialize: () ->
        @barLength = 30;
        @model.parentView = this
        @model.bind('timeupdate', @timeupdate)
#        _.bind @timeupdate, this
    timeupdate: () ->
        console.log 'timeupdate'
        
        @parentView.$el.find('.seek-bar').html @parentView.makeSeekBar()
        @parentView.$el.find('.time').html buzz.toTimer @getTime()
        
    events: 
        "click .play-button": "play"
        "click .pause-button": "pause"
        "click .seek-bar": "seek"
        "click .home-page": "homePage"
    
    template: App.Templates.Player
    className: "player-js"
    makeSeekBar: () ->
        position = Math.floor @barLength * @model.getPercent() / 100
        out = ""
        for i in [0..@barLength]
            if i <= position
                out += '='
            else
                out += '-'
        return out
    render: () ->
        @$el.html _.template @template, homePage: "https://github.com/lpenguin/mnplayer-js"
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
        @model.setPercent x/width*100
    homePage: () ->
        window.open('https://github.com/lpenguin/mnplayer-js','_newtab');



