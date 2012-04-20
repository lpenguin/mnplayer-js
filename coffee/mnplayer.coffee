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
    
    $('.mnplayer').each (i, ob) ->
        message = ""
        url = $(ob).attr 'url'
        mp3url = $(ob).attr 'mp3url'
        oggurl = $(ob).attr 'oggurl'
        message = 'sorry HTML5 is not supported by your browser' if not buzz.isSupported()
        
        if mp3url and buzz.isMP3Supported()
            url = mp3url
        if oggurl and buzz.isOGGSupported()
            url = oggurl
        if not url 
            message = 'error: no audio'
            url = ''
#            audio = {}
 #       else
        audio = new buzz.sound url, { preload:true, loop:false}
            
        duration = $(ob).attr 'duration'
        info = $(ob).attr 'info'
        
        

        player = new App.Views.Player model: audio, duration: duration, info: info, message: message
        $(ob).append player.render()
    
buzzBind = (sound, event, func, obj) ->
    f = (e) ->
        func.call obj, e, this
    sound.bind event, f
replaceAll = (string, search, replace) ->
    string.split(search).join(replace)


App.Views.Player = Backbone.View.extend
    initialize: (options) ->
        @barLength = App.Settings.barLength;
        if options.barLength
            @barLength = options.barLength
        buzzBind @model, 'timeupdate', @timeupdate, this
        buzzBind @model, 'durationchange', @durationchange, this
        #buzzBind @model, 'abort', @soundAbort, this
        buzzBind @model, 'error', @soundError, this
        if options.duration
            @manualDuration = buzz.fromTimer options.duration
        @info = options.info or ''
        @showMode = 'bar'
        @messagePosition = 0
        @showMessage options.message if options.message
        
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
        @$el.find('.time').html buzz.toTimer @model.getTime()
    drawMessage: () ->
        @$el.find('.seek-bar').html @makeMessageBar()
        @$el.find('.time').html buzz.toTimer @model.getTime()
    
    timeupdate: (e) ->
        if @showMode == 'bar'
            @drawSeekBar()
        if @showMode == 'message'
            @drawMessage()
            
        if @duration and @model.getTime() > @duration
            @pause()
            @model.setTime(0)
            
    durationchange: (e) ->
        @duration = @model.getDuration()
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
        position = Math.floor @barLength * @model.getTime() / @duration + 1
        console.log position + '/' + @barLength
        out = ""
        for i in [1..@barLength]
            if i <= position and position != 1
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
        if @showMode == 'message'
            @setBarMode()
            @drawSeekBar()
            return
        x = e.pageX - e.target.offsetLeft;
        width = $(e.target).width()
        @model.setTime x/width * @duration
    homePage: () ->
        window.open('https://github.com/lpenguin/mnplayer-js','_newtab');

$ () ->  mnplayer() if App.Settings.autoLoad

