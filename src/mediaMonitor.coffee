
class MediaMonitor

  constructor:( @el, @scale = 100, @listenCB )->

    @addEvent_ @el, "play", @
    @addEvent_ @el, "pause", @
    @addEvent_ @el, "seeking", @
    @addEvent_ @el, "seeked", @
    @addEvent_ @el, "timeupdate", @
    @addEvent_ @el, "ended", @

    @isEnabledSeeking_ = "onseeking" of @el or "onseeked" of @el or
                         (/(ipad|iphone)/i.test(navigator.userAgent) && /Version\/8/i.test(navigator.userAgent))

    if @el.duration
      @setDuration_ @el.duration

    @addEvent_ @el, "loadedmetadata", @

  #@private
  #Add a event listener to element
  addEvent_:( el, type, fn, capture )-> el.addEventListener type, fn, !!capture

  #@private
  #Remove a event listener by element
  removeEvent_:( el, type, fn, capture )-> el.removeEventListener type, fn, !!capture

  #@private
  #Set a max value of video or audio
  setDuration_:( duration )-> @duration_ = duration

  #@event
  #Assign dom element event to other method
  handleEvent:( e )->

    type = e.type
    firstChar = type.substr 0, 1
    typeChars = type.substr 1, (type.length - 1)
    @[ "on#{firstChar.toUpperCase()}#{typeChars}"] e

  #@private
  resetStartTime_:( sec )->
   
    @startTime_ = sec

  destroy:->

    @removeEvent_ @el, "play", @
    @removeEvent_ @el, "pause", @
    @removeEvent_ @el, "seeking", @
    @removeEvent_ @el, "seeked", @
    @removeEvent_ @el, "timeupdate", @

  #@event
  onPlay:( e )->
    @isEnablePlaying = true
    @resetStartTime_ @el.currentTime

  #@event
  onPause:( e )->
    @isEnablePlaying = false
    @clearLastStatus_()

  #@event
  onEnded:( e )-> if Math.round( @el.currentTime ) == Math.round( @duration_ ) then @onScaleChange()

  #@event
  onSeeking:( e )->
    @isEnablePlaying = false
    @clearLastStatus_()
    @seekingTime_ = @el.currentTime

  #@event
  onSeeked:( e )->
    @isEnablePlaying = true
    #fixed a bug that current time is zero when progress is seeked to end
    #test device [OS]( Android 4.4.2; B1-730HD Build/KOT49H ) [Browser]( Chrome 35.0.1916.141 ) [device builder]( acer )
    currentTime = @el.currentTime
    seekingTime = @seekingTime_
    resetStartTime = if seekingTime != undefined && currentTime != seekingTime then seekingTime else currentTime

    @resetStartTime_ resetStartTime

  #@event
  onLoadedmetadata:( e )->
    @setDuration_ @el.duration
    @clearLastStatus_()

  startTime_:0

  #@private
  setLastStatus_:( startScale, endScale )->
    @lastStatus_ =
      startScale:startScale
      endScale:endScale

  #@private
  getLastStatus_:-> @lastStatus_

  #@private
  clearLastStatus_:-> @lastStatus_ = null

  onScaleChange:->

    if @isEnabledSeeking_
      lastStatus = @getLastStatus_()
      startScale = if lastStatus then lastStatus.endScale else parseInt( @startTime_ * @scale / @duration_ )

      end = @el.currentTime
      #endScale   = parseInt( end * @scale / @duration_ )
      endScale   = Math.round( end * @scale / @duration_ )
      
      if @listenCB and ( !lastStatus or endScale != lastStatus.endScale ) then @listenCB startScale:startScale, endScale:endScale

      @setLastStatus_ startScale, endScale
    #listen not support seeked
    else
      scale = parseInt( @el.currentTime * @scale / @duration_ )
      if scale != @lastScale_ then @listenCB startScale:scale, endScale:scale
      @lastScale_ = scale


  #@event
  onTimeupdate:( e )->
    #fixed a bug when loadedmetadata is not support
    @setDuration_ @el.duration
    if @isEnablePlaying and !@el.paused then @onScaleChange()

#data builder
dataBuilder =

  url:( data )->
    queryStrs = []
    queryStrs.push "#{name}=#{data[name]}" for name of data
    queryStrs.join "&"

  json:( data )-> JSON.stringify data
 

#create ajax by method
buildAjax = ( method )->

    ( url, data, dataType = "url"  )->
      xhr = new XMLHttpRequest()

      isURLRequest = method.toLowerCase() == "get"

      dataStr = dataBuilder[dataType]( data )

      if isURLRequest
        defaultParamName = if dataType == "json" then "data=" else ""
        ajaxUrl = "#{ajaxUrl}?#{defaultParamName}#{dataStr}"
      else
        ajaxUrl = url

      xhr.open method, url, true
      if !isURLRequest then xhr.send dataStr else xhr.send()

#ajax
ajax =
  get:buildAjax "get"
  post:buildAjax "post"
  put:buildAjax "put"

utils =
  isArray:( val )-> Object.prototype.toString.call( val ) == "[object Array]"

mediaMonitor = (()->

  detect:( el, opts = {} )->
    if opts and typeof opts.listenCB == "object"
      listenCBOpts = opts.listenCB
      listenCB = ( data )->
        ajax[listenCBOpts.name]( listenCBOpts.url, data, listenCBOpts.dataType )
        otherCBs = listenCBOpts.otherCBs
        if otherCBs and utils.isArray otherCBs
          cb data for cb in otherCBs
    else
      listenCB = opts.listenCB
      
    new MediaMonitor el, opts.scale, listenCB

)()

if typeof module != "undefined" then module.exports = mediaMonitor
if typeof window != "undefined" then window.mediaMonitor = mediaMonitor

