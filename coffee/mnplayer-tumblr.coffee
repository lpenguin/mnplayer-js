if not window.soundManager.plugins?
  window.soundManager.plugins = []

class mnplayerTumblrPlugin
  tumblr_cheat_string: '?plead=please-dont-download-this-or-our-lawyers-wont-let-us-host-audio'
  
  ready: ()->
    str = @tumblr_cheat_string
    $('.audio_player').each (i, el)->
      embed = $(this).find('embed').first()
      src = embed.attr 'src'
      re = /\?audio_file\=([^\&]+)\&/
      res = re.exec src
      audio_src = res[1]+str
      console.log audio_src
      div = $ '<div></div>'
      div.addClass 'mnplayer'
      div.attr 'url', audio_src
      $(this).after div
      #$(this).hide()
      
window.soundManager.plugins.push new mnplayerTumblrPlugin()
      #http://assets.tumblr.com/swf/audio_player_black.swf?audio_file=http://www.tumblr.com/audio_file/18434471424/tumblr_m03rfvQ6GV1r1lmxt&color=FFFFFF
    
    

