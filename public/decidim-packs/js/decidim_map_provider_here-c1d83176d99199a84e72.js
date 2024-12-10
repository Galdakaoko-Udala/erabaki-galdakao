!function(){var t,e={51053:function(t,e,r){"use strict";r(45243),r(12097);$((function(){$("[data-decidim-map]").on("configure.decidim",(function(t,e,r){L.tileLayer.here(r.tileLayer).addTo(e)}))}));var o=r(48782);L.DivIcon.SVGIcon=o.q,L.DivIcon.SVGIcon.DecidimIcon=L.DivIcon.SVGIcon.extend({options:{fillColor:"#ef604d",opacity:0},_createPathDescription:function(){return"M14 1.17a11.685 11.685 0 0 0-11.685 11.685c0 11.25 10.23 20.61 10.665 21a1.5 1.5 0 0 0 2.025 0c0.435-.435 10.665-9.81 10.665-21A11.685 11.685 0 0 0 14 1.17Zm0 17.415A5.085 5.085 0 1 1 19.085 13.5 5.085 5.085 0 0 1 14 18.585Z"},_createCircle:function(){return""},_createSVG:function(){var t=this._createPath(),e=this._createCircle(),r=this._createText(),o="".concat(this.options.className,"-svg"),n="width:".concat(this.options.iconSize.x,"px; height:").concat(this.options.iconSize.y,"px;");return'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" class="'.concat(o,'" style="').concat(n,'">').concat(t).concat(e).concat(r,"</svg>")}});var n=r(29144),i=r(61781);function a(t){return a="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},a(t)}function c(t,e){for(var r=0;r<e.length;r++){var o=e[r];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(t,(n=o.key,i=void 0,i=function(t,e){if("object"!==a(t)||null===t)return t;var r=t[Symbol.toPrimitive];if(void 0!==r){var o=r.call(t,e||"default");if("object"!==a(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(n,"string"),"symbol"===a(i)?i:String(i)),o)}var n,i}function u(t,e){return u=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(t,e){return t.__proto__=e,t},u(t,e)}function s(t){var e=function(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(t){return!1}}();return function(){var r,o=l(t);if(e){var n=l(this).constructor;r=Reflect.construct(o,arguments,n)}else r=o.apply(this,arguments);return function(t,e){if(e&&("object"===a(e)||"function"===typeof e))return e;if(void 0!==e)throw new TypeError("Derived constructors may only return object or undefined");return function(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}(t)}(this,r)}}function l(t){return l=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(t){return t.__proto__||Object.getPrototypeOf(t)},l(t)}var p=window.open,f=function(t){!function(t,e){if("function"!==typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:!0,configurable:!0}}),Object.defineProperty(t,"prototype",{writable:!1}),e&&u(t,e)}(i,t);var e,r,o,n=s(i);function i(){return function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,i),n.apply(this,arguments)}return e=i,(r=[{key:"start",value:function(){var t=this;if(this.map.removeControl(this.map.zoomControl),this.map.dragging.disable(),this.map.touchZoom.disable(),this.map.doubleClickZoom.disable(),this.map.scrollWheelZoom.disable(),this.map.boxZoom.disable(),this.map.keyboard.disable(),this.map.tap&&this.map.tap.disable(),this.config.zoom?this.map.setZoom(this.config.zoom):this.map.setZoom(15),this.config.latitude&&this.config.longitude){var e=[this.config.latitude,this.config.longitude];this.map.panTo(e),L.marker(e,{icon:this.createIcon(),keyboard:!0,title:this.config.title}).addTo(this.map)._icon.removeAttribute("tabindex")}this.config.link&&this.map._container.addEventListener("click",(function(e){e.preventDefault(),t.map._container.focus(),p(t.config.link,"_blank")}))}}])&&c(e.prototype,r),o&&c(e,o),Object.defineProperty(e,"prototype",{writable:!1}),i}(i.Z);function h(t){return h="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},h(t)}function m(t,e){for(var r=0;r<e.length;r++){var o=e[r];o.enumerable=o.enumerable||!1,o.configurable=!0,"value"in o&&(o.writable=!0),Object.defineProperty(t,(n=o.key,i=void 0,i=function(t,e){if("object"!==h(t)||null===t)return t;var r=t[Symbol.toPrimitive];if(void 0!==r){var o=r.call(t,e||"default");if("object"!==h(o))return o;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}(n,"string"),"symbol"===h(i)?i:String(i)),o)}var n,i}function d(t,e){return d=Object.setPrototypeOf?Object.setPrototypeOf.bind():function(t,e){return t.__proto__=e,t},d(t,e)}function y(t){var e=function(){if("undefined"===typeof Reflect||!Reflect.construct)return!1;if(Reflect.construct.sham)return!1;if("function"===typeof Proxy)return!0;try{return Boolean.prototype.valueOf.call(Reflect.construct(Boolean,[],(function(){}))),!0}catch(t){return!1}}();return function(){var r,o=b(t);if(e){var n=b(this).constructor;r=Reflect.construct(o,arguments,n)}else r=o.apply(this,arguments);return function(t,e){if(e&&("object"===h(e)||"function"===typeof e))return e;if(void 0!==e)throw new TypeError("Derived constructors may only return object or undefined");return function(t){if(void 0===t)throw new ReferenceError("this hasn't been initialised - super() hasn't been called");return t}(t)}(this,r)}}function b(t){return b=Object.setPrototypeOf?Object.getPrototypeOf.bind():function(t){return t.__proto__||Object.getPrototypeOf(t)},b(t)}var v=function(t){!function(t,e){if("function"!==typeof e&&null!==e)throw new TypeError("Super expression must either be null or a function");t.prototype=Object.create(e&&e.prototype,{constructor:{value:t,writable:!0,configurable:!0}}),Object.defineProperty(t,"prototype",{writable:!1}),e&&d(t,e)}(i,t);var e,r,o,n=y(i);function i(){return function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,i),n.apply(this,arguments)}return e=i,(r=[{key:"start",value:function(){this.config.marker?this.addMarker(this.config.marker):this.map.fitWorld()}},{key:"addMarker",value:function(t){var e=this;if(null!==t.latitude&&null!==t.longitude){var r={lat:t.latitude,lng:t.longitude};this.triggerEvent("coordinates",[r]),this.marker=L.marker(r,{icon:this.createIcon(),keyboard:!0,title:t.title,draggable:!0}),this.marker.on("drag",(function(t){e.triggerEvent("coordinates",[t.target.getLatLng()])})),this.marker.addTo(this.map);var o=parseInt(this.config.zoom,10)||14;this.map.setView(r,o)}}},{key:"getMarker",value:function(){return this.marker}},{key:"removeMarker",value:function(){this.marker&&(this.marker.remove(),this.marker=null)}}])&&m(e.prototype,r),o&&m(e,o),Object.defineProperty(e,"prototype",{writable:!1}),i}(i.Z);window.Decidim.createMapController=function(t,e){return"static"===e.type?new f(t,e):"drag-marker"===e.type?new v(t,e):new n.Z(t,e)},$((function(){var t=$("[data-decidim-map]");if(t.length<1&&$("#map").length>0)throw new Error("DEPRECATION: Please update your maps customizations or include 'decidim/map/legacy.js' for legacy support!");t.each((function(t,e){var r=$(e),o=r.attr("id");o||(o="map-".concat(Math.random().toString(36).substr(2,9)),r.attr("id",o));var n=r.data("decidim-map"),i=window.Decidim.createMapController(o,n),a=i.load();r.data("map",a),r.data("map-controller",i),r.trigger("configure.decidim",[a,n]),i.start(),r.trigger("ready.decidim",[a,n])}))}))},12097:function(){L.TileLayer.HERE=L.TileLayer.extend({options:{subdomains:"1234",minZoom:2,maxZoom:18,scheme:"normal.day",resource:"maptile",mapId:"newest",format:"png8",appId:"",appCode:"",useCIT:!1,useHTTPS:!0,language:"",language2:""},initialize:function(t){var e=(t=L.setOptions(this,t)).scheme.split(".")[0];t.tileResolution=256;var r=["apiKey="+encodeURIComponent(t.apiKey)];t.apiKey||(r=["app_id="+encodeURIComponent(t.appId),"app_code="+encodeURIComponent(t.appCode)]),t.language&&r.push("lg="+encodeURIComponent(t.language)),t.language2&&r.push("lg2="+encodeURIComponent(t.language2));var o="/maptile/2.1/{resource}/{mapId}/{scheme}/{z}/{x}/{y}/{tileResolution}/{format}"+("?"+r.join("&")),n="/maptile/2.1/copyright/{mapId}?apiKey={apiKey}",i="maps.ls.hereapi.com";t.apiKey||(i="maps"+(t.useCIT?".cit":"")+".api.here.com",n="/maptile/2.1/copyright/{mapId}?app_id={appId}&app_code={appCode}");var a="base."+i;"satellite"!=e&&"terrain"!=e&&"hybrid"!=e||(a="aerial."+i),-1!==t.scheme.indexOf(".traffic.")&&(a="traffic"+i);var c="http"+(t.useHTTPS?"s":""),u=c+"://{s}."+a+o;this._attributionUrl=L.Util.template(c+"://1."+a+n,this.options),L.TileLayer.prototype.initialize.call(this,u,t),this._attributionText=""},onAdd:function(t){L.TileLayer.prototype.onAdd.call(this,t),this._attributionBBoxes||this._fetchAttributionBBoxes()},onRemove:function(t){this._map.attributionControl.removeAttribution(this._attributionText),this._attributionText="",this._map.off("moveend zoomend resetview",this._findCopyrightBBox,this),L.TileLayer.prototype.onRemove.call(this,t)},_fetchAttributionBBoxes:function(){var t=new XMLHttpRequest;t.onreadystatechange=L.bind((function(){4==t.readyState&&200==t.status&&this._parseAttributionBBoxes(JSON.parse(t.responseText))}),this),t.open("GET",this._attributionUrl,!0),t.send()},_parseAttributionBBoxes:function(t){if(this._map){for(var e=t[this.options.scheme.split(".")[0]]||t.normal,r=0;r<e.length;r++)if(e[r].boxes)for(var o=0;o<e[r].boxes.length;o++){var n=e[r].boxes[o];e[r].boxes[o]=L.latLngBounds([[n[0],n[1]],[n[2],n[3]]])}this._map.on("moveend zoomend resetview",this._findCopyrightBBox,this),this._attributionProviders=e,this._findCopyrightBBox()}},_findCopyrightBBox:function(){if(this._map){for(var t=this._attributionProviders,e=[],r=this._map.getZoom(),o=this._map.getBounds(),n=0;n<t.length;n++)if(t[n].minLevel<=r&&t[n].maxLevel>=r)if(t[n].boxes)for(var i=0;i<t[n].boxes.length;i++){var a=t[n].boxes[i];if(o.intersects(a)){e.push(t[n]);break}}else e.push(t[n]);var c=['<a href="https://legal.here.com/en-gb/terms" target="_blank" rel="noopener noreferrer">HERE maps</a>'];for(n=0;n<e.length;n++){var u=e[n];c.push('<abbr title="'+u.alt+'">'+u.label+"</abbr>")}var s="\xa9 "+c.join(", ")+". ";s!==this._attributionText&&(this._map.attributionControl.removeAttribution(this._attributionText),this._map.attributionControl.addAttribution(this._attributionText=s))}}}),L.tileLayer.here=function(t){return new L.TileLayer.HERE(t)}}},r={};function o(t){var n=r[t];if(void 0!==n)return n.exports;var i=r[t]={exports:{}};return e[t].call(i.exports,i,i.exports,o),i.exports}o.m=e,t=[],o.O=function(e,r,n,i){if(!r){var a=1/0;for(l=0;l<t.length;l++){r=t[l][0],n=t[l][1],i=t[l][2];for(var c=!0,u=0;u<r.length;u++)(!1&i||a>=i)&&Object.keys(o.O).every((function(t){return o.O[t](r[u])}))?r.splice(u--,1):(c=!1,i<a&&(a=i));if(c){t.splice(l--,1);var s=n();void 0!==s&&(e=s)}}return e}i=i||0;for(var l=t.length;l>0&&t[l-1][2]>i;l--)t[l]=t[l-1];t[l]=[r,n,i]},o.n=function(t){var e=t&&t.__esModule?function(){return t.default}:function(){return t};return o.d(e,{a:e}),e},o.d=function(t,e){for(var r in e)o.o(e,r)&&!o.o(t,r)&&Object.defineProperty(t,r,{enumerable:!0,get:e[r]})},o.o=function(t,e){return Object.prototype.hasOwnProperty.call(t,e)},function(){var t={6999:0};o.O.j=function(e){return 0===t[e]};var e=function(e,r){var n,i,a=r[0],c=r[1],u=r[2],s=0;if(a.some((function(e){return 0!==t[e]}))){for(n in c)o.o(c,n)&&(o.m[n]=c[n]);if(u)var l=u(o)}for(e&&e(r);s<a.length;s++)i=a[s],o.o(t,i)&&t[i]&&t[i][0](),t[i]=0;return o.O(l)},r=self.webpackChunkapp=self.webpackChunkapp||[];r.forEach(e.bind(null,0)),r.push=e.bind(null,r.push.bind(r))}();var n=o.O(void 0,[5732,9335,9144],(function(){return o(51053)}));n=o.O(n)}();
//# sourceMappingURL=decidim_map_provider_here-c1d83176d99199a84e72.js.map