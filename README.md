mediaMonitor
===================================

![demo image](/images/mediaMonitor.gif)

This is a progress monitor for video or audio.

## Install

```bash
bower install media-monitor
```

## Install node modules

```bash
npm install
```

## Support

* IE10
* chrome
* firefox

## Usage

```js
var opts = {
  //default 100
  scale:20,
  listenCB:function( data ){
    //do something...
  }
};

mediaMonitor.detect( audio, opts );
```

## API

#### mediaMonitor.detect( element, opts ) : MediaRecorder
> Create and listen a recorder

#### MediaMonitor.destroy() : void
> Remove all events

### default listen callback

* post (ajax)
* get (ajax)

> example:
```js
var opts = {
  listenCB:{
    name:"post",
    url:"/testse",
    //other callbacks (optional)
    otherCBs:[function(){console.log(arguments);}],
    //default url (optional)
    dataType:"json"
  },
  scale:scale
};
```


## DEMO

```bash
gulp server
```

## Build

```bash
gulp
```

