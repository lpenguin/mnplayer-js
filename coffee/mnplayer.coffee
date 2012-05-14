# mnplayer-js
# Minimalistic HTML5/Flash audio player in pseudographic style.

# Dependencies:
# Backbone
# Underscore
# SoundManager2
# jQuery

# TODO:
# 1) �������� �������� ��������
# 2) ��������� ������ �� ������, ������������� ����������, ������ � Backbone.Model
# 3) �������� ��������� ������

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
    
App.Templates.Player = 
    "<div class=\"play-button symbol clickable\">|>&nbsp;</div>"+
    "<div class=\"pause-button hidden symbol clickable\">||&nbsp;</div>"+
    "<div class=\"symbol\">[</div>"+
    "<div class=\"seek-bar symbol clickable\"></div>"+
    "<div class=\"symbol\">&nbsp;</div>"+
    "<div class=\"time symbol\"></div>"+
    "<div class=\"symbol\">]</div>"+
    "&nbsp;"+
    "<div class=\"symbol info clickable\">[i]</div>"+
    "<div class=\"symbol home-page clickable\">[?]</div><br/>"



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

App.Models.Sound = Backbone.Model.extend
    initialize: (options) ->
        
        url = options.url
        if not App.soundCounter?
            App.soundCounter = 0
        else
            App.soundCounter++
        @audio = soundManager.createSound id:'sound'+App.soundCounter, url: url, autoLoad: true
        
    #    @audio._whileloading @_event_durationchange, this
    #    @audio._whileplaying @_event_whileplaying, this
    #    @audio._ondataerror @_event_dataerror, this
    #    @audio._onid3 @_event_onid3, this
        @events = onid3: 
                    func: null
                    context: null
                 ondurationchange: 
                    func: null
                    context: null
                 onerror:
                    func: null
                    context: null
                 onplaying:
                    func: null
                    context: null
                 
                    
        @duration = @audio.duration
        if options.duration
            @manualDuration = fromTimer options.duration

        @info = options.info or @getinfo()
        
    # event bindings
    onplaying: (func, context) ->
        @events.onplaying.func = func
        @events.onplaying.context = context
    ondurationchange: (func, context)->
        @events.ondurationchange.func = func
        @events.ondurationchange.context = context
    onerror: (func, context)->
        @events.onerror.func = func
        @events.onerror.context = context
    onid3: (func, context)->
        @events.onid3.func = func
        @events.onid3.context = context
        
    # playback control
    play: () ->
        @model.play()
    pause: () ->
        @model.pause()
    stop: () ->
        @model.stop()
    seek: (position) ->
        @model.setPosition position
    
    # properties
    getInfo: () ->
        return @_makeInfo()
    getDuration: ()->
        return @duration if @duration
        return @audio.duration
    getError: ()->
        return message: "", status: null
    getErrorMessage: ()->
        return @getError().message
    getErrorStatus: ()->
        return @getError().status
    
    # private
    _makeInfo:() ->
        if @info
            return @info
        if @audio.id3.artist && @audio.id3.title
            return @audio.id3.artist+" - "+@audio.id3.title
        return ""
        
    # events
    _event_whileplaying: ()->
        if @events.onplaying.func?
           @events.onplaying.func.call(@events.onplaying.context)    
    _event_onid3: ()->
        if @events.onid3.func?
           @events.onid3.func.call(@events.onid3.context, @getInfo())
    _event_durationchange: ()->
        if @events.ondurationchange.func?
           @events.ondurationchange.func.call(@events.ondurationchange.context, @getDuration())     
    _event_dataerror: ()->
        if @events.onerror.func?
           @events.onerror.func.call(@events.onerror.context)     

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
        @audio._onid3 @onid3, this
        
        if options.duration
            @manualDuration = fromTimer options.duration
        @info = options.info or @getinfo()
        @showMode = 'bar'
        @messagePosition = 0
        @showMessage options.message if options.message
        
    getinfo: ()->
      return @audio.id3.artist+" - "+@audio.id3.title
    onid3: ()->
        if not @info
          @info = @getinfo()
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
        @model.seek x/width * @model.getDuration()
        @timeupdate()
    homePage: () ->
        window.open('https://github.com/lpenguin/mnplayer-js','_newtab');

#Root.soundManager.flashVersion = 9 #optional: shiny features (default = 8)
Root.soundManager.url = 'http://lpenguin.narod2.ru/swf/'
soundManager.preferFlash = true; 
Root.soundManager.onready () ->  mnplayer() if App.Settings.autoLoad
#$ () ->  mnplayer() if App.Settings.autoLoad

