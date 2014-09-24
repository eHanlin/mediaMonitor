
class MediaMonitor

  constructor:( @el, @scale = 100, @listenCB )->

    @addEvent_ @el, "play", @
    @addEvent_ @el, "pause", @
    @addEvent_ @el, "seeking", @
    @addEvent_ @el, "seeked", @
    @addEvent_ @el, "timeupdate", @

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
    if Math.round( @el.currentTime ) == Math.round( @duration_ ) then @onScaleChange()
    @isEnablePlaying = false
    @clearLastStatus_()

  #@event
  onSeeking:( e )->
    @isEnablePlaying = false
    @clearLastStatus_()

  #@event
  onSeeked:( e )->
    @isEnablePlaying = true
    @resetStartTime_ @el.currentTime

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

    lastStatus = @getLastStatus_()
    startScale = if lastStatus then lastStatus.endScale else parseInt( @startTime_ * @scale / @duration_ )

    end = @el.currentTime
    endScale   = parseInt( end * @scale / @duration_ )
    
    if @listenCB and ( !lastStatus or endScale != lastStatus.endScale ) then @listenCB startScale:startScale, endScale:endScale

    @setLastStatus_ startScale, endScale


  #@event
  onTimeupdate:( e )->

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

if module then module.exports = mediaMonitor
if window then window.mediaMonitor = mediaMonitor

