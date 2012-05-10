Root = window
Root.App = 
    Views: {}
    Models: {}
    Routers: {}
    Templates: {}

App.Settings = 
    barLength: 28
    autoLoad: true
    messageStep: 500
    messageSpace: 4
    updateTime: 500
    
App.Templates.Player = """
    <div class="play-button symbol clickable">|>&nbsp;</div>
    <div class="pause-button hidden symbol clickable">||&nbsp;</div>
    <div class="symbol">[</div>
    <div class="seek-bar symbol clickable"></div>
    <div class="symbol">&nbsp;</div>
    <div class="time symbol"></div>
    <div class="symbol">]</div>
    &nbsp;
    <div class="symbol info clickable">[i]</div>
    <div class="symbol home-page clickable">[?]</div><br/>
"""

Root.mnplayer = ( ) ->
    if Root.soundManager.plugins and Root.soundManager.plugins instanceof Array
        for plugin in Root.soundManager.plugins
            if plugin.ready
              plugin.ready()

    $('.mnplayer').each (i, ob) ->
        message = ""
        url = $(ob).attr 'url'
        audio = soundManager.createSound id:'sound'+i, url: url, autoLoad: true
        duration = $(ob).attr 'duration'
        info = $(ob).attr 'info'
        
        

        player = new App.Views.Player model: audio, duration: duration, info: info, message: message
        $(ob).append player.render()
    
eventBind = (sound, event, func, obj) ->
    f = (e) ->
        func.call obj, e, this
    sound.bind event, f
replaceAll = (string, search, replace) ->
    string.split(search).join(replace)

fromTimer = (time) ->
    vals = time.split(":")
    minutes = vals[0]
    seconds = vals[1]
    return (parseInt minutes * 60 + parseInt seconds) * 1000
    
toTimer = (ms) ->
    ms = Math.floor ms / 1000
    seconds = ms % 60
    minutes = Math.floor ms / 60
    seconds = '0' + seconds if seconds < 10
    minutes = '0' + minutes if minutes < 10
    return minutes+":"+seconds

startTimer = (func, delay, scope) ->
    id = setInterval( () -> 
        func.call scope
    , delay)
    return id

stopTimer = (id) ->
    clearInterval id
    
App.Views.Player = Backbone.View.extend
    initialize: (options) ->
        @barLength = App.Settings.barLength;
        if options.barLength
            @barLength = options.barLength
        #eventBind @model, 'timeupdate', @timeupdate, this
        #eventBind @model, 'durationchange', @durationchange, this
        ##buzzBind @model, 'abort', @soundAbort, this
        #eventBind @model, 'error', @soundError, this
        
        @audio = @model
        @duration = @audio.duration
        #soundManager.whileplaying @timeupdate, this
        @audio._whileloading @durationchange, this
        @audio.onid3 onid3, this
        
        if options.duration
            @manualDuration = fromTimer options.duration
        @info = options.info or ''
        @showMode = 'bar'
        @messagePosition = 0
        @showMessage options.message if options.message
        
    onid3: ()->
        if not @info?
          @info = @audio.id3.artist+" - "+@audio.id3.title
    setBarMode: () ->
        @showMode = 'bar'
        clearInterval @messageInterval if @messageInterval
    setMessageMode: () ->
        @showMode = 'message'
        @messagePosition = 0
        that = this
        @messageInterval = setInterval( (() -> that.updateMessage()), App.Settings.messageStep)
    updateMessage: () ->
        @drawMessage()
        @messagePosition++
        @messagePosition = 0 if @messagePosition >= @message.length + App.Settings.messageSpace
        
    drawSeekBar: () ->
        @$el.find('.seek-bar').html @makeSeekBar()
        @$el.find('.time').html toTimer @model.position
    drawMessage: () ->
        @$el.find('.seek-bar').html @makeMessageBar()
        @$el.find('.time').html toTimer @model.position
    
    timeupdate: (e) ->
        if @showMode == 'bar'
            @drawSeekBar()
        if @showMode == 'message'
            @drawMessage()
            
        if @duration and @model.duration > @duration
            @pause()
            @model.setPosition(0)
    
    getDuration: ()->
        return @manualDuration if @manualDuration
        return @audio.duration
    durationchange: (e) ->
        @duration = @model.duration
        if @manualDuration
            @duration = @manualDuration
    
    showMessage: (message) ->
        @message = message
        @setMessageMode() if @showMode != 'message'
        @drawMessage()
    
    soundAbort: (e) ->
        @showMessage 'aborted'
        
    soundError: (e) ->
        msg = 'error'
        if e.target instanceof HTMLAudioElement
            switch @model.getErrorCode()
                when 1
                    msg += ': aborted by user'
                when 2 
                    msg += ': network error'
                when 3 
                    msg += ': decode error'
                when 4 
                    msg += ': audio is not supported by your browser'
        else if e.target instanceof HTMLSourceElement
            #TODO::HACK
            msg += ': audio is not supported by your browser'
                    
        @showMessage msg
    events: 
        "click .play-button": "play"
        "click .pause-button": "pause"
        "click .seek-bar": "seek"
        "click .home-page": "homePage"
        "click .info": "showInfo"
    
    template: App.Templates.Player
    className: "player-js"
    makeSeekBar: () ->
        position = Math.floor @barLength * @model.position / @getDuration() + 1
        console.log position + '/' + @barLength
        out = ""
        for i in [1..@barLength]
            if i <= position
                out += '='
            else
                out += '-'
        return out
        
    makeMessageBar: () ->
        space = App.Settings.messageSpace
        m = minit = (@message or '') + Array(space+1).join(' ')

        if m.length > @barLength
            m = m.substring @messagePosition, @barLength + @messagePosition

        rest = @barLength - m.length 
        
        if minit.length > @barLength
            left = minit.substring(0, rest)
        else
            left = Array(rest+1).join(' ')

        return replaceAll m + left, ' ', '&nbsp;'
    showInfo: () ->
        if @showMode == 'message'
            @setBarMode()
            @drawSeekBar()
            return
        @showMessage @info
    render: () ->
        @$el.html @template
        @$el.find('.seek-bar').html @makeSeekBar()
        @$el.find('.time').html toTimer @model.position
        return @$el
    play: () ->
        @timeupdateTimer = startTimer @timeupdate, App.Settings.updateTime, this
        @model.play()
        @togglePlayButton()
    pause: () ->
        stopTimer @timeupdateTimer
        @model.pause()
        @togglePlayButton()
    togglePlayButton: () ->
        @$el.find('.play-button').toggleClass 'hidden'
        @$el.find('.pause-button').toggleClass 'hidden'
    seek: (e) ->
        if @showMode == 'message'
            @setBarMode()
            @drawSeekBar()
            return
        x = e.pageX - e.target.offsetLeft ;
        width = $(e.target).width()
        @model.setPosition x/width * @getDuration()
        @timeupdate()
    homePage: () ->
        window.open('https://github.com/lpenguin/mnplayer-js','_newtab');

#Root.soundManager.flashVersion = 9 #optional: shiny features (default = 8)
Root.soundManager.url = 'http://lpenguin.narod2.ru/swf/'
soundManager.preferFlash = true; 
Root.soundManager.onready () ->  mnplayer() if App.Settings.autoLoad
#$ () ->  mnplayer() if App.Settings.autoLoad

